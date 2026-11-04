import { Controller } from "@hotwired/stimulus"

// Верхняя планка атласа: тень при скролле
export default class extends Controller {
  connect() {
    this.onScroll = () => this.element.classList.toggle("is-scrolled", window.scrollY > 12)
    this.onScroll()
    window.addEventListener("scroll", this.onScroll, { passive: true })
  }

  disconnect() {
    window.removeEventListener("scroll", this.onScroll)
  }
}
