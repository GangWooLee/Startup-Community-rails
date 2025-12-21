import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["loading", "loadingText", "result"]
  static values = { idea: String }

  connect() {
    this.startAnalysis()
  }

  startAnalysis() {
    const loadingMessages = [
      "아이디어 분석 중...",
      "시장 조사 중...",
      "타깃 사용자 분석 중...",
      "방향성 도출 중...",
      "분석 완료!"
    ]

    let currentIndex = 0
    const interval = setInterval(() => {
      currentIndex++

      if (currentIndex < loadingMessages.length) {
        this.loadingTextTarget.textContent = loadingMessages[currentIndex]
      }

      if (currentIndex >= loadingMessages.length - 1) {
        clearInterval(interval)
        setTimeout(() => this.showResult(), 500)
      }
    }, 600)
  }

  showResult() {
    this.loadingTarget.classList.add("hidden")
    this.resultTarget.classList.remove("hidden")
  }

  goToPost(event) {
    // Idea is already stored in sessionStorage by ai_input_controller
    // The post form will read from sessionStorage on load
  }
}
