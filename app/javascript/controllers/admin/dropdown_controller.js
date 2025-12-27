import { Controller } from "@hotwired/stimulus"

// Admin 드롭다운 컨트롤러
// 필터 드롭다운 메뉴 토글
export default class extends Controller {
  static targets = ["menu"]

  connect() {
    // 외부 클릭 시 닫기
    this.outsideClickHandler = this.handleOutsideClick.bind(this)
    document.addEventListener("click", this.outsideClickHandler)
  }

  disconnect() {
    document.removeEventListener("click", this.outsideClickHandler)
  }

  toggle(event) {
    event.stopPropagation()

    if (this.hasMenuTarget) {
      this.menuTarget.classList.toggle("hidden")
    }
  }

  handleOutsideClick(event) {
    if (!this.element.contains(event.target) && this.hasMenuTarget) {
      this.menuTarget.classList.add("hidden")
    }
  }

  close() {
    if (this.hasMenuTarget) {
      this.menuTarget.classList.add("hidden")
    }
  }
}
