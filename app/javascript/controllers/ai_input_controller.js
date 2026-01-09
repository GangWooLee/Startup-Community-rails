import { Controller } from "@hotwired/stimulus"
import { delay } from "controllers/mixins/animation_helpers"

/**
 * AI Input Controller - "Premium macOS Native App"
 * Phase 10: 초정밀 macOS 네이티브 앱 수준 리디자인
 *
 * Design Goals:
 * - "실제 macOS 네이티브 앱을 웹으로 옮겨온 듯한 퀄리티"
 * - 픽셀 하나, 그림자 농도(Opacity) 하나까지 정확하게 구현
 * - 웹사이트 느낌 제거 → "나만의 아이디어 노트 앱" 몰입감
 *
 * Key Changes from Phase 9:
 * - Window: 65% opacity, blur(40px), rounded-[2rem]
 * - Typography: text-3xl ~ text-4xl for greeting
 * - Send Button: 48px, #2C2825 (Charcoal Brown)
 * - Progress: #2C2825 instead of #007aff
 * - Premium animations: fade-in-up, scale-down-fade, slide-in-up
 */
export default class extends Controller {
  static targets = [
    // Core inputs
    "textarea", "charCount", "submitButton",
    // Steps
    "step1", "step2", "loading", "loadingText",
    // Questions
    "questionsContainer", "analyzeButton",
    // Progress indicators
    "progress1", "progress2", "progress3", "progressContainer",
    // Phase 8/9 targets
    "previousAnswer", "previousAnswerText", "aiThinking",
    // Phase 9: macOS Window targets
    "chatArea", "inputArea",
    // Legacy (kept for compatibility)
    "chatContainer"
  ]

  static values = {
    questionsUrl: String,
    analyzeUrl: String,
    csrfToken: String
  }

  connect() {
    this.idea = ""
    this.answers = {}
    this.questions = []
    this.updateCharCount()

    // Auto-resize textarea on connect
    if (this.hasTextareaTarget) {
      this.autoResize({ target: this.textareaTarget })
    }
  }

  // ========== Character Count & Validation ==========

  updateCharCount() {
    const length = this.textareaTarget.value.length
    this.charCountTarget.textContent = length

    // Enable/disable submit button based on content (10-500 chars)
    this.submitButtonTarget.disabled = !(length >= 10 && length <= 500)
  }

  // ========== Auto-resize Textarea ==========

  autoResize(event) {
    const textarea = event.target
    // Reset height to auto to get correct scrollHeight
    textarea.style.height = "auto"
    // Set to scrollHeight for content-based sizing
    textarea.style.height = `${textarea.scrollHeight}px`
  }

  // ========== Keyboard Handling ==========

  handleKeydown(event) {
    // Cmd/Ctrl + Enter to submit (when valid)
    if ((event.metaKey || event.ctrlKey) && event.key === "Enter") {
      event.preventDefault()
      if (!this.submitButtonTarget.disabled) {
        this.submitIdea()
      }
    }
  }

  // ========== Example Fill ==========

  fillExample(event) {
    const example = event.currentTarget.dataset.example
    this.textareaTarget.value = example
    this.updateCharCount()
    this.autoResize({ target: this.textareaTarget })
    this.textareaTarget.focus()
  }

  // ========== Step 1: Submit Initial Idea ==========

  async submitIdea() {
    this.idea = this.textareaTarget.value.trim()

    if (this.idea.length < 10) {
      alert("아이디어를 10자 이상 입력해주세요.")
      return
    }

    // Store idea in sessionStorage
    sessionStorage.setItem("onboarding_idea", this.idea)

    // Hide step 1 with fade out
    this.step1Target.style.opacity = "0"
    this.step1Target.style.transform = "translateY(-20px)"
    this.step1Target.style.transition = "opacity 0.3s ease, transform 0.3s ease"

    // Update progress (step 2 active)
    this.updateProgress(2)

    // Show loading with animation
    setTimeout(() => {
      this.step1Target.classList.add("hidden")
      this.loadingTarget.classList.remove("hidden")
      this.loadingTarget.style.opacity = "0"
      this.loadingTarget.style.transform = "translateY(20px)"

      // Fade in loading
      requestAnimationFrame(() => {
        this.loadingTarget.style.transition = "opacity 0.4s ease, transform 0.4s ease"
        this.loadingTarget.style.opacity = "1"
        this.loadingTarget.style.transform = "translateY(0)"
      })

      this.loadingTextTarget.textContent = "추가 질문을 생성하고 있어요"
    }, 300)

    // Add user message to hidden chat container (for compatibility)
    if (this.hasChatContainerTarget) {
      this.addUserMessage(this.idea)
    }

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

      // Show previous answer in Step 2 (using textContent for safety)
      if (this.hasPreviousAnswerTextTarget) {
        this.previousAnswerTextTarget.textContent = this.idea
      }

      // Render questions with new card style
      this.renderQuestions()

      // Transition to Step 2
      this.transitionToStep2()

    } catch (error) {
      console.error("Error fetching questions:", error)
      // Fallback: go directly to analysis
      this.goToAnalysis()
    }
  }

  transitionToStep2() {
    // Hide loading
    this.loadingTarget.style.opacity = "0"
    this.loadingTarget.style.transform = "translateY(-20px)"

    setTimeout(() => {
      this.loadingTarget.classList.add("hidden")

      // Show the previous answer as a user bubble (iMessage style)
      this.showPreviousAnswerAsBubble()

      // Show Step 2 with slide up animation
      this.step2Target.classList.remove("hidden")
      this.step2Target.style.opacity = "0"
      this.step2Target.style.transform = "translateY(30px)"

      requestAnimationFrame(() => {
        this.step2Target.style.transition = "opacity 0.5s ease, transform 0.5s ease"
        this.step2Target.style.opacity = "1"
        this.step2Target.style.transform = "translateY(0)"
      })

      // Animate question cards with stagger
      this.animateQuestionCards()
    }, 300)
  }

  animateQuestionCards() {
    // Animate all elements in the questions container (bubbles + input cards)
    const elements = this.questionsContainerTarget.children
    Array.from(elements).forEach((element, index) => {
      element.style.opacity = "0"
      element.style.transform = "translateY(16px)"

      setTimeout(() => {
        element.style.transition = "opacity 0.3s ease, transform 0.3s ease"
        element.style.opacity = "1"
        element.style.transform = "translateY(0)"
      }, 80 + (index * 80)) // Faster stagger for chat-like feel
    })
  }

  updateProgress(step) {
    // Phase 10: Charcoal Brown for active state (brand color)
    const activeColor = "bg-[#2C2825]"
    const inactiveColor = "bg-stone-200"

    // Reset all to inactive
    if (this.hasProgress1Target) {
      this.progress1Target.classList.remove(activeColor, "bg-[#007aff]", "bg-orange-500")
      this.progress1Target.classList.add(inactiveColor)
    }
    if (this.hasProgress2Target) {
      this.progress2Target.classList.remove(activeColor, "bg-[#007aff]", "bg-orange-500")
      this.progress2Target.classList.add(inactiveColor)
    }
    if (this.hasProgress3Target) {
      this.progress3Target.classList.remove(activeColor, "bg-[#007aff]", "bg-orange-500")
      this.progress3Target.classList.add(inactiveColor)
    }

    // Activate up to current step
    if (step >= 1 && this.hasProgress1Target) {
      this.progress1Target.classList.remove(inactiveColor, "bg-gray-200")
      this.progress1Target.classList.add(activeColor)
    }
    if (step >= 2 && this.hasProgress2Target) {
      this.progress2Target.classList.remove(inactiveColor, "bg-gray-200")
      this.progress2Target.classList.add(activeColor)
    }
    if (step >= 3 && this.hasProgress3Target) {
      this.progress3Target.classList.remove(inactiveColor, "bg-gray-200")
      this.progress3Target.classList.add(activeColor)
    }
  }

  // ========== Question Rendering (Phase 10 Style - Premium Cards) ==========

  renderQuestions() {
    const container = this.questionsContainerTarget
    container.replaceChildren() // Safe way to clear children

    this.questions.forEach((question, index) => {
      // Create AI question bubble with Undrew character avatar
      const aiBubble = document.createElement("div")
      aiBubble.className = "flex items-start gap-3 mb-4"

      // Undrew character avatar (left side)
      const avatar = document.createElement("div")
      avatar.className = "flex-shrink-0 w-10 h-10 rounded-full bg-gradient-to-br from-orange-100 to-amber-50 p-1 shadow-sm"

      const avatarImg = document.createElement("img")
      avatarImg.src = "/undrew_hello_icon.png"
      avatarImg.alt = "Undrew"
      avatarImg.className = "w-full h-full object-contain"
      avatar.appendChild(avatarImg)

      // Question bubble (right side)
      const bubble = document.createElement("div")
      bubble.className = "px-5 py-3 bg-stone-100 rounded-2xl rounded-tl-md text-base text-[#2C2825] max-w-[85%]"
      bubble.textContent = question.question

      aiBubble.appendChild(avatar)
      aiBubble.appendChild(bubble)
      container.appendChild(aiBubble)

      // Create input card (Premium style - matches view's input area)
      const card = document.createElement("div")
      card.className = "relative bg-stone-50/50 rounded-2xl p-5 border border-stone-100 mb-4"
      card.style.opacity = "0"
      card.dataset.questionIndex = index

      // Create input with Premium style
      const input = document.createElement("input")
      input.type = "text"
      input.dataset.questionId = question.id
      input.dataset.required = question.required
      input.placeholder = question.placeholder || "답변을 입력해주세요..."
      input.className = "w-full bg-transparent border-0 text-lg font-medium text-[#2C2825] placeholder:text-stone-300 focus:outline-none"
      input.dataset.action = "input->ai-input#updateAnswers"

      // Add required/optional indicator (Premium style)
      const indicator = document.createElement("div")
      indicator.className = "flex items-center justify-between mt-3 pt-3 border-t border-stone-100"

      const statusSpan = document.createElement("span")
      statusSpan.className = "text-sm font-medium"
      if (question.required) {
        statusSpan.className += " text-[#2C2825]"
        statusSpan.textContent = "필수"
      } else {
        statusSpan.className += " text-stone-400"
        statusSpan.textContent = "선택"
      }
      indicator.appendChild(statusSpan)

      // Assemble card
      card.appendChild(input)
      card.appendChild(indicator)
      container.appendChild(card)
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

  // ========== Step 2: Submit for Analysis ==========

  submitForAnalysis() {
    // Update progress to step 3
    this.updateProgress(3)

    // Skip loading screen here - ai_result.html.erb has beautiful Undrew loading overlay
    // This prevents "double loading screen" feeling (Task 45)
    // Just disable the button to prevent double-click
    if (this.hasAnalyzeButtonTarget) {
      this.analyzeButtonTarget.disabled = true
      this.analyzeButtonTarget.textContent = "분석 시작 중..."
    }

    // Submit immediately - ai_result will show loading
    this.submitPostForm(this.idea, this.answers)
  }

  goToAnalysis() {
    this.loadingTarget.classList.remove("hidden")
    this.loadingTextTarget.textContent = "AI가 아이디어를 분석하고 있어요"

    // Submit via POST form
    this.submitPostForm(this.idea, {})
  }

  // ========== Form Submission ==========

  submitPostForm(idea, answers) {
    const form = document.createElement("form")
    form.method = "POST"
    form.action = this.analyzeUrlValue

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
    ideaInput.value = idea
    form.appendChild(ideaInput)

    // Answers (JSON)
    const answersInput = document.createElement("input")
    answersInput.type = "hidden"
    answersInput.name = "answers"
    answersInput.value = JSON.stringify(answers)
    form.appendChild(answersInput)

    document.body.appendChild(form)
    form.submit()
  }

  // ========== Legacy Methods (Compatibility) ==========

  addUserMessage(text) {
    if (!this.hasChatContainerTarget) return

    // Create message using safe DOM methods
    const wrapper = document.createElement("div")
    wrapper.className = "flex gap-3 justify-end"

    const inner = document.createElement("div")
    inner.className = "max-w-[80%]"

    const bubble = document.createElement("div")
    bubble.className = "bg-primary text-primary-foreground rounded-2xl rounded-tr-md px-4 py-3"

    const p = document.createElement("p")
    p.className = "text-sm"
    p.textContent = text // Safe: uses textContent

    bubble.appendChild(p)
    inner.appendChild(bubble)
    wrapper.appendChild(inner)
    this.chatContainerTarget.appendChild(wrapper)
  }

  addAiMessage(text) {
    if (!this.hasChatContainerTarget) return

    // Create message using safe DOM methods
    const wrapper = document.createElement("div")
    wrapper.className = "flex gap-3"

    // Avatar
    const avatar = document.createElement("div")
    avatar.className = "flex-shrink-0 h-10 w-10 rounded-full bg-gradient-to-br from-primary/20 to-primary/5 flex items-center justify-center"

    const svgNS = "http://www.w3.org/2000/svg"
    const svg = document.createElementNS(svgNS, "svg")
    svg.setAttribute("class", "h-5 w-5 text-primary")
    svg.setAttribute("fill", "none")
    svg.setAttribute("stroke", "currentColor")
    svg.setAttribute("viewBox", "0 0 24 24")

    const path = document.createElementNS(svgNS, "path")
    path.setAttribute("stroke-linecap", "round")
    path.setAttribute("stroke-linejoin", "round")
    path.setAttribute("stroke-width", "1.5")
    path.setAttribute("d", "M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z")
    svg.appendChild(path)
    avatar.appendChild(svg)

    // Content
    const content = document.createElement("div")
    content.className = "flex-1"

    const name = document.createElement("p")
    name.className = "text-sm font-medium text-foreground mb-1"
    name.textContent = "AI 분석봇"

    const bubble = document.createElement("div")
    bubble.className = "bg-secondary/50 rounded-2xl rounded-tl-md px-4 py-3"

    const p = document.createElement("p")
    p.className = "text-sm text-foreground"
    p.textContent = text // Safe: uses textContent

    bubble.appendChild(p)
    content.appendChild(name)
    content.appendChild(bubble)

    wrapper.appendChild(avatar)
    wrapper.appendChild(content)
    this.chatContainerTarget.appendChild(wrapper)
  }

  scrollToBottom() {
    if (!this.hasChatContainerTarget) return

    setTimeout(() => {
      this.chatContainerTarget.scrollIntoView({ behavior: "smooth", block: "end" })
    }, 100)
  }

  // ========== Phase 10: Premium Bubble Methods ==========

  /**
   * Transform user input into a Premium history bubble (Charcoal Brown, right-aligned)
   * Used when transitioning from Step 1 to Step 2
   */
  transformToUserBubble() {
    if (!this.hasChatAreaTarget || !this.hasInputAreaTarget) return

    const text = this.textareaTarget.value.trim()
    const bubble = this.createHistoryBubble(text)

    // Insert bubble before input area
    this.chatAreaTarget.insertBefore(bubble, this.inputAreaTarget)

    // Animate entrance
    bubble.classList.add("animate-slide-in-up")
  }

  /**
   * Create a Premium history bubble (Charcoal Brown, right-aligned)
   * Phase 10 Style: Uses history-bubble class
   * @param {string} text - The message text
   * @returns {HTMLElement} The bubble wrapper element
   */
  createHistoryBubble(text) {
    const wrapper = document.createElement("div")
    wrapper.className = "flex justify-end mb-6"

    const bubble = document.createElement("div")
    bubble.className = "history-bubble"
    bubble.textContent = text // Safe: uses textContent

    wrapper.appendChild(bubble)
    return wrapper
  }

  /**
   * Create a Premium AI bubble (stone background, left-aligned)
   * Phase 10 Style: Uses rounded-2xl and stone colors
   * @param {string} text - The message text
   * @returns {HTMLElement} The bubble wrapper element
   */
  createAiBubble(text) {
    const wrapper = document.createElement("div")
    wrapper.className = "flex mb-4"

    const bubble = document.createElement("div")
    bubble.className = "px-5 py-3 bg-stone-100 rounded-2xl rounded-bl-md text-base text-[#2C2825] animate-slide-in-up"
    bubble.textContent = text // Safe: uses textContent

    wrapper.appendChild(bubble)
    return wrapper
  }

  /**
   * Add an AI response bubble to the chat area
   * @param {string} text - The AI message text
   */
  addAiBubbleToChat(text) {
    if (!this.hasChatAreaTarget) return

    const bubble = this.createAiBubble(text)
    this.chatAreaTarget.appendChild(bubble)

    // Scroll to show the new bubble
    this.scrollChatToBottom()
  }

  /**
   * Scroll the chat area to the bottom smoothly
   */
  scrollChatToBottom() {
    if (!this.hasChatAreaTarget) return

    setTimeout(() => {
      this.chatAreaTarget.scrollTo({
        top: this.chatAreaTarget.scrollHeight,
        behavior: "smooth"
      })
    }, 100)
  }

  /**
   * Show the previous answer as a Premium history bubble in Step 2
   * Called during transition from Step 1 to Step 2
   * Phase 10: Uses history-bubble class with animate-slide-in-up
   */
  showPreviousAnswerAsBubble() {
    if (!this.hasPreviousAnswerTarget || !this.hasPreviousAnswerTextTarget) return

    // The view already has the bubble structure,
    // just need to populate and show it
    this.previousAnswerTextTarget.textContent = this.idea
    this.previousAnswerTarget.classList.remove("hidden")
    this.previousAnswerTarget.classList.add("animate-slide-in-up")
  }

  // Note: Animation helpers imported from ./mixins/animation_helpers
  // delay(ms) function is now imported, not a class method
}
