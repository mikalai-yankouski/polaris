import { Controller } from "@hotwired/stimulus"

// Живой расчёт длительности и стоимости заявки в форме —
// точно повторяет Reservations::PriceCalculator (тариф «будни/выходные × окно суток»,
// перенос через полночь, неполная минута считается полной, базовая ставка вне окон).
// Время начала не обязательно: без него заявка уходит на согласование, расчёт скрыт.
export default class extends Controller {
  static values = {
    rules: Array,      // [{day_kind, start_minutes, end_minutes, rate}]
    baseRate: Number,  // базовая ставка комнаты, центы/час
    currency: { type: String, default: "BYN" }
  }
  static targets = ["date", "startTime", "duration", "summary", "durationLabel", "total"]

  connect() {
    this.recalculate()
  }

  recalculate() {
    const startsAt = this.parseStartsAt()
    const minutes = parseInt(this.durationTarget.value, 10)

    if (!startsAt || !minutes || minutes <= 0) {
      this.summaryTarget.classList.add("hidden")
      return
    }

    let sum = 0
    for (let i = 0; i < minutes; i++) {
      sum += this.rateFor(new Date(startsAt.getTime() + i * 60000))
    }
    const totalCents = Math.round(sum / 60)

    this.durationLabelTarget.textContent = this.formatDuration(minutes)
    this.totalTarget.textContent = this.formatMoney(totalCents)
    this.summaryTarget.classList.remove("hidden")
  }

  // Дата из календаря + выбранное время начала ("YYYY-MM-DD" + "HH:MM")
  parseStartsAt() {
    const date = this.dateTarget.value
    const time = this.startTimeTarget.value
    if (!date || !time) return null

    const m = date.match(/^(\d{4})-(\d{2})-(\d{2})$/)
    const t = time.match(/^(\d{2}):(\d{2})$/)
    if (!m || !t) return null

    return new Date(+m[1], +m[2] - 1, +m[3], +t[1], +t[2])
  }

  rateFor(time) {
    const dayKind = (time.getDay() === 0 || time.getDay() === 6) ? "weekend" : "weekday"
    const minuteOfDay = time.getHours() * 60 + time.getMinutes()

    for (const rule of this.rulesValue) {
      if (rule.day_kind !== dayKind) continue
      const s = rule.start_minutes
      const e = rule.end_minutes
      const wraps = e <= s
      const end = wraps ? e + 1440 : e
      const m = wraps && minuteOfDay < s ? minuteOfDay + 1440 : minuteOfDay
      if (m >= s && m < end) return rule.rate
    }
    return this.baseRateValue
  }

  formatDuration(minutes) {
    const h = Math.floor(minutes / 60)
    const min = minutes % 60
    if (min === 0) return `${h} ч`
    if (h === 0) return `${min} мин`
    return `${h} ч ${min} мин`
  }

  formatMoney(cents) {
    const amount = (cents / 100).toFixed(2).replace(".", ",")
    return `${amount} ${this.currencyValue}`
  }
}
