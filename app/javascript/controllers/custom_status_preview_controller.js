import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview", "badge"]

  connect() {
    this.update()
  }

  update() {
    const value = this.inputTarget.value.trim()

    if (value) {
      this.badgeTarget.textContent = value
      this.previewTarget.classList.remove("hidden")
    } else {
      this.previewTarget.classList.add("hidden")
    }
  }
}
