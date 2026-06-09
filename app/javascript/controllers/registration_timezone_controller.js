import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="registration-timezone"
export default class extends Controller {
  connect() {
    const tz = Intl.DateTimeFormat().resolvedOptions().timeZone

    if (tz && this.element) {
      this.element.value = tz
    }
  }
}
