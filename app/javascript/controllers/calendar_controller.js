import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tray"]

  connect() {
    this.isOpen = false
  }

  toggle(event) {
    event.stopPropagation()
    this.isOpen ? this.close() : this.open()
  }

  open() {
    this.trayTarget.style.gridTemplateRows = "1fr"
    this.trayTarget.style.opacity = "1"
    this.trayTarget.style.transform = "translateY(0)"
    this.isOpen = true
  }

  close() {
    this.trayTarget.style.gridTemplateRows = "0fr"
    this.trayTarget.style.opacity = "0"
    this.trayTarget.style.transform = "translateY(-8px)"
    this.isOpen = false
  }

  navigateToDay(event) {
    if (!this.isOpen) return

    event.preventDefault()

    const url = event.currentTarget.href
    this.close()

    setTimeout(() => {
      Turbo.visit(url)
    }, 350)
  }
}
