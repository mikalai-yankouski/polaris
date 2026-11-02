class PriceRule < ApplicationRecord
  enum :day_kind, { weekday: 0, weekend: 1 }, default: :weekday

  belongs_to :zone

  validates :starts_at_time, :ends_at_time, presence: true
  validates :hourly_rate_cents, numericality: { only_integer: true, greater_than: 0 }
  validate :window_valid
  validate :no_overlap_within_day_kind

  scope :ordered, -> { order(:day_kind, :starts_at_time) }

  MINUTES_IN_DAY = 1440

  def start_minutes = starts_at_time.hour * 60 + starts_at_time.min
  def end_minutes = ends_at_time.hour * 60 + ends_at_time.min

  # Окно, пересекающее полночь (конец <= начала), покрывает два отрезка суток
  def wraps_midnight? = ends_at_time <= starts_at_time

  def day_kind_label
    I18n.t(day_kind, scope: "day_kinds", default: day_kind.to_s.humanize)
  end

  def window_label
    "#{starts_at_time.strftime('%H:%M')}–#{ends_at_time.strftime('%H:%M')}"
  end

  private

    def window_valid
      return unless starts_at_time && ends_at_time
      return unless errors[:starts_at_time].empty? && errors[:ends_at_time].empty?

      errors.add(:ends_at_time, :empty_window) if start_minutes == end_minutes
    end

    def no_overlap_within_day_kind
      return unless zone && valid_window?

      overlap = zone.price_rules.where(day_kind:).where.not(id:).any? do |other|
        arc_covers?(start_minutes, other) || arc_covers?(other.start_minutes, self)
      end
      errors.add(:starts_at_time, :overlap) if overlap
    end

    def valid_window?
      starts_at_time && ends_at_time && start_minutes != end_minutes
    end

    # Дуга суток (с возможным переходом через полночь) содержит минуту m?
    def arc_covers?(minute, rule)
      s = rule.start_minutes
      e = rule.end_minutes
      e += MINUTES_IN_DAY if rule.wraps_midnight?
      m = minute < s && rule.wraps_midnight? ? minute + MINUTES_IN_DAY : minute
      (s...e).cover?(m)
    end
end
