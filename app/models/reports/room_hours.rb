module Reports
  # Отчёт «занятые часы по комнатам» за период.
  # Учитываются подтверждённые и завершённые брони, начавшиеся в периоде.
  class RoomHours
    Row = Struct.new(:zone, :bookings, :hours, :revenue_cents, keyword_init: true)

    attr_reader :from, :to

    def initialize(from:, to:)
      @from = from
      @to = to
    end

    def rows
      counts = base.count
      minutes = base.sum("EXTRACT(EPOCH FROM (ends_at - starts_at)) / 60")
      revenue = base.sum(:total_price_cents)

      Zone.ordered.map do |zone|
        Row.new(
          zone:,
          bookings: counts[zone.id].to_i,
          hours: (minutes[zone.id].to_f / 60).round(1),
          revenue_cents: revenue[zone.id].to_i
        )
      end
    end

    private

    def base
      Reservation.paid
                 .where(starts_at: from.beginning_of_day..to.end_of_day)
                 .group(:zone_id)
    end
  end
end
