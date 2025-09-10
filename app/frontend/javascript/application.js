import { Application } from "@hotwired/stimulus"
import Rails from "@rails/ujs"
import "@hotwired/turbo-rails"

Rails.start()

const application = Application.start()

application.debug = false
window.Stimulus = application

export { application }
