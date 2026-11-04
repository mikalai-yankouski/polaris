module AdminChartsHelper
  # Палитра бренда: шампань → аметист → бирюза → индиго → роза → янтарь
  PALETTE = [ "#F2D58A", "#9A8BFA", "#45E0C8", "#5B8CFF", "#FDA4AF", "#FCD34D" ].freeze

  STATUS_COLORS = {
    "На рассмотрении" => "#FCD34D",
    "Подтверждена" => "#45E0C8",
    "Отклонена" => "#FDA4AF",
    "Отменена" => "#7C88AD",
    "Завершена" => "#5B8CFF"
  }.freeze

  # Светлая палитра: те же роли, глубже тона для белого фона
  PALETTE_LIGHT = [ "#B98A2E", "#5B48C7", "#0D9488", "#2F5FE0", "#D05672", "#A16207" ].freeze

  STATUS_COLORS_LIGHT = {
    "На рассмотрении" => "#A16207",
    "Подтверждена" => "#0D9488",
    "Отклонена" => "#D05672",
    "Отменена" => "#78716C",
    "Завершена" => "#2F5FE0"
  }.freeze

  def chart_palette
    admin_dark? ? PALETTE : PALETTE_LIGHT
  end

  # Общие опции Chartkick + Chart.js (по мотивам varka)
  def admin_chart_options(height: "280px", **extra)
    {
      height:,
      thousands: " ",
      decimal: ",",
      colors: chart_palette,
      library: {
        plugins: { legend: { display: false } },
        datasets: [ { borderRadius: 6, borderSkipped: "start", maxBarThickness: 46, categoryPercentage: 0.72 } ],
        scales: {
          x: { grid: { display: false }, ticks: { maxRotation: 0, autoSkip: false } },
          y: { border: { display: false }, grid: { color: chart_grid_color }, ticks: { precision: 0 } }
        }
      }
    }.deep_merge(extra)
  end

  def chart_grid_color
    admin_dark? ? "rgba(255,255,255,0.07)" : "rgba(25,22,16,0.08)"
  end

  def chart_legend_color
    admin_dark? ? "#9AA5C7" : "#57534E"
  end

  # Линия с мягкой заливкой области
  def admin_line_options(color:, height: "280px")
    light = !admin_dark?
    color = PALETTE_LIGHT[1] if light && color == "#9A8BFA"
    admin_chart_options(height:,
      colors: [ color ],
      library: {
        datasets: [ { type: "line", tension: 0.35, borderWidth: 2, pointRadius: 0, pointHoverRadius: 5,
                     borderColor: color, backgroundColor: "#{color}22", fill: true, borderRadius: nil, maxBarThickness: nil } ],
        scales: {
          x: { grid: { display: false }, ticks: { maxRotation: 0, autoSkip: true, maxTicksLimit: 8 } },
          y: { border: { display: false }, grid: { color: "rgba(255,255,255,0.07)" }, ticks: { precision: 0 } }
        }
      })
  end

  # Пончик со статусами: единственный график с легендой.
  # Цвета мапим по подписям данных, а не по порядку
  def admin_status_donut_options(data, height: "280px")
    palette = admin_dark? ? STATUS_COLORS : STATUS_COLORS_LIGHT
    {
      height:,
      donut: true,
      thousands: " ",
      decimal: ",",
      colors: data.keys.map { |label| palette.fetch(label, "#78716C") },
      legend: "bottom",
      library: {
        cutout: "68%",
        plugins: {
          legend: {
            display: true,
            position: "bottom",
            labels: { color: chart_legend_color, boxWidth: 10, boxHeight: 10, usePointStyle: true, padding: 14 }
          }
        }
      }
    }
  end
end
