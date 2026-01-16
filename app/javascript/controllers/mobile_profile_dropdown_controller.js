import { Controller } from "@hotwired/stimulus"

// 모바일 사이드바 상단 프로필 드롭다운 컨트롤러
// 모바일에서 사이드바 하단 프로필이 가려지는 문제 해결
// Usage: data-controller="mobile-profile-dropdown"
// Targets: menu (드롭다운 메뉴)
export default class extends Controller {
  static targets = ["menu"]

  connect() {
    this.isOpen = false
    // 외부 클릭 시 닫기
    this.boundClose = this.closeOnClickOutside.bind(this)
    document.addEventListener("click", this.boundClose)

    // ESC 키로 닫기
    this.boundKeydown = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this.boundKeydown)
  }

  disconnect() {
    document.removeEventListener("click", this.boundClose)
    document.removeEventListener("keydown", this.boundKeydown)
  }

  toggle(event) {
    event.stopPropagation()
    this.isOpen = !this.isOpen
    this.updateUI()
  }

  updateUI() {
    if (this.hasMenuTarget) {
      this.menuTarget.classList.toggle("hidden", !this.isOpen)

      // 애니메이션 효과
      if (this.isOpen) {
        this.menuTarget.style.opacity = "0"
        this.menuTarget.style.transform = "translateY(-8px)"
        requestAnimationFrame(() => {
          this.menuTarget.style.transition = "opacity 0.15s ease-out, transform 0.15s ease-out"
          this.menuTarget.style.opacity = "1"
          this.menuTarget.style.transform = "translateY(0)"
        })
      }
    }
  }

  closeOnClickOutside(event) {
    if (!this.element.contains(event.target) && this.isOpen) {
      this.isOpen = false
      this.updateUI()
    }
  }

  handleKeydown(event) {
    if (event.key === "Escape" && this.isOpen) {
      this.isOpen = false
      this.updateUI()
    }
  }

  close() {
    this.isOpen = false
    this.updateUI()
  }
}
