class Reservation < ApplicationRecord
  # Допустимые переходы статусов; declined/cancelled/completed — терминальные
  TRANSITIONS = {
    "pending"   => %w[confirmed declined cancelled].freeze,
    "confirmed" => %w[cancelled completed].freeze
  }.freeze

  # Детское мероприятие: увеличенный буфер уборки
  CHILDREN_CLEANING_MINUTES = 30

  belongs_to :zone
  # Клиенты бронируют без аккаунта — пользователь только у броней персонала
  belongs_to :user, optional: true
  has_many :payments, dependent: :destroy

  enum :status, { pending: 0, confirmed: 1, declined: 2, cancelled: 3, completed: 4 }, default: :pending

  # Поля гостевой заявки: дата обязательна, время — по желанию (согласуем по телефону).
  # Слот (starts_at/ends_at) собирается в контроллере из этих полей.
  # Длительность — booking_duration: имя duration_minutes занято вычисляемым методом.
  attr_accessor :booking_date, :start_time, :booking_duration

  # Заявка без слота не занимает расписание: время согласуется по телефону
  scope :blocking, -> { where(status: [ statuses[:pending], statuses[:confirmed] ]).where.not(starts_at: nil) }
  scope :slotless, -> { pending.where(starts_at: nil) }
  scope :upcoming, -> { blocking.where(ends_at: Time.current..).order(:starts_at) }
  scope :active_now, -> { blocking.where(starts_at: ..Time.current).where(ends_at: Time.current..).order(:ends_at) }
  scope :between, ->(range) { where(starts_at: range) }
  scope :paid, -> { where(status: [ statuses[:confirmed], statuses[:completed] ]) }

  validates :guests_count, numericality: { only_integer: true, greater_than: 0 }
  # Гостевая бронь: идентифицируем клиента по имени и телефону
  validates :guest_name, presence: true, if: -> { user.blank? }
  validates :guest_phone, presence: true, if: -> { user.blank? }
  validates :guest_phone, format: { with: /\A\+?[\d\s()-]{9,25}\z/ }, allow_blank: true
  # Слот — дата+время или ничего: оба конца или оба NULL
  validate :slot_presence
  # Заявка без слота всё равно знает желаемую дату
  validates :requested_date, presence: true, if: -> { starts_at.blank? && ends_at.blank? }
  validate :ends_after_start
  validate :starts_in_future, on: :create
  validate :duration_within_limits
  validate :guests_within_capacity
  validate :zone_is_active, on: :create
  validate :review_note_present_when_declining
  validate :no_overlapping_reservation
  validate :no_adjacent_karaoke_conflict, on: :create

  before_validation :compute_price, if: -> { new_record? }
  before_validation :snapshot_cleaning_minutes
  # Автоподтверждение имеет смысл только для заявки со слотом
  after_create :auto_approve, if: -> { zone && !zone.requires_approval && starts_at.present? }

  def duration_minutes
    return 0 unless starts_at && ends_at

    ((ends_at - starts_at) / 60).to_i
  end

  # Заявка с согласованным временем
  def slot? = starts_at.present? && ends_at.present?

  # Заявка ждёт согласования времени по телефону
  def slotless? = !slot?

  # Окно, на которое комната фактически занята (бронь + уборка)
  def blocked_until = ends_at + cleaning_minutes.minutes

  def running? = starts_at <= Time.current && Time.current < ends_at

  def paid?
    if payments.loaded?
      payments.any?(&:successful?)
    else
      payments.successful.exists?
    end
  end

  def blocking? = slot? && (pending? || confirmed?)
  def payable? = !paid? && blocking?

  # Подтвердить можно только заявку со согласованным временем
  def confirmable?  = pending? && slot?
  def declinable?   = pending?
  def cancellable?  = pending? || confirmed?
  def completable?  = confirmed? && ends_at < Time.current
  def extendable?   = slot? && (pending? || confirmed?)

  def status_label(value = status)
    I18n.t(value, scope: "reservation_statuses", default: value.to_s.humanize)
  end

  # Представление клиента в админке: имя аккаунта или имя гостя
  def client_name = user&.name || guest_name

  # Контакт клиента: телефон пользователя, иначе email; у гостя — телефон
  def client_contact
    user ? user.phone.presence || user.email_address : guest_phone
  end

  def confirm!
    assert_transition!(:confirmed)
    update!(status: :confirmed)
  end

  def decline!(note:)
    assert_transition!(:declined)
    update!(status: :declined, review_note: note)
  end

  def cancel!
    assert_transition!(:cancelled)
    update!(status: :cancelled)
  end

  def complete!
    assert_transition!(:completed)
    update!(status: :completed)
  end

  # Назначение времени заявке, пришедшей без слота: ставим интервал,
  # пересчитываем цену по действующим тарифам и снапшотим уборку.
  def assign_slot!(starts_at:, duration_minutes:)
    self.starts_at = starts_at
    self.ends_at = starts_at + duration_minutes.minutes
    snapshot_cleaning_minutes
    self.total_price_cents = Reservations::PriceCalculator.new(zone:).total_cents(self.starts_at, self.ends_at)
    save!
  rescue ActiveRecord::RecordInvalid
    raise
  end

  # Продление на месте: шаг minutes минут, доплата за добавленный интервал
  # по действующим тарифам. Цена исходного интервала не пересчитывается.
  def extend!(minutes)
    raise ActiveRecord::RecordInvalid.new(self) unless extendable?

    new_ends_at = ends_at + minutes.minutes
    extra_cents = Reservations::PriceCalculator.new(zone:).total_cents(ends_at, new_ends_at)
    self.ends_at = new_ends_at
    self.total_price_cents += extra_cents
    save!
  rescue ActiveRecord::RecordInvalid
    raise
  end

  private

    def assert_transition!(to_status)
      return if TRANSITIONS[status.to_s]&.include?(to_status.to_s)

      errors.add(:base, :invalid_transition,
                 status: human_enum_status(status),
                 new_status: human_enum_status(to_status))
      raise ActiveRecord::RecordInvalid.new(self)
    end

    def human_enum_status(value)
      I18n.t(value, scope: "reservation_statuses", default: value.to_s.humanize)
    end

    def compute_price
      return unless zone && starts_at && ends_at && errors.empty?

      self.total_price_cents = Reservations::PriceCalculator.new(zone:).total_cents(starts_at, ends_at)
    end

    def snapshot_cleaning_minutes
      return unless zone

      self.cleaning_minutes = zone.cleaning_minutes_for(children_party: children_party?)
    end

    # Слот задаётся парой: либо оба конца, либо оба NULL
    def slot_presence
      return if starts_at.blank? == ends_at.blank?

      errors.add(:starts_at, :slot_incomplete)
    end

    def ends_after_start
      return unless starts_at && ends_at

      errors.add(:ends_at, :before_start) if ends_at <= starts_at
    end

    def starts_in_future
      return unless starts_at

      errors.add(:starts_at, :in_past) if starts_at < Time.current
    end

    def duration_within_limits
      return unless zone && starts_at && ends_at && ends_at > starts_at

      minutes = duration_minutes
      if minutes < zone.min_duration_minutes
        errors.add(:ends_at, :duration_too_short, min: zone.min_duration_minutes / 60.0)
      end
      if minutes > zone.max_duration_minutes
        errors.add(:ends_at, :duration_too_long, max: zone.max_duration_minutes / 60.0)
      end
    end

    def guests_within_capacity
      return unless zone && guests_count

      errors.add(:guests_count, :over_capacity, capacity: zone.capacity) if guests_count > zone.capacity
    end

    def zone_is_active
      errors.add(:zone, :inactive) if zone && !zone.active?
    end

    def review_note_present_when_declining
      return unless will_save_change_to_status? && status == "declined" && review_note.blank?

      errors.add(:review_note, :blank)
    end

    # Дружелюбная проверка перед записью (с учётом буфера уборки, без себя);
    # окончательная гарантия — exclusion constraint reservations_no_overlaps.
    def no_overlapping_reservation
      return unless zone && starts_at && ends_at && errors.empty?

      scope = Reservation.blocking
                         .where(zone_id: zone_id)
                         .where(starts_at: ...blocked_until)
                         .where("ends_at + make_interval(mins => cleaning_minutes) > ?", starts_at)
      scope = scope.where.not(id: id) if persisted?
      errors.add(:starts_at, :slot_taken) if scope.exists?
    end

    # Правило звукоизоляции: две караоке-брони не ставим в соседние комнаты
    # одновременно (проверяем на создание; администратор видит шахматку)
    def no_adjacent_karaoke_conflict
      return unless zone&.karaoke? && starts_at && ends_at && errors.empty?

      conflict = Reservation.blocking
                            .joins(:zone)
                            .where(zones: { id: zone.adjacent_zone_ids, room_type: Zone.room_types[:karaoke] })
                            .where(starts_at: ...blocked_until)
                            .where("reservations.ends_at + make_interval(mins => reservations.cleaning_minutes) > ?", starts_at)
                            .exists?
      errors.add(:base, :adjacent_karaoke) if conflict
    end

    # Зоны без модерации подтверждаются автоматически
    def auto_approve
      update!(status: :confirmed)
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.warn("Auto-approve failed for reservation ##{id}: #{e.record.errors.full_messages.to_sentence}")
    end
end
