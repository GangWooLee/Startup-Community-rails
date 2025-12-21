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
    // 아이디어를 sessionStorage에 저장 (로그인 후에도 유지됨)
    // ai_input에서 이미 저장했지만, 혹시 없을 경우를 대비해 다시 저장
    if (this.ideaValue) {
      sessionStorage.setItem('onboarding_idea', this.ideaValue)
    }
  }
}
