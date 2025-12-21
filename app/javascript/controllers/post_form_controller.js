import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["category", "outsourcingFields", "title", "content", "serviceType"]

  connect() {
    this.prefillFromOnboarding()
    this.validateForm()
  }

  prefillFromOnboarding() {
    // Check if we should prefill from onboarding
    const urlParams = new URLSearchParams(window.location.search)
    const shouldPrefill = urlParams.get('prefill') === 'idea'

    if (shouldPrefill && this.hasContentTarget) {
      const savedIdea = sessionStorage.getItem('onboarding_idea')
      if (savedIdea) {
        this.contentTarget.value = savedIdea
        // Clear after use
        sessionStorage.removeItem('onboarding_idea')
        // Trigger validation
        this.validateForm()
      }
    }
  }

  toggleOutsourcingFields() {
    const selectedCategory = this.categoryTargets.find(input => input.checked)?.value
    const isOutsourcing = selectedCategory === 'hiring' || selectedCategory === 'seeking'

    if (this.hasOutsourcingFieldsTarget) {
      if (isOutsourcing) {
        this.outsourcingFieldsTarget.classList.remove('hidden')
      } else {
        this.outsourcingFieldsTarget.classList.add('hidden')
      }
    }

    this.validateForm()
  }

  validateForm() {
    const submitButton = document.getElementById('submit-button')
    if (!submitButton) return

    const title = this.hasTitleTarget ? this.titleTarget.value.trim() : ''
    const content = this.hasContentTarget ? this.contentTarget.value.trim() : ''
    const categorySelected = this.categoryTargets.some(input => input.checked)

    // 기본 유효성 검사
    let isValid = title.length > 0 && content.length > 0 && categorySelected

    // 외주 글인 경우 추가 검증
    const selectedCategory = this.categoryTargets.find(input => input.checked)?.value
    const isOutsourcing = selectedCategory === 'hiring' || selectedCategory === 'seeking'

    if (isOutsourcing && this.hasServiceTypeTarget) {
      const serviceType = this.serviceTypeTarget.value
      isValid = isValid && serviceType !== ''
    }

    submitButton.disabled = !isValid
  }
}
