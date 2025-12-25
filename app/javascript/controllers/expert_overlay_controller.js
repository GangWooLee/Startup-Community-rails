import { Controller } from "@hotwired/stimulus"

// 추천 전문가 프로필 오버레이 컨트롤러
// expert_card 클릭 시 프로필 모달을 Turbo Stream으로 로드
export default class extends Controller {
  static targets = ["container"]

  show(event) {
    const userId = event.params.userId
    if (!userId) return

    // Turbo Stream으로 프로필 오버레이 로드
    fetch(`/ai/expert/${userId}`, {
      method: "GET",
      headers: {
        "Accept": "text/vnd.turbo-stream.html",
        "X-Requested-With": "XMLHttpRequest"
      }
    })
    .then(response => response.text())
    .then(html => {
      Turbo.renderStreamMessage(html)
    })
    .catch(error => {
      console.error("Failed to load expert profile:", error)
    })
  }
}
