import { Controller } from "@hotwired/stimulus"

// 알림 드롭다운 토글 컨트롤러
export default class extends Controller {
  static targets = ["button", "dropdown"]

  connect() {
    // 외부 클릭 시 드롭다운 닫기
    this.handleClickOutside = this.handleClickOutside.bind(this)
    document.addEventListener("click", this.handleClickOutside)
  }

  disconnect() {
    document.removeEventListener("click", this.handleClickOutside)
  }

  toggle(event) {
    event.stopPropagation()
    this.dropdownTarget.classList.toggle("hidden")
  }

  handleClickOutside(event) {
    // 드롭다운 외부 클릭 시 닫기
    if (!this.element.contains(event.target)) {
      this.dropdownTarget.classList.add("hidden")
    }
  }

  close() {
    this.dropdownTarget.classList.add("hidden")
  }
}
