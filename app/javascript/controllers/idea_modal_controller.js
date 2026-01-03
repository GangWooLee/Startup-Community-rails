import { Controller } from "@hotwired/stimulus"

/**
 * IdeaModalController - 온보딩 랜딩 페이지 아이디어 입력 모달
 *
 * 기능:
 * - 모달 열기/닫기 (애니메이션 포함)
 * - textarea 입력 검증 (10-500자)
 * - 기존 AI 분석 플로우로 폼 제출
 */
export default class extends Controller {
  static targets = [
    "modal",
    "backdrop",
    "content",
    "ideaInput",
    "charCount",
    "submitButton",
    "buttonText",
    "buttonIcon",
    "loadingSpinner"
  ]

  static values = {
    analyzeUrl: String,
    csrfToken: String,
    minChars: { type: Number, default: 10 },
    maxChars: { type: Number, default: 500 }
  }

  connect() {
    this.isOpen = false
    this.idea = ""
  }

  /**
   * 모달 열기
   * Reference: scale 0.98 → 1, opacity 0 → 1, duration 0.2s
   */
  open(event) {
    if (event) event.preventDefault()
    this.isOpen = true

    // Show modal container
    this.modalTarget.classList.remove("hidden")

    // Trigger animations (scale-[0.98] → scale-100)
    requestAnimationFrame(() => {
      this.backdropTarget.classList.remove("opacity-0")
      this.contentTarget.classList.remove("opacity-0", "scale-[0.98]")
      this.contentTarget.classList.add("opacity-100", "scale-100")
    })

    // Prevent body scroll
    document.body.style.overflow = "hidden"

    // Focus textarea after animation
    setTimeout(() => {
      if (this.hasIdeaInputTarget) {
        this.ideaInputTarget.focus()
      }
    }, 200)
  }

  /**
   * 모달 닫기 (애니메이션 포함)
   * Reference: scale 1 → 0.98, opacity 1 → 0, duration 0.2s
   */
  close(event) {
    if (event) event.preventDefault()
    this.isOpen = false

    // Fade out animation (scale-100 → scale-[0.98])
    this.backdropTarget.classList.add("opacity-0")
    this.contentTarget.classList.remove("opacity-100", "scale-100")
    this.contentTarget.classList.add("opacity-0", "scale-[0.98]")

    // Hide after animation
    setTimeout(() => {
      this.modalTarget.classList.add("hidden")
      document.body.style.overflow = ""
      this.reset()
    }, 200)
  }

  /**
   * 배경 클릭 시 닫기
   */
  backdropClick(event) {
    if (event.target === this.backdropTarget) {
      this.close()
    }
  }

  /**
   * textarea 입력 업데이트
   */
  updateInput() {
    const value = this.ideaInputTarget.value
    const length = value.length

    this.idea = value.trim()
    this.charCountTarget.textContent = length

    // Update character count color
    if (length > this.maxCharsValue) {
      this.charCountTarget.classList.add("text-red-500")
    } else {
      this.charCountTarget.classList.remove("text-red-500")
    }

    // Enable/disable submit button
    const isValid = this.idea.length >= this.minCharsValue && length <= this.maxCharsValue
    this.submitButtonTarget.disabled = !isValid

    if (isValid) {
      this.submitButtonTarget.classList.remove("opacity-40", "cursor-not-allowed")
    } else {
      this.submitButtonTarget.classList.add("opacity-40", "cursor-not-allowed")
    }
  }

  /**
   * 폼 제출 - 기존 AI 분석 플로우로 연결
   */
  submit(event) {
    event.preventDefault()

    if (!this.idea || this.idea.length < this.minCharsValue) {
      return
    }

    // Store idea in sessionStorage for potential recovery
    sessionStorage.setItem("onboarding_idea", this.idea)

    // Show loading state on button (using targets, not innerHTML)
    this.submitButtonTarget.disabled = true
    if (this.hasButtonTextTarget) {
      this.buttonTextTarget.textContent = "분석 준비 중..."
    }
    if (this.hasButtonIconTarget) {
      this.buttonIconTarget.classList.add("hidden")
    }
    if (this.hasLoadingSpinnerTarget) {
      this.loadingSpinnerTarget.classList.remove("hidden")
    }

    // Submit via hidden form (preserves CSRF and proper redirect)
    this.submitViaForm()
  }

  /**
   * 동적 폼 생성 및 제출
   */
  submitViaForm() {
    const form = document.createElement("form")
    form.method = "POST"
    form.action = this.analyzeUrlValue
    form.style.display = "none"

    // CSRF token
    const csrfInput = document.createElement("input")
    csrfInput.type = "hidden"
    csrfInput.name = "authenticity_token"
    csrfInput.value = this.csrfTokenValue
    form.appendChild(csrfInput)

    // Idea
    const ideaInput = document.createElement("input")
    ideaInput.type = "hidden"
    ideaInput.name = "idea"
    ideaInput.value = this.idea
    form.appendChild(ideaInput)

    // Empty answers (skip follow-up questions for direct submission)
    const answersInput = document.createElement("input")
    answersInput.type = "hidden"
    answersInput.name = "answers"
    answersInput.value = "{}"
    form.appendChild(answersInput)

    document.body.appendChild(form)
    form.submit()
  }

  /**
   * 모달 상태 리셋
   */
  reset() {
    if (this.hasIdeaInputTarget) {
      this.ideaInputTarget.value = ""
    }
    if (this.hasCharCountTarget) {
      this.charCountTarget.textContent = "0"
      this.charCountTarget.classList.remove("text-red-500")
    }
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = true
      this.submitButtonTarget.classList.add("opacity-40", "cursor-not-allowed")
    }
    if (this.hasButtonTextTarget) {
      this.buttonTextTarget.textContent = "아이디어 스케치 시작하기"
    }
    if (this.hasButtonIconTarget) {
      this.buttonIconTarget.classList.remove("hidden")
    }
    if (this.hasLoadingSpinnerTarget) {
      this.loadingSpinnerTarget.classList.add("hidden")
    }
    this.idea = ""
  }

  /**
   * ESC 키로 닫기
   */
  keydown(event) {
    if (event.key === "Escape" && this.isOpen) {
      this.close()
    }
  }
}
