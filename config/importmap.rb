# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo-rails.js"
pin "@hotwired/turbo", to: "turbo.es2017-esm.js" # @8.0.23
pin "@hotwired/stimulus", to: "stimulus.min.js" # @3.2.2
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js" # @1.3.0
pin_all_from "app/javascript/controllers", under: "controllers"
pin "chart.js" # @4.6.1 (jsDelivr +esm бандл, kurkle локально)
pin "chartkick" # @5.0.1
pin "@kurkle/color", to: "@kurkle--color.js" # @0.3.4
