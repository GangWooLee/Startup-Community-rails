import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["result"]
  static values = { idea: String }

  goToPost(event) {
    // 요약을 sessionStorage에 저장 (제목용)
    const summary = event.currentTarget.dataset.summary
    if (summary) {
      sessionStorage.setItem('onboarding_idea_summary', summary)
    }
    // 원본 아이디어는 저장하지 않음 - 본문은 사용자가 직접 작성
  }
}
