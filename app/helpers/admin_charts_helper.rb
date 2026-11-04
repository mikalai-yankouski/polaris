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

  # Общие опции Chartkick + Chart.js для тёмной админки (по мотивам varka)
  def admin_chart_options(height: "280px", **extra)
    {
      height:,
      thousands: " ",
      decimal: ",",
      colors: PALETTE,
      library: {
        plugins: { legend: { display: false } },
        datasets: [ { borderRadius: 6, borderSkipped: "start", maxBarThickness: 46, categoryPercentage: 0.72 } ],
        scales: {
          x: { grid: { display: false }, ticks: { maxRotation: 0, autoSkip: false } },
          y: { border: { display: false }, grid: { color: "rgba(255,255,255,0.07)" }, ticks: { precision: 0 } }
        }
      }
    }.deep_merge(extra)
  end

  # Линия с мягкой заливкой области
  def admin_line_options(color:, height: "280px")
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
    {
      height:,
      donut: true,
      thousands: " ",
      decimal: ",",
      colors: data.keys.map { |label| STATUS_COLORS.fetch(label, "#7C88AD") },
      legend: "bottom",
      library: {
        cutout: "68%",
        plugins: {
          legend: {
            display: true,
            position: "bottom",
            labels: { color: "#9AA5C7", boxWidth: 10, boxHeight: 10, usePointStyle: true, padding: 14 }
          }
        }
      }
    }
  end
end
