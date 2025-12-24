import { Controller } from "@hotwired/stimulus"

// 토스트 알림 자동 닫힘 컨트롤러
export default class extends Controller {
  static values = {
    duration: { type: Number, default: 3000 }
  }

  connect() {
    // 지정된 시간 후 자동으로 사라지게 함
    this.timeout = setTimeout(() => {
      this.dismiss()
    }, this.durationValue)
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  dismiss() {
    // fade out 애니메이션 적용
    this.element.classList.remove("animate-toast-in")
    this.element.classList.add("animate-toast-out")

    // 애니메이션 완료 후 요소 제거
    setTimeout(() => {
      this.element.remove()
    }, 300)
  }
}
