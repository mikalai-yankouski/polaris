import { Controller } from "@hotwired/stimulus"

const AUTOPLAY_MS = 5000

// Галерея фото зала: слайд-трек, стрелки, точки/миниатюры, свайп и стрелки клавиатуры.
// Слайды крутятся сами, по кругу: пауза при наведении и в скрытой вкладке, любое
// вмешательство останавливает прокрутку до конца визита. При reduced-motion — не крутится.
// Стрелки вручную не зацикливаются: на краях гаснут, позиция всегда видна по счётчику.
export default class extends Controller {
  static targets = ["viewport", "track", "counter", "goto", "prev", "next"]

  connect() {
    this.index = 0
    this.total = this.trackTarget.children.length
    this.pointer = null
    this.stopped = false
    this.timer = null
    this.render()

    this.keydown = (event) => {
      if (event.key === "ArrowLeft") { event.preventDefault(); this.prev() }
      if (event.key === "ArrowRight") { event.preventDefault(); this.next() }
    }
    this.element.addEventListener("keydown", this.keydown)

    this.bindAutoplay()
  }

  disconnect() {
    this.element.removeEventListener("keydown", this.keydown)
    if (this.pointerenter) {
      this.element.removeEventListener("pointerenter", this.pointerenter)
      this.element.removeEventListener("pointerleave", this.pointerleave)
      document.removeEventListener("visibilitychange", this.visibilitychange)
    }
    this.clearTimer()
  }

  bindAutoplay() {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return

    this.pointerenter = () => this.pause()
    this.pointerleave = () => this.resume()
    this.visibilitychange = () => (document.hidden ? this.pause() : this.resume())

    this.element.addEventListener("pointerenter", this.pointerenter)
    this.element.addEventListener("pointerleave", this.pointerleave)
    document.addEventListener("visibilitychange", this.visibilitychange)

    this.schedule()
  }

  prev() { this.manual(this.index - 1) }
  next() { this.manual(this.index + 1) }

  select(event) {
    this.manual(Number(event.currentTarget.dataset.index))
  }

  // Ручное действие останавливает автопрокрутку: гость взял управление на себя
  manual(index) {
    this.stopped = true
    this.clearTimer()
    this.go(index)
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
    try { this.viewportTarget.setPointerCapture(event.pointerId) } catch { /* указатель уже ушёл */ }
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

  pause() { this.clearTimer() }

  resume() {
    if (!this.stopped && !document.hidden) this.schedule()
  }

  schedule() {
    this.clearTimer()
    this.timer = setTimeout(() => {
      this.go((this.index + 1) % this.total)
      this.schedule()
    }, AUTOPLAY_MS)
  }

  clearTimer() {
    if (this.timer) { clearTimeout(this.timer); this.timer = null }
  }

  pad(number) {
    return String(number).padStart(2, "0")
  }
}
