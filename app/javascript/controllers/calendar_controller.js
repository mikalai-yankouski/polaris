import { Controller } from "@hotwired/stimulus"

const MONTHS = ["Январь", "Февраль", "Март", "Апрель", "Май", "Июнь",
                "Июль", "Август", "Сентябрь", "Октябрь", "Ноябрь", "Декабрь"]
const WEEKDAYS = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]

// Календарь заявки: сетка месяца всегда открыта — клик по дате сразу выбирает её.
// Прошедшие дни недоступны, «сегодня» обведено золотом, выбранный день залит.
// Дизайн-паттерн — inline calendar с 21st.dev (halaska-studio), адаптирован под тему Polaris.
export default class extends Controller {
  static targets = ["title", "grid", "input", "prev"]

  connect() {
    const today = new Date()
    this.today = new Date(today.getFullYear(), today.getMonth(), today.getDate())
    this.selected = this.inputTarget.value ? this.fromInput(this.inputTarget.value) : null
    const start = this.selected && this.selected >= this.today ? this.selected : this.today
    this.view = new Date(start.getFullYear(), start.getMonth(), 1)
    this.render()
  }

  nav(event) {
    const direction = Number(event.currentTarget.dataset.direction)
    const next = new Date(this.view.getFullYear(), this.view.getMonth() + direction, 1)
    const floor = new Date(this.today.getFullYear(), this.today.getMonth(), 1)
    if (next < floor) return

    this.view = next
    this.render()
  }

  pick(date) {
    this.selected = date
    this.inputTarget.value = this.toInput(date)
    this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))
    this.render()
  }

  render() {
    this.titleTarget.textContent = `${MONTHS[this.view.getMonth()]} ${this.view.getFullYear()}`
    this.prevTarget.disabled = this.view <= new Date(this.today.getFullYear(), this.today.getMonth(), 1)

    const year = this.view.getFullYear()
    const month = this.view.getMonth()
    const firstWeekday = (new Date(year, month, 1).getDay() + 6) % 7 // неделя с понедельника
    const daysInMonth = new Date(year, month + 1, 0).getDate()

    const grid = document.createElement("div")
    grid.className = "cal-grid"

    for (const day of WEEKDAYS) {
      const cell = document.createElement("span")
      cell.className = "cal-wd"
      cell.textContent = day
      grid.appendChild(cell)
    }
    for (let i = 0; i < firstWeekday; i++) grid.appendChild(document.createElement("span"))

    for (let day = 1; day <= daysInMonth; day++) {
      const date = new Date(year, month, day)
      const button = document.createElement("button")
      button.type = "button"
      button.className = "cal-day"
      button.textContent = day
      button.disabled = date < this.today
      if (date.getTime() === this.today.getTime()) button.classList.add("cal-day--today")
      if (this.selected && date.getTime() === this.selected.getTime()) button.classList.add("cal-day--sel")
      button.addEventListener("click", () => this.pick(date))
      grid.appendChild(button)
    }

    this.gridTarget.replaceChildren(grid)
  }

  fromInput(value) {
    const [y, m, d] = value.split("-").map(Number)
    return new Date(y, m - 1, d)
  }

  toInput(date) {
    const pad = (n) => String(n).padStart(2, "0")
    return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`
  }
}
