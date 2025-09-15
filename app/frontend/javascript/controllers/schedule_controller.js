import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["interval", "weekdayRow", "dayRow", "weekday", "day", "hour", "minute"]

  connect() {
    this.updateVisibility()
  }

  change() {
    this.updateVisibility()
  }

  updateVisibility() {
    const iv = this.intervalTarget.value
    const showWeekday = iv === "weekly"
    const showDay = iv === "monthly"

    this.weekdayRowTarget.classList.toggle("hidden", !showWeekday)
    this.dayRowTarget.classList.toggle("hidden", !showDay)

    this.weekdayTarget.required = showWeekday
    this.dayTarget.required = showDay

    this.hourTarget.required = true
    this.minuteTarget.required = true

    if (!showWeekday) this.weekdayTarget.value = ""
    if (!showDay) this.dayTarget.value = ""
  }
}
