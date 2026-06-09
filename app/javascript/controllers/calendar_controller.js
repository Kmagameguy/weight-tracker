import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["popover"]

  connect() {
    this.handleOutsideClick = this.handleOutsideClick.bind(this)
    this.popoverTarget.style.display = "none"
  }

  toggle(event) {
    event.stopPropagation()
    const popover = this.popoverTarget
    if (popover.style.display === "none") {
      popover.style.display = "block"
      document.addEventListener("click", this.handleOutsideClick)
    } else {
      this.close()
    }
  }

  close() {
    this.popoverTarget.style.display = "none"
    document.removeEventListener("click", this.handleOutsideClick)
  }

  handleOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  disconnect() {
    document.removeEventListener("click", this.handleOutsideClick)
  }
}
