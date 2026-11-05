import { Controller } from "@hotwired/stimulus"

// Галерея фото зала: слайд-трек, стрелки, точки/миниатюры, свайп и стрелки клавиатуры.
// Не зацикливается: на краях стрелки гаснут, позиция всегда видна по счётчику.
export default class extends Controller {
  static targets = ["viewport", "track", "counter", "goto", "prev", "next"]

  connect() {
    this.index = 0
    this.total = this.trackTarget.children.length
    this.pointer = null
    this.render()

    this.keydown = (event) => {
      if (event.key === "ArrowLeft") { event.preventDefault(); this.prev() }
      if (event.key === "ArrowRight") { event.preventDefault(); this.next() }
    }
    this.element.addEventListener("keydown", this.keydown)
  }

  disconnect() {
    this.element.removeEventListener("keydown", this.keydown)
  }

  prev() { this.go(this.index - 1) }
  next() { this.go(this.index + 1) }

  select(event) {
    this.go(Number(event.currentTarget.dataset.index))
  }

  go(index) {
    this.index = Math.max(0, Math.min(this.total - 1, index))
    this.render()
  }

  render() {
    this.trackTarget.style.transform = `translateX(-${this.index * 100}%)`

    if (this.hasCounterTarget) {
      this.counterTarget.textContent = `${this.pad(this.index + 1)} / ${this.pad(this.total)}`
    }

    this.gotoTargets.forEach((item) => {
      const active = Number(item.dataset.index) === this.index
      item.classList.toggle("is-active", active)
      item.setAttribute("aria-current", active ? "true" : "false")
    })

    if (this.hasPrevTarget) this.prevTarget.disabled = this.index === 0
    if (this.hasNextTarget) this.nextTarget.disabled = this.index === this.total - 1
  }

  // Свайп: начинаем только не с кнопки, вертикальный скролл страницы не трогаем
  pointerdown(event) {
    if (event.pointerType === "mouse" && event.button !== 0) return
    if (event.target.closest("button")) return

    this.pointer = { x: event.clientX, y: event.clientY, dx: 0, dy: 0 }
    this.viewportTarget.setPointerCapture(event.pointerId)
  }

  pointermove(event) {
    if (!this.pointer) return
    this.pointer.dx = event.clientX - this.pointer.x
    this.pointer.dy = event.clientY - this.pointer.y
  }

  pointerup() {
    if (!this.pointer) return
    const { dx, dy } = this.pointer
    this.pointer = null

    if (Math.abs(dx) < 40 || Math.abs(dx) < Math.abs(dy)) return
    dx < 0 ? this.next() : this.prev()
  }

  pad(number) {
    return String(number).padStart(2, "0")
  }
}
