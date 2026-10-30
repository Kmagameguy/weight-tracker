import { Controller } from "@hotwired/stimulus"

// Workaround for inline onclick handlers being blocked by CSP
export default class extends Controller {
  print() {
    window.print()
  }
}
