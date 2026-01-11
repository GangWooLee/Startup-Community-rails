import { Controller } from "@hotwired/stimulus"

/**
 * IdeaModalController - 온보딩 랜딩 페이지 아이디어 입력 모달
 *
 * 기능:
 * - 모달 열기/닫기 (애니메이션 포함)
 * - textarea 입력 검증 (10-500자)
 * - 2단계 플로우: 아이디어 입력 → 추가질문 → AI 분석
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
    "loadingSpinner",
    // Step 2 targets
    "step1",
    "step2",
    "questionsContainer",
    "step2SubmitButton",
    "step2LoadingSpinner",
    "step2ButtonText"
  ]

  static values = {
    analyzeUrl: String,
    questionsUrl: String,
    csrfToken: String,
    minChars: { type: Number, default: 10 },
    maxChars: { type: Number, default: 500 }
  }

  connect() {
    this.isOpen = false
    this.idea = ""
    this.questions = []
    this.currentStep = 1
    this.isSubmitting = false // 중복 클릭 방지 플래그
  }

  /**
   * 모달 열기
   */
  open(event) {
    if (event) event.preventDefault()
    this.isOpen = true

    // Show modal container
    this.modalTarget.classList.remove("hidden")

    // Trigger animations
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
   */
  close(event) {
    if (event) event.preventDefault()
    this.isOpen = false

    // Fade out animation
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
   * Step 1: 아이디어 제출 → 추가질문 가져오기
   */
  async submit(event) {
    event.preventDefault()

    // 중복 클릭 방지
    if (this.isSubmitting) return

    if (!this.idea || this.idea.length < this.minCharsValue) {
      return
    }

    this.isSubmitting = true

    // Store idea in sessionStorage for recovery
    sessionStorage.setItem("onboarding_idea", this.idea)

    // Show loading state
    this.setStep1Loading(true)

    try {
      // Fetch follow-up questions
      const response = await fetch(this.questionsUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfTokenValue
        },
        body: JSON.stringify({ idea: this.idea })
      })

      if (!response.ok) {
        throw new Error("질문을 가져오는데 실패했습니다")
      }

      const data = await response.json()
      this.questions = data.questions || []

      // 질문이 없으면 바로 제출 (Step 2 건너뛰기)
      if (this.questions.length === 0) {
        this.submitViaForm()
        return
      }

      // Render questions and switch to Step 2
      this.renderQuestions()
      this.showStep2()
      this.isSubmitting = false // Step 2에서 다시 제출 가능하도록
    } catch (error) {
      console.error("Error fetching questions:", error)
      // Fallback: proceed without questions (legacy flow)
      this.submitViaForm()
    }
  }

  /**
   * 질문 UI 렌더링 (DOM API 사용 - XSS 방지)
   * Phase 14: 태그 입력 시스템 추가 (ai_input_controller.js와 동일)
   */
  renderQuestions() {
    const container = this.questionsContainerTarget
    // Clear existing content safely
    while (container.firstChild) {
      container.removeChild(container.firstChild)
    }

    this.questions.forEach((q) => {
      // Create question wrapper
      const questionDiv = document.createElement("div")
      questionDiv.className = "mb-6"

      // Create header row
      const headerRow = document.createElement("div")
      headerRow.className = "flex items-start gap-3 mb-3"

      // Create icon container
      const iconContainer = document.createElement("div")
      iconContainer.className = "flex-shrink-0 w-8 h-8 rounded-full bg-[#2C4A6B]/10 flex items-center justify-center"

      // Create SVG icon
      const svgNS = "http://www.w3.org/2000/svg"
      const svg = document.createElementNS(svgNS, "svg")
      svg.setAttribute("class", "w-4 h-4 text-[#2C4A6B]")
      svg.setAttribute("fill", "none")
      svg.setAttribute("stroke", "currentColor")
      svg.setAttribute("viewBox", "0 0 24 24")

      const path = document.createElementNS(svgNS, "path")
      path.setAttribute("stroke-linecap", "round")
      path.setAttribute("stroke-linejoin", "round")
      path.setAttribute("stroke-width", "2")
      path.setAttribute("d", "M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z")
      svg.appendChild(path)
      iconContainer.appendChild(svg)

      // Create question text container with required/optional indicator
      const textContainer = document.createElement("div")
      textContainer.className = "flex-1"

      const questionText = document.createElement("p")
      questionText.className = "text-[#2C4A6B] font-medium text-sm leading-relaxed"
      questionText.textContent = q.question // Safe: textContent escapes HTML

      // Add required/optional indicator inline
      if (q.required) {
        const asterisk = document.createElement("span")
        asterisk.className = "text-red-400 ml-1"
        asterisk.textContent = "*"
        asterisk.setAttribute("aria-label", "필수 입력")
        questionText.appendChild(asterisk)
      } else {
        const optionalBadge = document.createElement("span")
        optionalBadge.className = "text-[#2C4A6B]/50 text-xs ml-2"
        optionalBadge.textContent = "(선택)"
        questionText.appendChild(optionalBadge)
      }

      textContainer.appendChild(questionText)
      headerRow.appendChild(iconContainer)
      headerRow.appendChild(textContainer)

      // Create tag input container (tags + text input in one area)
      const tagInputContainer = document.createElement("div")
      tagInputContainer.className = "tag-input-container"
      tagInputContainer.dataset.questionId = q.id

      // Create text input that grows to fill space
      const input = document.createElement("input")
      input.type = "text"
      input.dataset.questionId = q.id
      input.dataset.required = q.required
      input.placeholder = q.placeholder || "답변을 입력해주세요..."
      input.className = "tag-input-field"

      tagInputContainer.appendChild(input)

      questionDiv.appendChild(headerRow)
      questionDiv.appendChild(tagInputContainer)

      // Add example buttons if examples exist
      if (q.examples && q.examples.length > 0) {
        const examplesContainer = document.createElement("div")
        examplesContainer.className = "flex flex-wrap items-center gap-2 mt-3"
        examplesContainer.dataset.examplesForQuestion = q.id

        // "예시" label
        const label = document.createElement("span")
        label.className = "text-xs text-[#2C4A6B]/60 mr-1"
        label.textContent = "예시"
        examplesContainer.appendChild(label)

        // Example buttons
        q.examples.forEach(example => {
          const btn = document.createElement("button")
          btn.type = "button"
          btn.className = "example-chip"
          btn.textContent = example
          btn.dataset.questionId = q.id
          btn.dataset.example = example
          btn.addEventListener("click", (e) => this.selectExample(e.target))
          examplesContainer.appendChild(btn)
        })

        questionDiv.appendChild(examplesContainer)
      }

      container.appendChild(questionDiv)
    })
  }

  // ========== Tag Input System (Phase 14) ==========

  /**
   * Select an example and move it as a tag into the input container
   * @param {HTMLElement} btn - The clicked example button
   */
  selectExample(btn) {
    const questionId = btn.dataset.questionId
    const example = btn.dataset.example

    // Hide the example button
    btn.style.display = "none"

    // Find the tag input container for this question
    const tagInputContainer = this.questionsContainerTarget.querySelector(
      `.tag-input-container[data-question-id="${questionId}"]`
    )
    if (!tagInputContainer) return

    // Create and insert tag before the text input
    const tag = this.createTag(example, questionId)
    const input = tagInputContainer.querySelector("input")
    tagInputContainer.insertBefore(tag, input)
  }

  /**
   * Remove a tag and restore the example button
   * @param {HTMLElement} tag - The tag element to remove
   */
  removeTag(tag) {
    const questionId = tag.dataset.questionId
    const example = tag.dataset.example

    // Remove the tag
    tag.remove()

    // Find and show the original example button
    const examplesContainer = this.questionsContainerTarget.querySelector(
      `[data-examples-for-question="${questionId}"]`
    )
    if (examplesContainer) {
      const btn = examplesContainer.querySelector(
        `.example-chip[data-example="${CSS.escape(example)}"]`
      )
      if (btn) {
        btn.style.display = ""
      }
    }
  }

  /**
   * Create a tag element with remove button
   * @param {string} text - The tag text
   * @param {string} questionId - The question ID this tag belongs to
   * @returns {HTMLElement} The tag element
   */
  createTag(text, questionId) {
    const tag = document.createElement("span")
    tag.className = "selected-tag"
    tag.dataset.questionId = questionId
    tag.dataset.example = text

    // Text node (using textContent for XSS safety)
    const textNode = document.createTextNode(text)
    tag.appendChild(textNode)

    // Remove button (×)
    const removeBtn = document.createElement("button")
    removeBtn.type = "button"
    removeBtn.className = "tag-remove-btn"
    removeBtn.textContent = "×"
    removeBtn.setAttribute("aria-label", `${text} 제거`)
    removeBtn.addEventListener("click", (e) => {
      e.stopPropagation()
      this.removeTag(tag)
    })

    tag.appendChild(removeBtn)
    return tag
  }

  /**
   * Step 2 표시
   */
  showStep2() {
    this.currentStep = 2
    this.setStep1Loading(false)

    // Hide Step 1, show Step 2
    if (this.hasStep1Target) {
      this.step1Target.classList.add("hidden")
    }
    if (this.hasStep2Target) {
      this.step2Target.classList.remove("hidden")
    }
  }

  /**
   * Step 1으로 돌아가기
   */
  goBack(event) {
    if (event) event.preventDefault()
    this.currentStep = 1

    // Show Step 1, hide Step 2
    if (this.hasStep1Target) {
      this.step1Target.classList.remove("hidden")
    }
    if (this.hasStep2Target) {
      this.step2Target.classList.add("hidden")
    }

    // Focus textarea
    setTimeout(() => {
      if (this.hasIdeaInputTarget) {
        this.ideaInputTarget.focus()
      }
    }, 100)
  }

  /**
   * Step 2: 답변과 함께 최종 제출
   */
  submitWithAnswers(event) {
    if (event) event.preventDefault()

    // 중복 클릭 방지
    if (this.isSubmitting) return
    this.isSubmitting = true

    // Collect answers (tags + text input)
    const answers = {}
    const inputs = this.questionsContainerTarget.querySelectorAll("input[data-question-id]")

    inputs.forEach(input => {
      const questionId = input.dataset.questionId

      // 선택된 태그 수집
      const tagInputContainer = input.closest(".tag-input-container")
      const selectedTags = tagInputContainer
        ? Array.from(tagInputContainer.querySelectorAll(".selected-tag"))
            .map(tag => tag.dataset.example)
        : []

      // 텍스트 입력 수집
      const textValue = input.value.trim()

      // 태그 + 텍스트 결합
      const allValues = [...selectedTags]
      if (textValue) allValues.push(textValue)

      answers[questionId] = allValues.join(", ")
    })

    // Store in sessionStorage
    sessionStorage.setItem("onboarding_idea", this.idea)
    sessionStorage.setItem("onboarding_answers", JSON.stringify(answers))

    // Show loading state
    this.setStep2Loading(true)

    // Submit via form
    this.submitViaFormWithAnswers(answers)
  }

  /**
   * 답변 포함 폼 제출
   */
  submitViaFormWithAnswers(answers) {
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

    // Answers
    const answersInput = document.createElement("input")
    answersInput.type = "hidden"
    answersInput.name = "answers"
    answersInput.value = JSON.stringify(answers)
    form.appendChild(answersInput)

    document.body.appendChild(form)
    form.submit()
  }

  /**
   * 레거시: 질문 없이 직접 제출 (fallback)
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

    // Empty answers
    const answersInput = document.createElement("input")
    answersInput.type = "hidden"
    answersInput.name = "answers"
    answersInput.value = "{}"
    form.appendChild(answersInput)

    document.body.appendChild(form)
    form.submit()
  }

  /**
   * Step 1 로딩 상태 설정
   */
  setStep1Loading(isLoading) {
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = isLoading
    }
    if (this.hasButtonTextTarget) {
      this.buttonTextTarget.textContent = isLoading ? "질문 준비 중..." : "다음"
    }
    if (this.hasButtonIconTarget) {
      this.buttonIconTarget.classList.toggle("hidden", isLoading)
    }
    if (this.hasLoadingSpinnerTarget) {
      this.loadingSpinnerTarget.classList.toggle("hidden", !isLoading)
    }
  }

  /**
   * Step 2 로딩 상태 설정
   */
  setStep2Loading(isLoading) {
    if (this.hasStep2SubmitButtonTarget) {
      this.step2SubmitButtonTarget.disabled = isLoading
    }
    if (this.hasStep2ButtonTextTarget) {
      this.step2ButtonTextTarget.textContent = isLoading ? "분석 준비 중..." : "분석 시작하기"
    }
    if (this.hasStep2LoadingSpinnerTarget) {
      this.step2LoadingSpinnerTarget.classList.toggle("hidden", !isLoading)
    }
  }

  /**
   * 모달 상태 리셋
   */
  reset() {
    // Reset Step 1
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
      this.buttonTextTarget.textContent = "다음"
    }
    if (this.hasButtonIconTarget) {
      this.buttonIconTarget.classList.remove("hidden")
    }
    if (this.hasLoadingSpinnerTarget) {
      this.loadingSpinnerTarget.classList.add("hidden")
    }

    // Reset Step 2
    if (this.hasQuestionsContainerTarget) {
      const container = this.questionsContainerTarget
      while (container.firstChild) {
        container.removeChild(container.firstChild)
      }
    }
    if (this.hasStep2SubmitButtonTarget) {
      this.step2SubmitButtonTarget.disabled = false
    }
    if (this.hasStep2ButtonTextTarget) {
      this.step2ButtonTextTarget.textContent = "분석 시작하기"
    }
    if (this.hasStep2LoadingSpinnerTarget) {
      this.step2LoadingSpinnerTarget.classList.add("hidden")
    }

    // Show Step 1, hide Step 2
    if (this.hasStep1Target) {
      this.step1Target.classList.remove("hidden")
    }
    if (this.hasStep2Target) {
      this.step2Target.classList.add("hidden")
    }

    this.idea = ""
    this.questions = []
    this.currentStep = 1
    this.isSubmitting = false
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
