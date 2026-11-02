class Zone < ApplicationRecord
  belongs_to :building
  has_many :zone_amenities, dependent: :destroy
  has_many :amenities, through: :zone_amenities
  has_many :reservations, dependent: :destroy
  has_many_attached :photos

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:name) }

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :capacity, numericality: { only_integer: true, greater_than: 0 }
  validates :floor, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :hourly_rate_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :min_duration_minutes, numericality: { only_integer: true, greater_than: 0 }
  validates :max_duration_minutes, numericality: { only_integer: true, greater_than: 0 }
  validate :max_duration_exceeds_min

  def to_s = name

  # Брони, блокирующие интервал (ожидающие подтверждения и подтверждённые)
  def blocking_reservations(range)
    reservations.blocking
                .where(starts_at: ...range.end)
                .where("ends_at > ?", range.begin)
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
