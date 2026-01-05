import { Controller } from "@hotwired/stimulus"

// Drawbridge Task #100: Mobile Bottom Sheet UX 개선
// Speed Dial 패턴 적용 - FAB 클릭 시 미니 FAB 확장
export default class extends Controller {
  static targets = ["overlay", "sheet", "speedDial", "mainButton", "backdrop"]

  connect() {
    this.isOpen = false
    this.boundHandleKeydown = this.handleKeydown.bind(this)
    this.boundHandleClickOutside = this.handleClickOutside.bind(this)
    document.addEventListener("keydown", this.boundHandleKeydown)
    document.addEventListener("click", this.boundHandleClickOutside)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundHandleKeydown)
    document.removeEventListener("click", this.boundHandleClickOutside)
  }

  // Speed Dial 토글 (모바일용)
  toggle(event) {
    event.stopPropagation()
    if (this.isOpen) {
      this.closeSpeedDial()
    } else {
      this.openSpeedDial()
    }
  }

  openSpeedDial() {
    this.isOpen = true

    // 백드롭 표시 (터치 영역 확보)
    if (this.hasBackdropTarget) {
      this.backdropTarget.classList.remove("hidden", "opacity-0")
      this.backdropTarget.classList.add("opacity-100")
    }

    // 메인 버튼 회전
    if (this.hasMainButtonTarget) {
      this.mainButtonTarget.classList.add("rotate-45")
    }

    // Speed Dial 아이템 표시 (staggered animation)
    if (this.hasSpeedDialTarget) {
      const items = this.speedDialTarget.querySelectorAll("[data-speed-dial-item]")
      this.speedDialTarget.classList.remove("pointer-events-none")

      items.forEach((item, index) => {
        setTimeout(() => {
          item.classList.remove("opacity-0", "translate-y-4", "scale-75")
          item.classList.add("opacity-100", "translate-y-0", "scale-100")
        }, index * 50)
      })
    }
  }

  closeSpeedDial() {
    this.isOpen = false

    // 백드롭 숨기기
    if (this.hasBackdropTarget) {
      this.backdropTarget.classList.remove("opacity-100")
      this.backdropTarget.classList.add("opacity-0")
      setTimeout(() => {
        this.backdropTarget.classList.add("hidden")
      }, 200)
    }

    // 메인 버튼 회전 해제
    if (this.hasMainButtonTarget) {
      this.mainButtonTarget.classList.remove("rotate-45")
    }

    // Speed Dial 아이템 숨기기
    if (this.hasSpeedDialTarget) {
      const items = this.speedDialTarget.querySelectorAll("[data-speed-dial-item]")
      this.speedDialTarget.classList.add("pointer-events-none")

      items.forEach((item) => {
        item.classList.remove("opacity-100", "translate-y-0", "scale-100")
        item.classList.add("opacity-0", "translate-y-4", "scale-75")
      })
    }
  }

  // 외부 클릭 시 닫기
  handleClickOutside(event) {
    if (this.isOpen && !this.element.contains(event.target)) {
      this.closeSpeedDial()
    }
  }

  // PC용 바텀시트 (레거시 지원)
  open() {
    if (!this.hasOverlayTarget || !this.hasSheetTarget) return

    this.overlayTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"

    requestAnimationFrame(() => {
      this.overlayTarget.classList.remove("opacity-0")
      this.overlayTarget.classList.add("opacity-100")
      this.sheetTarget.classList.remove("translate-y-full")
      this.sheetTarget.classList.add("translate-y-0")
    })
  }

  close() {
    // Speed Dial이 열려있으면 먼저 닫기
    if (this.isOpen) {
      this.closeSpeedDial()
      return
    }

    if (!this.hasOverlayTarget || !this.hasSheetTarget) return

    this.overlayTarget.classList.remove("opacity-100")
    this.overlayTarget.classList.add("opacity-0")
    this.sheetTarget.classList.remove("translate-y-0")
    this.sheetTarget.classList.add("translate-y-full")

    setTimeout(() => {
      this.overlayTarget.classList.add("hidden")
      document.body.style.overflow = ""
    }, 300)
  }

  handleKeydown(event) {
    if (event.key === "Escape") {
      if (this.isOpen) {
        this.closeSpeedDial()
      } else if (this.hasOverlayTarget && !this.overlayTarget.classList.contains("hidden")) {
        this.close()
      }
    }
  }
}
