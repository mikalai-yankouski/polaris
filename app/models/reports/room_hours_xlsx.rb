module Reports
  # Экспорт отчёта «занятые часы по комнатам» в xlsx (caxlsx).
  class RoomHoursXlsx
    def initialize(from:, to:, rows:, totals:)
      @from = from
      @to = to
      @rows = rows
      @totals = totals
    end

    def build
      package = Axlsx::Package.new
      workbook = package.workbook

      workbook.styles do |s|
        @header = s.add_style(b: true, bg_color: "E2E8F0", border: { style: :thin, color: "CBD5E1" })
        @cell = s.add_style(border: { style: :thin, color: "CBD5E1" }, format_code: "#,##0.00")
        @total = s.add_style(b: true, bg_color: "F1F5F9", border: { style: :thin, color: "CBD5E1" })
      end

      workbook.add_worksheet(name: I18n.t("admin.reports.sheet_name")) do |sheet|
        sheet.add_row
        sheet.add_row [ I18n.t("admin.reports.room_hours.title"), "#{@from.strftime('%d.%m.%Y')} — #{@to.strftime('%d.%m.%Y')}" ], b: true
        sheet.add_row
        sheet.add_row headers, style: @header
        @rows.each do |row|
          sheet.add_row [ row.zone.to_s, row.zone.room_type_label, row.bookings, row.hours, (row.revenue_cents / 100.0) ], style: @cell
        end
        sheet.add_row [
          I18n.t("admin.reports.total"), "", @totals.bookings, @totals.hours, (@totals.revenue_cents / 100.0)
        ], style: @total
        sheet.column_widths 32, 16, 12, 12, 14
      end

      package.to_stream.read
    end

    private

    def headers
      [
        Zone.model_name.human,
        I18n.t("admin.reports.room_type"),
        I18n.t("admin.reports.bookings"),
        I18n.t("admin.reports.hours"),
        I18n.t("admin.reports.revenue")
      ]
    end
  end
end
