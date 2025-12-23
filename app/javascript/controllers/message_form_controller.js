import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "button"]

  connect() {
    this.autoResize()
  }

  submit(event) {
    // Ctrl+Enter 또는 Cmd+Enter로 전송
    if (this.hasInputTarget && this.inputTarget.value.trim() !== "") {
      event.preventDefault()
      this.element.requestSubmit()
    }
  }

  reset() {
    if (this.hasInputTarget) {
      this.inputTarget.value = ""
      this.inputTarget.style.height = "auto"
      this.inputTarget.focus()
    }
  }

  autoResize() {
    if (this.hasInputTarget) {
      const input = this.inputTarget
      input.style.height = "auto"
      input.style.height = Math.min(input.scrollHeight, 128) + "px"
    }
  }
}
