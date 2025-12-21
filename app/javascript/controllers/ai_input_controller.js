import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["textarea", "charCount", "submitButton"]

  connect() {
    this.updateCharCount()
  }

  updateCharCount() {
    const length = this.textareaTarget.value.length
    this.charCountTarget.textContent = length

    // Enable/disable submit button based on content
    if (length >= 10 && length <= 500) {
      this.submitButtonTarget.disabled = false
    } else {
      this.submitButtonTarget.disabled = true
    }
  }

  fillExample(event) {
    const example = event.currentTarget.dataset.example
    this.textareaTarget.value = example
    this.updateCharCount()
    this.textareaTarget.focus()
  }

  handleSubmit(event) {
    const idea = this.textareaTarget.value.trim()

    if (idea.length < 10) {
      event.preventDefault()
      alert("아이디어를 10자 이상 입력해주세요.")
      return
    }

    // Store idea in sessionStorage for later use (post creation pre-fill)
    sessionStorage.setItem("onboarding_idea", idea)
  }
}
