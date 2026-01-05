import { Controller } from "@hotwired/stimulus"

// 사이드바 하단 프로필 드롭다운 컨트롤러
// Usage: data-controller="sidebar-dropdown"
// Targets: menu (드롭다운 메뉴), arrow (화살표 아이콘)
export default class extends Controller {
  static targets = ["menu", "arrow"]

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

      // 애니메이션 효과 추가
      if (this.isOpen) {
        this.menuTarget.style.opacity = "0"
        this.menuTarget.style.transform = "translateY(8px)"
        requestAnimationFrame(() => {
          this.menuTarget.style.transition = "opacity 0.15s ease-out, transform 0.15s ease-out"
          this.menuTarget.style.opacity = "1"
          this.menuTarget.style.transform = "translateY(0)"
        })
      }
    }

    if (this.hasArrowTarget) {
      // 화살표 회전 (열림: 180도, 닫힘: 0도)
      this.arrowTarget.style.transform = this.isOpen ? "rotate(180deg)" : "rotate(0deg)"
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
