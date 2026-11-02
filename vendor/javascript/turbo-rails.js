// Обёртка @hotwired/turbo-rails: стартуем Turbo (аналог гемовской turbo.min.js)
import * as Turbo from "@hotwired/turbo"

Turbo.start()
window.Turbo = Turbo

export default Turbo
