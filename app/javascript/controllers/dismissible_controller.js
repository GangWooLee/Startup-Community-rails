import { Controller } from "@hotwired/stimulus"

// Alert/Toast 닫기 컨트롤러
// data-controller="dismissible" 로 사용
export default class extends Controller {
  dismiss() {
    // 페이드 아웃 애니메이션
    this.element.style.opacity = "0"
    this.element.style.transform = "translateY(-10px)"
    this.element.style.transition = "opacity 0.2s ease-out, transform 0.2s ease-out"

    // 애니메이션 완료 후 제거
    setTimeout(() => {
      this.element.remove()
    }, 200)
  }
}
