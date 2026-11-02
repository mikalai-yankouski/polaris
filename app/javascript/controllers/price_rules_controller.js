import { Controller } from "@hotwired/stimulus"

// Динамическое добавление/удаление строк тарифов в форме комнаты
export default class extends Controller {
  static targets = ["template", "rows"]

  add(event) {
    event.preventDefault()
    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime())
    this.rowsTarget.insertAdjacentHTML("beforeend", content)
  }

  remove(event) {
    event.preventDefault()
    const row = event.target.closest("tr")
    if (row.dataset.newRecord === "true") {
      row.remove()
    } else {
      row.querySelector("input[type='checkbox'][name*='_destroy']").checked = true
      row.style.display = "none"
    }
  }
}
