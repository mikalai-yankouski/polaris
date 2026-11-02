module Analytics
  # Набор запросов для административного дашборда.
  # Период по умолчанию — последние 30 дней.
  class Dashboard
    attr_reader :period

    # Рабочее окно здания: 15 часов в сутки (08:00–23:00)
    DAILY_WINDOW_HOURS = 15

    def initialize(period: 30.days.ago.beginning_of_day..Time.current)
      @period = period
    end

    def days_count
      [ (period.end - period.begin).to_i / 1.day, 1 ].max
    end

    def total_reservations
      reservations_in_period.count
    end

    def total_guests
      reservations_in_period.sum(:guests_count)
    end

    def revenue_cents
      paid_in_period.sum(:total_price_cents)
    end

    def avg_utilization
      values = utilization_by_zone.values
      return 0 if values.empty?

      (values.sum / values.size)
    end

    def reservations_by_day
      reservations_in_period.group_by_day(:starts_at).count.transform_keys { |day| day.strftime("%d.%m") }
    end

    def revenue_by_week
      paid_in_period.group_by_week(:starts_at).sum(:total_price_cents)
                    .transform_keys { |week| week.strftime("%d.%m") }
    end

    def bookings_by_weekday
      counts = reservations_in_period.group_by_day_of_week(:starts_at, week_start: :monday).count
      counts.keys.sort.map { |dow| [ weekday_name(dow), counts[dow] ] }
    end

    def bookings_by_hour
      reservations_in_period.group_by_hour_of_day(:starts_at).count.sort.to_h
    end

    def status_breakdown
      reservations_in_period.group(:status).count
                            .transform_keys { |status| I18n.t(status, scope: "reservation_statuses") }
    end

    def top_zones
      reservations_in_period.joins(:zone).group("zones.name").order(count_all: :desc).limit(5).count
    end

    def utilization_by_zone
      available_hours = days_count * DAILY_WINDOW_HOURS
      zones.index_with do |zone|
        booked_seconds = zone.reservations.paid.where(starts_at: period).sum("EXTRACT(EPOCH FROM (ends_at - starts_at))")
        next 0 if available_hours.zero?

        booked_hours = booked_seconds / 3600.0
        [ (booked_hours / available_hours * 100).round(1), 100.0 ].min
      end
    end

    private

    def zones
      @zones ||= Zone.active.ordered.to_a
    end

    def reservations_in_period
      Reservation.where(starts_at: period)
    end

    def paid_in_period
      Reservation.paid.where(starts_at: period)
    end

    def weekday_name(day_of_week_index)
      # groupdate: 0 = воскресенье
      date = Date.commercial(Date.current.cwyear, 1, (day_of_week_index + 1) % 7 + 1)
      I18n.l(date, format: "%a")
    end
  end
end
