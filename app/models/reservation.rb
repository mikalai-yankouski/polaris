class Reservation < ApplicationRecord
  # Допустимые переходы статусов; declined/cancelled/completed — терминальные
  TRANSITIONS = {
    "pending"   => %w[confirmed declined cancelled].freeze,
    "confirmed" => %w[cancelled completed].freeze
  }.freeze

  belongs_to :zone
  belongs_to :user

  enum :status, { pending: 0, confirmed: 1, declined: 2, cancelled: 3, completed: 4 }, default: :pending

  scope :blocking, -> { where(status: [ statuses[:pending], statuses[:confirmed] ]) }
  scope :upcoming, -> { blocking.where(ends_at: Time.current..).order(:starts_at) }
  scope :between, ->(range) { where(starts_at: range) }
  scope :paid, -> { where(status: [ statuses[:confirmed], statuses[:completed] ]) }

  validates :starts_at, :ends_at, presence: true
  validates :guests_count, numericality: { only_integer: true, greater_than: 0 }
  validate :ends_after_start
  validate :starts_in_future, on: :create
  validate :duration_within_limits
  validate :guests_within_capacity
  validate :zone_is_active, on: :create
  validate :review_note_present_when_declining
  validate :no_overlapping_reservation, on: :create

  before_validation :compute_price
  after_create :auto_approve, if: -> { zone && !zone.requires_approval }

  def duration_minutes
    return 0 unless starts_at && ends_at

    ((ends_at - starts_at) / 60).to_i
  end

  def confirmable?  = pending?
  def declinable?   = pending?
  def cancellable?  = pending? || confirmed?
  def completable?  = confirmed? && ends_at < Time.current

  def status_label(value = status)
    I18n.t(value, scope: "reservation_statuses", default: value.to_s.humanize)
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

      self.total_price_cents = (zone.hourly_rate_cents * duration_minutes / 60.0).round
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
      # Применяем и на create (auto_approve путь не проходит через decline), и на update
      return unless will_save_change_to_status? && status == "declined" && review_note.blank?

      errors.add(:review_note, :blank)
    end

    # Дружелюбная проверка перед записью; окончательная гарантия —
    # exclusion constraint reservations_no_overlaps на уровне PostgreSQL.
    def no_overlapping_reservation
      return unless zone && starts_at && ends_at && errors.empty?

      conflicts = Reservation.blocking
                             .where(zone_id: zone_id)
                             .where(starts_at: ...ends_at)
                             .where("ends_at > ?", starts_at)
                             .exists?
      errors.add(:starts_at, :slot_taken) if conflicts
    end

    # Зоны без модерации подтверждаются автоматически
    def auto_approve
      update!(status: :confirmed)
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.warn("Auto-approve failed for reservation ##{id}: #{e.record.errors.full_messages.to_sentence}")
    end
end
