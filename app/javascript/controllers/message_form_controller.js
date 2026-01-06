import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "button"]

  connect() {
    this.autoResize()
  }

  // Enter로 전송, Shift+Enter로 줄바꿈
  handleKeydown(event) {
    // 한글 IME 조합 중이면 무시 (중복 전송 방지)
    if (event.isComposing) return

    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      if (this.hasInputTarget && this.inputTarget.value.trim() !== "") {
        this.element.requestSubmit()
      }
    }
  }

  submit(event) {
    // 직접 호출 시 전송
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
