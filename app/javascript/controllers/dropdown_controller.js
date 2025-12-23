import { Controller } from "@hotwired/stimulus"

// 드롭다운 메뉴 토글 컨트롤러
export default class extends Controller {
  static targets = ["menu"]

  connect() {
    // 외부 클릭 시 닫기
    this.boundClose = this.closeOnClickOutside.bind(this)
    document.addEventListener("click", this.boundClose)
  }

  disconnect() {
    document.removeEventListener("click", this.boundClose)
  }

  toggle(event) {
    event.stopPropagation()
    this.menuTarget.classList.toggle("hidden")
  }

  closeOnClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.classList.add("hidden")
    }
  }

  close() {
    this.menuTarget.classList.add("hidden")
  }
}
