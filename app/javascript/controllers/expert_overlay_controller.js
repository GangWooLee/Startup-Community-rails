import { Controller } from "@hotwired/stimulus"

// 추천 전문가 프로필 오버레이 컨트롤러
// expert_card 클릭 시 프로필 모달을 Turbo Stream으로 로드
export default class extends Controller {
  static targets = ["container"]

  show(event) {
    const userId = event.params.userId
    if (!userId) return

    // Prediction 데이터 추출 (expert_card_v2에서 전달)
    const scoreBoost = event.params.scoreBoost || 10
    const boostArea = event.params.boostArea || "전문성"
    const why = event.params.why || ""

    // Query params 생성
    const params = new URLSearchParams({
      score_boost: scoreBoost,
      boost_area: boostArea,
      why: why
    })

    // Turbo Stream으로 프로필 오버레이 로드
    fetch(`/ai/expert/${userId}?${params}`, {
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
