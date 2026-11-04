import { Controller } from "@hotwired/stimulus"

// Кастомный дропдаун в стиле «ночного неба»: кнопка + стеклянная панель опций.
// Значение пишется в скрытый input с именем настоящего поля и диспатчит change —
// нативный select не стилизуется браузером, поэтому собран свой.
export default class extends Controller {
  static targets = ["button", "panel", "input", "label"]

  connect() {
    this.closeIfOutside = (event) => {
      if (!this.element.contains(event.target)) this.close()
    }
    document.addEventListener("click", this.closeIfOutside)
    this.sync()
  }

  disconnect() {
    document.removeEventListener("click", this.closeIfOutside)
  }

  toggle() {
    this.panelTarget.classList.toggle("hidden")
  }

  pick(event) {
    const option = event.currentTarget
    this.inputTarget.value = option.dataset.value
    this.labelTarget.textContent = option.dataset.label
    this.sync()
    this.close()
    this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))
  }

  close() {
    this.panelTarget.classList.add("hidden")
  }

  // Подсветка выбранной опции по текущему значению input
  sync() {
    this.panelTarget.querySelectorAll("[data-value]").forEach((option) => {
      option.classList.toggle("sel-opt--sel", option.dataset.value === this.inputTarget.value)
    })
  }
}
