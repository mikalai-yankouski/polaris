import { Controller } from "@hotwired/stimulus"

// Обратный отсчёт до конца брони; за 10 минут — предупреждение, после конца — просрочено
export default class extends Controller {
  static values = {
    endsAt: String,
    warningSeconds: { type: Number, default: 600 }
  }

  connect() {
    this.endsAt = new Date(this.endsAtValue)
    this.tick()
    this.timer = setInterval(() => this.tick(), 1000)
  }

  disconnect() {
    clearInterval(this.timer)
  }

  tick() {
    const remaining = Math.floor((this.endsAt - new Date()) / 1000)
    const label = this.element.querySelector("[data-countdown-target='label']")

    if (remaining > this.warningSecondsValue) {
      this.element.className = this.element.dataset.baseClass || ""
      label.textContent = this.format(remaining)
    } else if (remaining > 0) {
      this.element.className = this.element.dataset.warningClass || ""
      label.textContent = this.format(remaining)
    } else {
      this.element.className = this.element.dataset.overdueClass || ""
      label.textContent = this.format(remaining)
    }
  }

  format(seconds) {
    const sign = seconds < 0 ? "+" : ""
    const abs = Math.abs(seconds)
    const h = Math.floor(abs / 3600)
    const m = Math.floor((abs % 3600) / 60)
    const s = abs % 60
    const mm = String(m).padStart(2, "0")
    const ss = String(s).padStart(2, "0")
    return h > 0 ? `${sign}${h}:${mm}:${ss}` : `${sign}${mm}:${ss}`
  }
}
