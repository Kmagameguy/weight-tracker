import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="food-entry-typeahead"
export default class extends Controller {
  static targets = ["name", "calories", "results"]
  static values  = { url: String }

  connect() {
    this.debounceTimeout = null
  }

  search() {
    clearTimeout(this.debounceTimeout)
    const query = this.nameTarget.value.trim()

    if (query.length < 2) {
      this.clearResults()
      return
    }

    this.debounceTimeout = setTimeout(() => this.fetchResults(query), 200)
  }

  async fetchResults(query) {
    const response = await fetch(`${this.urlValue}?query=${encodeURIComponent(query)}`, {
      headers: { Accept: "text/html" }
    })

    if (response.ok) {
      this.resultsTarget.innerHTML = await response.text()
    }
  }

  select(event) {
    this.nameTarget.value = event.currentTarget.dataset.name
    this.caloriesTarget.value = event.currentTarget.dataset.calories
    this.clearResults()
  }

  blurClear() {
    setTimeout(() => this.clearResults(), 150)
  }

  clearResults() {
    this.resultsTarget.innerHTML = ""
  }
}
