import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["result"]
  static values = { idea: String }

  goToPost(event) {
    // 아이디어를 sessionStorage에 저장 (로그인 후에도 유지됨)
    // ai_input에서 이미 저장했지만, 혹시 없을 경우를 대비해 다시 저장
    if (this.ideaValue) {
      sessionStorage.setItem('onboarding_idea', this.ideaValue)
    }
  }
}
