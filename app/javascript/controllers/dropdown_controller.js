import { Controller } from "@hotwired/stimulus"

// 드롭다운 메뉴 토글 컨트롤러 (모바일 터치 지원)
export default class extends Controller {
  static targets = ["menu"]

  connect() {
    // 외부 클릭/터치 시 닫기
    this.boundCloseOnClick = this.closeOnClickOutside.bind(this)
    this.boundCloseOnTouch = this.closeOnTouchOutside.bind(this)

    document.addEventListener("click", this.boundCloseOnClick)
    document.addEventListener("touchend", this.boundCloseOnTouch)
  }

  disconnect() {
    document.removeEventListener("click", this.boundCloseOnClick)
    document.removeEventListener("touchend", this.boundCloseOnTouch)
  }

  toggle(event) {
    event.stopPropagation()
    event.preventDefault()  // 터치 시 ghost click 방지

    const isOpening = this.menuTarget.classList.contains("hidden")
    this.menuTarget.classList.toggle("hidden")

    // 모바일 Haptic 피드백 (열기 시)
    if (isOpening && navigator.vibrate) {
      navigator.vibrate(10)
    }
  }

  closeOnClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.classList.add("hidden")
    }
  }

  // 터치 시 외부 영역 터치로 닫기
  closeOnTouchOutside(event) {
    // 메뉴가 열려있고, 터치가 드롭다운 외부에서 발생한 경우
    if (!this.menuTarget.classList.contains("hidden") &&
        !this.element.contains(event.target)) {
      this.menuTarget.classList.add("hidden")
    }
  }

  close() {
    this.menuTarget.classList.add("hidden")
  }
}
