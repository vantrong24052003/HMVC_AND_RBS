import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["startedAt", "limit", "unit"]

  startNow() {
    const d = new Date()
    d.setSeconds(0, 0)
    const pad = n => ("0" + n).slice(-2)
    const value = `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`
    if (this.hasStartedAtTarget) this.startedAtTarget.value = value
  }

  normalize() {
    if (!this.hasLimitTarget || !this.hasUnitTarget) return
    const raw = parseInt(this.limitTarget.value, 10)
    if (isNaN(raw)) return
    if (this.unitTarget.value === "hours") {
      this.limitTarget.value = String(raw * 60)
    }
  }
}
