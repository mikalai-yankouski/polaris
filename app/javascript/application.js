// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import { Chart, registerables } from "chart.js"
Chart.register(...registerables)
window.Chart = Chart

// Тема графиков: админка светлая/тёмная — класс тела уже в DOM (скрипт отложенный)
if (document.body.classList.contains("admin-light")) {
  Chart.defaults.color = "#57534E"
  Chart.defaults.borderColor = "rgba(25, 22, 16, 0.08)"
} else {
  Chart.defaults.color = "#9AA5C7"
  Chart.defaults.borderColor = "rgba(255, 255, 255, 0.07)"
}
Chart.defaults.font.family = "Inter, system-ui, sans-serif"
Chart.defaults.font.size = 11

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

/* ---------------------------------------------------------------------------
   Атлас: сигнатурные эффекты светлой темы
   (курсор-звезда, кинетический заголовок, созвездие планшетов, параллакс)
--------------------------------------------------------------------------- */

const STAR_SVG = '<svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M12 0c.6 6.5 4.9 10.8 12 12-7.1 1.2-11.4 5.5-12 12-.6-6.5-4.9-10.8-12-12C7.1 10.8 11.4 6.5 12 0Z"/></svg>'

function initStarCursor() {
  if (document.body.hasStarCursorBound) return
  document.body.hasStarCursorBound = true

  const star = document.createElement("div")
  star.className = "cursor-star"
  star.innerHTML = STAR_SVG
  const lag = document.createElement("div")
  lag.className = "cursor-star"
  lag.innerHTML = STAR_SVG
  document.body.append(star, lag)
  document.body.classList.add("has-star-cursor")

  star.style.width = "15px"
  star.style.height = "15px"
  lag.style.width = "9px"
  lag.style.height = "9px"
  lag.style.opacity = "0.35"
  star.style.transform = "translate3d(-100px, -100px, 0)"
  lag.style.transform = "translate3d(-100px, -100px, 0)"

  let mx = -100, my = -100, lx = -100, ly = -100, raf = null

  // Лаг-спутник догоняет курсор; цикл останавливается, когда догнал
  const paint = () => {
    lx += (mx - lx) * 0.22
    ly += (my - ly) * 0.22
    lag.style.transform = `translate3d(${lx - 4.5}px, ${ly - 4.5}px, 0)`
    if (Math.abs(mx - lx) + Math.abs(my - ly) < 0.4) {
      raf = null
      return
    }
    raf = requestAnimationFrame(paint)
  }

  document.addEventListener("pointermove", (event) => {
    mx = event.clientX
    my = event.clientY
    // Главную звезду ставим мгновенно, вне rAF — ноль задержки
    star.style.transform = `translate3d(${mx - 7.5}px, ${my - 7.5}px, 0)`
    star.classList.add("is-on")
    lag.classList.add("is-on")

    const target = event.target instanceof Element ? event.target : null
    const overInteractive = !!target?.closest("a, button, [role='button'], .plate, .zone-card")
    const overText = !!target?.closest("input, textarea, select")

    star.classList.toggle("is-hover", overInteractive)
    star.classList.toggle("is-hidden", overText)
    lag.classList.toggle("is-hidden", overText || overInteractive)

    if (!raf) raf = requestAnimationFrame(paint)
  }, { passive: true })

  document.addEventListener("pointerleave", () => {
    star.classList.remove("is-on")
    lag.classList.remove("is-on")
  })
  document.addEventListener("pointerdown", () => star.style.scale = "0.7")
  document.addEventListener("pointerup", () => star.style.scale = "1")
}

/* Кинетический заголовок: текст превращается в буквы-звёзды */
function initKineticHeadline() {
  document.querySelectorAll("[data-kinetic]").forEach((el) => {
    if (el.dataset.kineticDone) return
    el.dataset.kineticDone = "1"

    let index = 0
    const wrap = (node) => {
      const text = node.textContent
      const frag = document.createDocumentFragment()
      for (const ch of text) {
        if (ch === " ") {
          frag.append(" ")
          continue
        }
        const span = document.createElement("span")
        span.className = "kl"
        span.style.setProperty("--i", index++)
        span.textContent = ch
        frag.append(span)
      }
      node.replaceWith(frag)
    }
    ;[...el.childNodes].forEach((node) => {
      if (node.nodeType === Node.TEXT_NODE) wrap(node)
    })
  })
}

/* Созвездие: соединяем планшеты залов линией, звёзды в узлах */
function initHallConstellation() {
  const holder = document.querySelector("[data-constellation-holder]")
  const plates = [...document.querySelectorAll("[data-constellation-holder] [data-cn]")]
  if (!holder || plates.length < 2) return
  if (holder.dataset.constellationDone) return
  holder.dataset.constellationDone = "1"

  const draw = () => {
    holder.querySelectorAll("svg").forEach((s) => s.remove())
    const rect = holder.getBoundingClientRect()
    const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg")
    svg.setAttribute("class", "constellation-svg")
    svg.setAttribute("width", rect.width)
    svg.setAttribute("height", rect.height)
    svg.setAttribute("viewBox", `0 0 ${rect.width} ${rect.height}`)

    const centers = plates.map((plate) => {
      const r = plate.getBoundingClientRect()
      return { x: r.left - rect.left + r.width / 2, y: r.top - rect.top + r.height / 2 }
    })

    centers.forEach((c, j) => {
      const dot = document.createElementNS("http://www.w3.org/2000/svg", "circle")
      dot.setAttribute("class", "cs")
      dot.setAttribute("cx", c.x)
      dot.setAttribute("cy", c.y)
      dot.setAttribute("r", 3.5)
      dot.style.setProperty("--j", j)
      svg.append(dot)
    })

    for (let i = 0; i < centers.length - 1; i++) {
      const line = document.createElementNS("http://www.w3.org/2000/svg", "line")
      line.setAttribute("class", "cl")
      line.setAttribute("pathLength", 1)
      line.setAttribute("x1", centers[i].x)
      line.setAttribute("y1", centers[i].y)
      line.setAttribute("x2", centers[i + 1].x)
      line.setAttribute("y2", centers[i + 1].y)
      svg.append(line)
    }

    holder.append(svg)
  }

  draw()
  let timer = null
  window.addEventListener("resize", () => {
    clearTimeout(timer)
    timer = setTimeout(draw, 200)
  })
}

/* Параллакс колеса: лёгкий сдвиг за скроллом */
function initWheelParallax() {
  const wheels = document.querySelectorAll(".parallax-wheel")
  if (!wheels.length) return

  const onScroll = () => {
    const y = window.scrollY
    wheels.forEach((w, i) => {
      w.style.transform = `translate3d(0, ${y * (i === 0 ? -0.06 : -0.03)}px, 0)`
    })
  }
  onScroll()
  window.addEventListener("scroll", onScroll, { passive: true })
}

document.addEventListener("turbo:load", () => {
  initReveal()
  initNav()
  initConstellation()

  // Звёзды-курсоры прячутся при навигации, пока мышь снова не двинется
  document.querySelectorAll(".cursor-star").forEach((s) => {
    s.classList.remove("is-on", "is-hover")
    s.style.transform = "translate3d(-100px, -100px, 0)"
  })

  const publicTheme = document.body.classList.contains("theme-paper") || document.body.classList.contains("design-night")

  if (publicTheme) {
    if (window.matchMedia("(pointer: fine)").matches && !reducedMotion) initStarCursor()
    if (!reducedMotion) {
      initKineticHeadline()
      initWheelParallax()
    }
    initHallConstellation()
  }
})
