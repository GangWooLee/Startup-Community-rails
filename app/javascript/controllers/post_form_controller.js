import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["category", "outsourcingFields", "seekingFields", "title", "content", "serviceType"]

  connect() {
    this.prefillFromOnboarding()
    this.toggleCategoryFields()
    this.validateForm()
  }

  prefillFromOnboarding() {
    // sessionStorage에 저장된 아이디어가 있으면 자동으로 채움
    // (로그인 후 리디렉션된 경우에도 작동)
    const savedIdea = sessionStorage.getItem('onboarding_idea')

    if (savedIdea && this.hasContentTarget) {
      this.contentTarget.value = savedIdea
      // 사용 후 삭제
      sessionStorage.removeItem('onboarding_idea')
      // 유효성 검사 트리거
      this.validateForm()
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

  toggleCategoryFields() {
    const selectedCategory = this.categoryTargets.find(input => input.checked)?.value
    const isSeeking = selectedCategory === 'seeking'

    // 구직 전용 필드 토글
    if (this.hasSeekingFieldsTarget) {
      if (isSeeking) {
        this.seekingFieldsTarget.classList.remove('hidden')
      } else {
        this.seekingFieldsTarget.classList.add('hidden')
      }
    }

    this.validateForm()
  }

  validateForm() {
    const submitButton = document.getElementById('submit-button')
    if (!submitButton) return

    const title = this.hasTitleTarget ? this.titleTarget.value.trim() : ''
    const content = this.hasContentTarget ? this.contentTarget.value.trim() : ''

    // 카테고리 확인: radio button 또는 hidden field
    let categorySelected = false
    let selectedCategory = null

    // radio button으로 선택된 경우
    if (this.categoryTargets.length > 0) {
      categorySelected = this.categoryTargets.some(input => input.checked)
      selectedCategory = this.categoryTargets.find(input => input.checked)?.value
    } else {
      // hidden field로 설정된 경우 (폼 내 hidden input 확인)
      const hiddenCategory = this.element.querySelector('input[name="post[category]"][type="hidden"]')
      if (hiddenCategory && hiddenCategory.value) {
        categorySelected = true
        selectedCategory = hiddenCategory.value
      }
    }

    // 기본 유효성 검사
    let isValid = title.length > 0 && content.length > 0 && categorySelected

    // 외주 글인 경우 추가 검증
    const isOutsourcing = selectedCategory === 'hiring' || selectedCategory === 'seeking'

    if (isOutsourcing && this.hasServiceTypeTarget) {
      const serviceType = this.serviceTypeTarget.value
      isValid = isValid && serviceType !== ''
    }

    submitButton.disabled = !isValid
  }
}
