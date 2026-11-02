module Admin
  class ReportsController < BaseController
    def room_hours
      @from = parse_date(params[:from], 30.days.ago.to_date)
      @to = parse_date(params[:to], Date.current)
      @rows = Reports::RoomHours.new(from: @from, to: @to).rows
      @totals = totals(@rows)

      respond_to do |format|
        format.html
        format.xlsx do
          xlsx = Reports::RoomHoursXlsx.new(from: @from, to: @to, rows: @rows, totals: @totals).build
          send_data xlsx,
                    filename: "polaris-room-hours-#{@from}-#{@to}.xlsx",
                    type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        end
      end
    end

    private

    Totals = Struct.new(:bookings, :hours, :revenue_cents, keyword_init: true)

    def totals(rows)
      Totals.new(
        bookings: rows.sum(&:bookings),
        hours: rows.sum(&:hours).round(1),
        revenue_cents: rows.sum(&:revenue_cents)
      )
    end

    def parse_date(value, default)
      Date.parse(value.to_s)
    rescue ArgumentError, TypeError
      default
    end
  end
end
