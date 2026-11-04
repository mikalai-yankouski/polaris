// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import { Chart, registerables } from "chart.js"
Chart.register(...registerables)
window.Chart = Chart

// Тёмная тема графиков (админка и публичные графики)
Chart.defaults.color = "#9AA5C7"
Chart.defaults.font.family = "Inter, system-ui, sans-serif"
Chart.defaults.font.size = 11
Chart.defaults.borderColor = "rgba(255, 255, 255, 0.07)"

import "chartkick"
import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

window.Stimulus = Application.start()
eagerLoadControllersFrom("controllers", window.Stimulus)

// ---------------------------------------------------------------------------
// Polaris UI
// ---------------------------------------------------------------------------

const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches

/* Reveal-on-scroll */
function initReveal() {
  const elements = document.querySelectorAll(".reveal:not(.is-visible)")
  if (reducedMotion || !("IntersectionObserver" in window)) {
    elements.forEach((el) => el.classList.add("is-visible"))
    return
  }

  const observer = new IntersectionObserver((entries) => {
    for (const entry of entries) {
      if (entry.isIntersecting) {
        entry.target.classList.add("is-visible")
        observer.unobserve(entry.target)
      }
    }
  }, { threshold: 0.1, rootMargin: "0px 0px -40px 0px" })

  elements.forEach((el) => observer.observe(el))
}

/* Spotlight за курсором */
if (window.matchMedia("(pointer: fine)").matches && !reducedMotion) {
  document.addEventListener("pointermove", (event) => {
    const card = event.target instanceof Element ? event.target.closest(".spotlight") : null
    if (!card) return
    const rect = card.getBoundingClientRect()
    card.style.setProperty("--mx", `${event.clientX - rect.left}px`)
    card.style.setProperty("--my", `${event.clientY - rect.top}px`)
  }, { passive: true })
}

/* Плавающий нав: уплотняется при скролле */
function initNav() {
  const pill = document.querySelector(".nav-pill")
  if (!pill) return
  const onScroll = () => pill.classList.toggle("is-scrolled", window.scrollY > 24)
  onScroll()
  window.addEventListener("scroll", onScroll, { passive: true })
}

/* Созвездия в hero: звёзды дрейфуют, близкие соединяются линиями, изредка метеор */
function initConstellation() {
  const canvas = document.getElementById("constellation")
  if (!canvas) return

  const ctx = canvas.getContext("2d")
  const dpr = Math.min(window.devicePixelRatio || 1, 2)
  let width = 0, height = 0, stars = [], raf = null, meteor = null, nextMeteorAt = 0

  function resize() {
    const rect = canvas.parentElement.getBoundingClientRect()
    width = rect.width
    height = rect.height
    canvas.width = width * dpr
    canvas.height = height * dpr
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0)
    buildStars()
  }

  function buildStars() {
    const count = Math.min(130, Math.round((width * height) / 12000))
    stars = Array.from({ length: count }, () => ({
      x: Math.random() * width,
      y: Math.random() * height,
      r: Math.random() * 1.3 + 0.4,
      vx: (Math.random() - 0.5) * 0.12,
      vy: (Math.random() - 0.5) * 0.08,
      tw: Math.random() * Math.PI * 2,
      gold: Math.random() < 0.14
    }))
  }

  function spawnMeteor() {
    meteor = {
      x: Math.random() * width * 0.7,
      y: Math.random() * height * 0.3,
      vx: 6 + Math.random() * 3,
      vy: 2.2 + Math.random() * 1.2,
      life: 1
    }
  }

  function frame(ts) {
    ctx.clearRect(0, 0, width, height)

    // связи между близкими звёздами
    ctx.lineWidth = 0.6
    for (let i = 0; i < stars.length; i++) {
      for (let j = i + 1; j < stars.length; j++) {
        const a = stars[i], b = stars[j]
        const dx = a.x - b.x, dy = a.y - b.y
        const dist = Math.hypot(dx, dy)
        if (dist < 110) {
          ctx.strokeStyle = `rgba(154, 139, 250, ${(1 - dist / 110) * 0.16})`
          ctx.beginPath()
          ctx.moveTo(a.x, a.y)
          ctx.lineTo(b.x, b.y)
          ctx.stroke()
        }
      }
    }

    // звёзды
    for (const s of stars) {
      s.x += s.vx
      s.y += s.vy
      s.tw += 0.02
      if (s.x < -4) s.x = width + 4
      if (s.x > width + 4) s.x = -4
      if (s.y < -4) s.y = height + 4
      if (s.y > height + 4) s.y = -4

      const alpha = 0.45 + Math.sin(s.tw) * 0.3
      ctx.fillStyle = s.gold ? `rgba(242, 213, 138, ${alpha})` : `rgba(255, 255, 255, ${alpha * 0.85})`
      ctx.beginPath()
      ctx.arc(s.x, s.y, s.r, 0, Math.PI * 2)
      ctx.fill()
    }

    // метеор
    if (!meteor && ts > nextMeteorAt) spawnMeteor()
    if (meteor) {
      const grad = ctx.createLinearGradient(meteor.x, meteor.y, meteor.x - meteor.vx * 14, meteor.y - meteor.vy * 14)
      grad.addColorStop(0, "rgba(248, 231, 186, 0.9)")
      grad.addColorStop(1, "rgba(248, 231, 186, 0)")
      ctx.strokeStyle = grad
      ctx.lineWidth = 1.4
      ctx.beginPath()
      ctx.moveTo(meteor.x, meteor.y)
      ctx.lineTo(meteor.x - meteor.vx * 14, meteor.y - meteor.vy * 14)
      ctx.stroke()
      meteor.x += meteor.vx
      meteor.y += meteor.vy
      meteor.life -= 0.012
      if (meteor.life <= 0 || meteor.x > width + 60) {
        meteor = null
        nextMeteorAt = ts + 5000 + Math.random() * 8000
      }
    }

    raf = requestAnimationFrame(frame)
  }

  function drawStatic() {
    // reduced motion: один статичный кадр
    buildStars()
    ctx.clearRect(0, 0, width, height)
    for (const s of stars) {
      ctx.fillStyle = s.gold ? "rgba(242, 213, 138, 0.7)" : "rgba(255, 255, 255, 0.6)"
      ctx.beginPath()
      ctx.arc(s.x, s.y, s.r, 0, Math.PI * 2)
      ctx.fill()
    }
    ctx.lineWidth = 0.6
    for (let i = 0; i < stars.length; i++) {
      for (let j = i + 1; j < stars.length; j++) {
        const a = stars[i], b = stars[j]
        const dist = Math.hypot(a.x - b.x, a.y - b.y)
        if (dist < 110) {
          ctx.strokeStyle = `rgba(154, 139, 250, ${(1 - dist / 110) * 0.14})`
          ctx.beginPath()
          ctx.moveTo(a.x, a.y)
          ctx.lineTo(b.x, b.y)
          ctx.stroke()
        }
      }
    }
  }

  resize()
  if (reducedMotion) {
    drawStatic()
  } else {
    raf = requestAnimationFrame(frame)
  }

  const onResize = () => {
    resize()
    if (reducedMotion) drawStatic()
  }
  window.addEventListener("resize", onResize, { passive: true })

  // Пауза, когда hero не виден или вкладка скрыта
  document.addEventListener("visibilitychange", () => {
    if (reducedMotion) return
    if (document.hidden && raf) {
      cancelAnimationFrame(raf)
      raf = null
    } else if (!document.hidden && !raf) {
      raf = requestAnimationFrame(frame)
    }
  })
}

document.addEventListener("turbo:load", () => {
  initReveal()
  initNav()
  initConstellation()
})
