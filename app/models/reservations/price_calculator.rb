module Reservations
  # Расчёт стоимости интервала по тарифной сетке комнаты:
  # каждая минута тарифицируется по правилу «будни/выходные × окно времени суток».
  # Если ни одно правило не покрывает минуту — базовая ставка комнаты.
  class PriceCalculator
    def initialize(zone:, rules: nil)
      @zone = zone
      @rules = rules || zone.price_rules.to_a
      @cache = {}
    end

    def total_cents(starts_at, ends_at)
      return 0 if ends_at <= starts_at

      # неполная минута считается полной; каждая минута тарифицируется
      # по правилу, действующему в момент её начала
      minutes = ((ends_at - starts_at) / 60.0).ceil
      sum = 0
      minutes.times do |i|
        sum += rate_for(starts_at + i.minutes)
      end
      (sum / 60.0).round
    end

    private

    def rate_for(time)
      kind = weekend?(time) ? :weekend : :weekday
      tod = time.hour * 60 + time.min
      @cache[[ kind, tod ]] ||= begin
        rule = @rules.find { |r| r.day_kind == kind.to_s && covers?(r, tod) }
        rule ? rule.hourly_rate_cents : @zone.hourly_rate_cents
      end
    end

    def covers?(rule, minute)
      s = rule.start_minutes
      e = rule.end_minutes
      e += PriceRule::MINUTES_IN_DAY if rule.wraps_midnight?
      m = minute < s && rule.wraps_midnight? ? minute + PriceRule::MINUTES_IN_DAY : minute
      (s...e).cover?(m)
    end

    def weekend?(time)
      time.saturday? || time.sunday?
    end
  end
end
