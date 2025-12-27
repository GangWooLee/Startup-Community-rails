import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "textarea", "charCount", "submitButton",
    "chatContainer", "step1", "step2", "loading", "loadingText",
    "questionsContainer", "analyzeButton",
    "progress1", "progress2", "progress3"
  ]

  static values = {
    questionsUrl: String,
    resultUrl: String
  }

  connect() {
    this.idea = ""
    this.answers = {}
    this.questions = []
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

  // Step 1: Submit initial idea
  async submitIdea() {
    this.idea = this.textareaTarget.value.trim()

    if (this.idea.length < 10) {
      alert("아이디어를 10자 이상 입력해주세요.")
      return
    }

    // Store idea in sessionStorage
    sessionStorage.setItem("onboarding_idea", this.idea)

    // Add user message to chat
    this.addUserMessage(this.idea)

    // Hide step 1, show loading
    this.step1Target.classList.add("hidden")
    this.loadingTarget.classList.remove("hidden")
    this.loadingTextTarget.textContent = "추가 질문 생성 중..."

    // Update progress
    this.progress2Target.classList.remove("bg-secondary")
    this.progress2Target.classList.add("bg-primary")

    try {
      // Fetch follow-up questions from server
      const response = await fetch(this.questionsUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
        },
        body: JSON.stringify({ idea: this.idea })
      })

      if (!response.ok) {
        throw new Error("Failed to fetch questions")
      }

      const data = await response.json()
      this.questions = data.questions || []

      // Add AI follow-up message
      this.addAiMessage("좀 더 정확한 분석을 위해 몇 가지 질문을 드릴게요!")

      // Render questions
      this.renderQuestions()

      // Hide loading, show step 2
      this.loadingTarget.classList.add("hidden")
      this.step2Target.classList.remove("hidden")

    } catch (error) {
      console.error("Error fetching questions:", error)
      // Fallback: go directly to analysis
      this.goToAnalysis()
    }
  }

  addUserMessage(text) {
    const messageHtml = `
      <div class="flex gap-3 justify-end">
        <div class="max-w-[80%]">
          <div class="bg-primary text-primary-foreground rounded-2xl rounded-tr-md px-4 py-3">
            <p class="text-sm">${this.escapeHtml(text)}</p>
          </div>
        </div>
      </div>
    `
    this.chatContainerTarget.insertAdjacentHTML("beforeend", messageHtml)
    this.scrollToBottom()
  }

  addAiMessage(text) {
    const messageHtml = `
      <div class="flex gap-3">
        <div class="flex-shrink-0 h-10 w-10 rounded-full bg-gradient-to-br from-primary/20 to-primary/5 flex items-center justify-center">
          <svg class="h-5 w-5 text-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/>
          </svg>
        </div>
        <div class="flex-1">
          <p class="text-sm font-medium text-foreground mb-1">AI 분석봇</p>
          <div class="bg-secondary/50 rounded-2xl rounded-tl-md px-4 py-3">
            <p class="text-sm text-foreground">${this.escapeHtml(text)}</p>
          </div>
        </div>
      </div>
    `
    this.chatContainerTarget.insertAdjacentHTML("beforeend", messageHtml)
    this.scrollToBottom()
  }

  renderQuestions() {
    const container = this.questionsContainerTarget
    container.innerHTML = ""

    this.questions.forEach((question, index) => {
      const questionHtml = `
        <div class="mb-4">
          <label class="block text-sm font-medium text-foreground mb-2">
            ${this.escapeHtml(question.question)}
            ${question.required ? '<span class="text-destructive">*</span>' : '<span class="text-muted-foreground text-xs">(선택)</span>'}
          </label>
          <input
            type="text"
            data-question-id="${question.id}"
            data-required="${question.required}"
            placeholder="${this.escapeHtml(question.placeholder || '')}"
            class="w-full px-4 py-3 rounded-lg bg-secondary border-0 text-foreground placeholder:text-muted-foreground focus:ring-2 focus:ring-primary/20 focus:outline-none"
            data-action="input->ai-input#updateAnswers"
          />
        </div>
      `
      container.insertAdjacentHTML("beforeend", questionHtml)
    })
  }

  updateAnswers() {
    const inputs = this.questionsContainerTarget.querySelectorAll("input[data-question-id]")
    let allRequiredFilled = true

    inputs.forEach(input => {
      const id = input.dataset.questionId
      const value = input.value.trim()
      const required = input.dataset.required === "true"

      this.answers[id] = value

      if (required && !value) {
        allRequiredFilled = false
      }
    })

    // Enable/disable analyze button
    this.analyzeButtonTarget.disabled = !allRequiredFilled
  }

  // Step 2: Submit for analysis
  submitForAnalysis() {
    // Update progress
    this.progress3Target.classList.remove("bg-secondary")
    this.progress3Target.classList.add("bg-primary")

    // Build URL with query params
    const url = new URL(this.resultUrlValue, window.location.origin)
    url.searchParams.set("idea", this.idea)
    url.searchParams.set("answers", JSON.stringify(this.answers))

    // Navigate to result page
    window.location.href = url.toString()
  }

  goToAnalysis() {
    const url = new URL(this.resultUrlValue, window.location.origin)
    url.searchParams.set("idea", this.idea)
    window.location.href = url.toString()
  }

  scrollToBottom() {
    setTimeout(() => {
      this.chatContainerTarget.scrollIntoView({ behavior: "smooth", block: "end" })
    }, 100)
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
