module Schedule
  # Шахматка: комнаты × часы суток, статусы «свободна / занята / уборка».
  class Grid
    DAY_START_HOUR = 8
    DAY_END_HOUR   = 24 # час 24 = полуночный рубеж следующего дня

    Cell = Struct.new(:hour, :state, :reservation, keyword_init: true)

    attr_reader :date, :zones

    def initialize(date:, zones:)
      @date = date
      @zones = zones
    end

    def hours
      (DAY_START_HOUR...DAY_END_HOUR)
    end

    # Ячейки строки комнаты: по одной на час
    def cells_for(zone)
      reservations = segments_by_zone[zone.id] || []
      hours.map do |hour|
        hour_start = date.beginning_of_day + hour.hours
        hour_end   = hour_start + 1.hour

        booking = reservations.find { |r| r.starts_at < hour_end && hour_start < r.ends_at }
        next Cell.new(hour:, state: booking.status.to_sym, reservation: booking) if booking

        cleaning = reservations.find { |r| r.ends_at < hour_end && hour_start < r.blocked_until }
        next Cell.new(hour:, state: :cleaning, reservation: cleaning) if cleaning

        Cell.new(hour:, state: :free, reservation: nil)
      end
    end

    private

    def segments_by_zone
      @segments_by_zone ||= begin
        day_start = date.beginning_of_day + DAY_START_HOUR.hours
        day_end   = date.beginning_of_day + DAY_END_HOUR.hours
        Reservation.blocking
                   .includes(:zone, :user)
                   .where(starts_at: ...day_end)
                   .where("ends_at + make_interval(mins => cleaning_minutes) > ?", day_start)
                   .order(:starts_at)
                   .group_by(&:zone_id)
      end
    end
  end
end
