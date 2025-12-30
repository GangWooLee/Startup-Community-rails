import { Controller } from "@hotwired/stimulus"

// 탈퇴 사유 선택 시 "기타" 상세 입력 필드 토글
export default class extends Controller {
  static targets = ["select", "detail"]

  connect() {
    this.toggle()
  }

  toggle() {
    const isOther = this.selectTarget.value === "other"

    if (isOther) {
      this.detailTarget.classList.remove("hidden")
    } else {
      this.detailTarget.classList.add("hidden")
    }
  }
}
