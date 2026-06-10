import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    Turbo.config.forms.confirm = this.show.bind(this)
    Turbo.config.drive.confirm = this.show.bind(this)
  }

  disconnect() {
    Turbo.config.forms.confirm = (message) => Promise.resolve(window.confirm(message))
    Turbo.config.drive.confirm = (message) => Promise.resolve(window.confirm(message))
  }

  show(message) {
    return new Promise((resolve) => {
      const dialog    = document.getElementById("turbo-confirm-dialog")
      const messageEl = document.getElementById("turbo-confirm-message")
      const okBtn     = document.getElementById("turbo-confirm-ok")
      const cancelBtn = document.getElementById("turbo-confirm-cancel")

      messageEl.textContent = message
      dialog.showModal()

      const cleanup = (result) => {
        dialog.close()
        resolve(result)
      }

      okBtn.addEventListener("click",     () => cleanup(true),  { once: true })
      cancelBtn.addEventListener("click", () => cleanup(false), { once: true })
      dialog.addEventListener("cancel",   () => cleanup(false), { once: true })
    })
  }
}
