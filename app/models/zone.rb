class Zone < ApplicationRecord
  belongs_to :building
  has_many :zone_amenities, dependent: :destroy
  has_many :amenities, through: :zone_amenities
  has_many :reservations, dependent: :destroy
  has_many :price_rules, dependent: :destroy
  has_many :zone_adjacencies, dependent: :destroy
  has_many :adjacent_zones, through: :zone_adjacencies
  has_many_attached :photos

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:name) }

  enum :room_type, { lounge: 0, cinema: 1, karaoke: 2, billiard: 3, ps5: 4 }, default: :lounge

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :capacity, numericality: { only_integer: true, greater_than: 0 }
  validates :floor, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :hourly_rate_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :min_duration_minutes, numericality: { only_integer: true, greater_than: 0 }
  validates :max_duration_minutes, numericality: { only_integer: true, greater_than: 0 }
  validates :cleaning_buffer_minutes, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 120 }
  validate :max_duration_exceeds_min

  accepts_nested_attributes_for :price_rules, allow_destroy: true,
                                reject_if: ->(attrs) { attrs["hourly_rate_cents"].blank? }

  def to_s = [ building_code, name ].compact.join(" · ")

  def room_type_label
    I18n.t(room_type, scope: "room_types", default: room_type.to_s.humanize)
  end

  # Буфер уборки с учётом типа брони: после детских — 30 минут
  def cleaning_minutes_for(children_party:)
    children_party ? 30 : cleaning_buffer_minutes
  end

  # Брони, блокирующие интервал (с учётом буфера уборки):
  # бронь занимает комнату на [starts_at, ends_at + cleaning_minutes)
  def blocking_reservations(range)
    reservations.blocking
                .where(starts_at: ...range.end)
                .where("ends_at + make_interval(mins => cleaning_minutes) > ?", range.begin)
                .order(:starts_at)
  end

  def blocked?(range) = blocking_reservations(range).exists?

  private

    def max_duration_exceeds_min
      return unless min_duration_minutes && max_duration_minutes

      if max_duration_minutes < min_duration_minutes
        errors.add(:max_duration_minutes, :less_than_min_duration)
      end
    end
end
