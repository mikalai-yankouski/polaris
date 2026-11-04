module Reports
  # Экспорт отчёта «занятые часы по комнатам» в xlsx (caxlsx).
  # Верстка как в varka: бренд-шапка, зебра, тёмный итог, KPI-сводка,
  # закреплённая шапка. Палитра — «ночное небо» polaris: night/star/aurora.
  class RoomHoursXlsx
    COLUMNS = 5

    # Палитра из --color-night/star/aurora + нейтральные для табличной части.
    NIGHT_DEEP = "05070F" # night-900 — бренд-шапка
    NIGHT = "0A0D1A"      # night-800 — шапка таблицы и итог
    STAR = "F8E7BA"       # star-300 — золотой текст на ночном
    GOLD = "E4BC63"       # star-500 — воркмарк
    GOLD_DEEP = "8C6D1F"  # заглушённое золото для групповых заголовков
    AURORA = "9A8BFA"     # aurora-300 — подзаголовок на ночном
    STAR_SOFT = "F6EFDB"  # мягкое золото для строки-заголовка
    CANVAS = "F0F1F6"     # холодный фон для KPI и групп
    SURFACE = "FFFFFF"
    ZEBRA = "F5F6FA"
    BORDER = "E4E7F0"
    MUTED = "6E7488"
    INK = "141A2E"

    def initialize(from:, to:, rows:, totals:)
      @from = from
      @to = to
      @rows = rows
      @totals = totals
    end

    def filename
      "room-hours-#{@from.strftime('%d.%m.%Y')}-#{@to.strftime('%d.%m.%Y')}.xlsx"
    end

    def build
      package = Axlsx::Package.new
      package.use_shared_strings = true
      workbook = package.workbook
      styles = build_styles(workbook)

      workbook.add_worksheet(name: I18n.t("admin.reports.sheet_name")) do |sheet|
        brand_block(sheet, styles)
        sheet.add_row headers, style: header_styles(styles), height: 22

        if @totals.bookings.zero?
          sheet.add_row [ I18n.t("admin.reports.empty"), nil, nil, nil, nil ], style: styles[:muted], height: 20
        else
          @rows.each_with_index { |row, index| data_row(sheet, styles, row, zebra: index.odd?) }
        end

        spacer(sheet, styles)
        total_row(sheet, styles)
        add_summary(sheet, styles)

        sheet.column_widths 34, 18, 12, 12, 16
        # Печать/PDF: альбомная, вся ширина таблицы на одном листе.
        sheet.page_setup.orientation = :landscape
        sheet.page_setup.fit_to_width = 1
        sheet.sheet_pr.page_setup_pr.fit_to_page = true
        # Бренд-шапка (3 строки) + спейсер + строка заголовков — закреплены.
        sheet.sheet_view.pane do |pane|
          pane.state = :frozen
          pane.y_split = 5
          pane.top_left_cell = "A6"
          pane.active_pane = :bottom_left
        end
      end

      package.to_stream.read
    end

    private

    def build_styles(workbook)
      s = workbook.styles
      thin = { style: :thin, color: BORDER }
      base = { border: thin, alignment: { vertical: :center } }

      {
        brand: s.add_style(
          b: true, sz: 18, fg_color: GOLD, bg_color: NIGHT_DEEP,
          alignment: { horizontal: :left, vertical: :center }
        ),
        brand_sub: s.add_style(
          sz: 10, fg_color: AURORA, bg_color: NIGHT_DEEP,
          alignment: { horizontal: :left, vertical: :center }
        ),
        title: s.add_style(
          b: true, sz: 14, fg_color: INK, bg_color: STAR_SOFT,
          alignment: { horizontal: :left, vertical: :center }, border: thin
        ),
        subtitle: s.add_style(
          sz: 10, fg_color: MUTED, bg_color: STAR_SOFT,
          alignment: { horizontal: :left, vertical: :center }, border: thin
        ),
        header: s.add_style(
          b: true, sz: 10, fg_color: STAR, bg_color: NIGHT, border: thin,
          alignment: { horizontal: :left, vertical: :center, wrap_text: true }
        ),
        header_right: s.add_style(
          b: true, sz: 10, fg_color: STAR, bg_color: NIGHT, border: thin,
          alignment: { horizontal: :right, vertical: :center, wrap_text: true }
        ),
        group: s.add_style(
          b: true, sz: 9, fg_color: GOLD_DEEP, bg_color: CANVAS, border: thin,
          alignment: { horizontal: :left, vertical: :center }
        ),
        label: s.add_style(base.merge(sz: 10, fg_color: INK, bg_color: SURFACE)),
        label_zebra: s.add_style(base.merge(sz: 10, fg_color: INK, bg_color: ZEBRA)),
        money: s.add_style(base.merge(sz: 10, fg_color: INK, bg_color: SURFACE, format_code: "#,##0.00", alignment: { horizontal: :right, vertical: :center })),
        money_zebra: s.add_style(base.merge(sz: 10, fg_color: INK, bg_color: ZEBRA, format_code: "#,##0.00", alignment: { horizontal: :right, vertical: :center })),
        hours: s.add_style(base.merge(sz: 10, fg_color: INK, bg_color: SURFACE, format_code: "0.0", alignment: { horizontal: :right, vertical: :center })),
        hours_zebra: s.add_style(base.merge(sz: 10, fg_color: INK, bg_color: ZEBRA, format_code: "0.0", alignment: { horizontal: :right, vertical: :center })),
        qty: s.add_style(base.merge(sz: 10, fg_color: INK, bg_color: SURFACE, format_code: "#,##0", alignment: { horizontal: :right, vertical: :center })),
        qty_zebra: s.add_style(base.merge(sz: 10, fg_color: INK, bg_color: ZEBRA, format_code: "#,##0", alignment: { horizontal: :right, vertical: :center })),
        muted: s.add_style(base.merge(sz: 9, fg_color: MUTED, bg_color: SURFACE)),
        muted_zebra: s.add_style(base.merge(sz: 9, fg_color: MUTED, bg_color: ZEBRA)),
        total_label: s.add_style(base.merge(b: true, sz: 12, fg_color: STAR, bg_color: NIGHT)),
        total_qty: s.add_style(base.merge(b: true, sz: 12, fg_color: STAR, bg_color: NIGHT, format_code: "#,##0", alignment: { horizontal: :right, vertical: :center })),
        total_hours: s.add_style(base.merge(b: true, sz: 12, fg_color: STAR, bg_color: NIGHT, format_code: "0.0", alignment: { horizontal: :right, vertical: :center })),
        total_money: s.add_style(base.merge(b: true, sz: 12, fg_color: STAR, bg_color: NIGHT, format_code: "#,##0.00", alignment: { horizontal: :right, vertical: :center })),
        kpi_label: s.add_style(base.merge(sz: 10, fg_color: MUTED, bg_color: CANVAS)),
        kpi_money: s.add_style(base.merge(b: true, sz: 11, fg_color: INK, bg_color: CANVAS, format_code: "#,##0.00", alignment: { horizontal: :right, vertical: :center })),
        kpi_hours: s.add_style(base.merge(b: true, sz: 11, fg_color: INK, bg_color: CANVAS, format_code: "0.0", alignment: { horizontal: :right, vertical: :center })),
        kpi_int: s.add_style(base.merge(b: true, sz: 11, fg_color: INK, bg_color: CANVAS, format_code: "#,##0", alignment: { horizontal: :right, vertical: :center })),
        empty: s.add_style(bg_color: CANVAS)
      }
    end

    def brand_block(sheet, styles)
      last_col = ("A".ord + COLUMNS - 1).chr
      sheet.add_row Array.new(COLUMNS), style: styles[:brand], height: 28
      sheet.rows.last.cells[0].value = "POLARIS"
      sheet.merge_cells("A#{sheet.rows.size}:#{last_col}#{sheet.rows.size}")

      sheet.add_row Array.new(COLUMNS), style: styles[:title], height: 24
      sheet.rows.last.cells[0].value = I18n.t("admin.reports.room_hours.title")
      sheet.merge_cells("A#{sheet.rows.size}:#{last_col}#{sheet.rows.size}")

      sheet.add_row Array.new(COLUMNS), style: styles[:subtitle], height: 18
      sheet.rows.last.cells[0].value = period_label
      sheet.merge_cells("A#{sheet.rows.size}:#{last_col}#{sheet.rows.size}")

      sheet.add_row Array.new(COLUMNS), style: styles[:empty], height: 8
    end

    def data_row(sheet, styles, row, zebra:)
      sheet.add_row(
        [ row.zone.to_s, row.zone.room_type_label, row.bookings, row.hours, row.revenue_cents / 100.0 ],
        style: [
          zebra ? styles[:label_zebra] : styles[:label],
          zebra ? styles[:muted_zebra] : styles[:muted],
          zebra ? styles[:qty_zebra] : styles[:qty],
          zebra ? styles[:hours_zebra] : styles[:hours],
          zebra ? styles[:money_zebra] : styles[:money]
        ],
        height: 20
      )
    end

    def total_row(sheet, styles)
      sheet.add_row(
        [ I18n.t("admin.reports.total"), nil, @totals.bookings, @totals.hours, @totals.revenue_cents / 100.0 ],
        style: [
          styles[:total_label], styles[:total_label],
          styles[:total_qty], styles[:total_hours], styles[:total_money]
        ],
        height: 26
      )
    end

    def add_summary(sheet, styles)
      spacer(sheet, styles)
      sheet.add_row [ I18n.t("admin.reports.summary"), nil, nil, nil, nil ], style: styles[:group], height: 20

      kpi(sheet, styles, :days, days, :int)
      kpi(sheet, styles, :active_zones, active_zones, :int)
      kpi(sheet, styles, :avg_revenue, avg_revenue, :money)
      kpi(sheet, styles, :avg_duration, avg_duration, :hours)
      kpi(sheet, styles, :revenue_per_day, revenue_per_day, :money)
      kpi(sheet, styles, :hours_per_day, hours_per_day, :hours)
    end

    def kpi(sheet, styles, key, value, kind)
      value_style = styles[:"kpi_#{kind}"]
      sheet.add_row(
        [ I18n.t(key, scope: "admin.reports.kpi"), value, nil, nil, nil ],
        style: [ styles[:kpi_label], value_style, styles[:kpi_label], styles[:kpi_label], styles[:kpi_label] ],
        height: 20
      )
    end

    def spacer(sheet, styles)
      sheet.add_row [], style: styles[:empty], height: 10
    end

    def headers
      [
        Zone.model_name.human,
        I18n.t("admin.reports.room_type"),
        I18n.t("admin.reports.bookings"),
        I18n.t("admin.reports.hours"),
        I18n.t("admin.reports.revenue_byn")
      ]
    end

    def header_styles(styles)
      [ styles[:header], styles[:header], styles[:header_right], styles[:header_right], styles[:header_right] ]
    end

    def period_label
      "#{@from.strftime('%d.%m.%Y')} — #{@to.strftime('%d.%m.%Y')}"
    end

    def days
      (@to - @from).to_i + 1
    end

    def active_zones
      @rows.count { |row| row.bookings.positive? }
    end

    def avg_revenue
      return 0 if @totals.bookings.zero?

      (@totals.revenue_cents / 100.0 / @totals.bookings).round(2)
    end

    def avg_duration
      return 0 if @totals.bookings.zero?

      (@totals.hours / @totals.bookings).round(1)
    end

    def revenue_per_day
      (@totals.revenue_cents / 100.0 / days).round(2)
    end

    def hours_per_day
      (@totals.hours / days).round(1)
    end
  end
end
