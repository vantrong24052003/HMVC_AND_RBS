import { Application } from "@hotwired/stimulus"
import Rails from "@rails/ujs"
import "@hotwired/turbo-rails"

Rails.start()

const application = Application.start()

application.debug = false
window.Stimulus = application

// Turbo Drive demo hooks
window.TurboDemo = {
  visit(url, options = {}) {
    const action = options.action || "advance"
    if (window.Turbo && typeof window.Turbo.visit === "function") {
      console.log("[TurboDemo] Visiting:", { url, action })
      window.Turbo.visit(url, { action })
    } else {
      console.warn("[TurboDemo] Turbo not available; falling back to window.location")
      window.location.href = url
    }
  }
}

document.addEventListener("turbo:before-visit", (event) => {
  console.log("[TurboDemo] before-visit", { url: event.detail.url })
})

document.addEventListener("turbo:load", () => {
  console.log("[TurboDemo] load", { title: document.title, path: window.location.pathname })
})

document.addEventListener("turbo:before-cache", () => {
  console.log("[TurboDemo] before-cache", { path: window.location.pathname })
})

export { application }
