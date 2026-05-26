import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "form"];

  edit() {
    this.displayTarget.classList.add("hidden");
    this.formTarget.classList.remove("hidden");
  }
}
