import { Controller } from "@hotwired/stimulus"

// Admin 슬라이드 패널 컨트롤러
// 오른쪽에서 슬라이드 인/아웃하는 상세 패널
export default class extends Controller {
  static targets = ["panel"]

  connect() {
    // 애니메이션을 위해 약간의 지연 후 열기
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        this.open()
      })
    })

    // ESC 키로 닫기
    this.escHandler = this.handleEsc.bind(this)
    document.addEventListener("keydown", this.escHandler)
  }

  disconnect() {
    document.removeEventListener("keydown", this.escHandler)
    document.body.classList.remove("overflow-hidden")
  }

  open() {
    document.body.classList.add("overflow-hidden")
    if (this.hasPanelTarget) {
      this.panelTarget.classList.remove("translate-x-full")
    }
  }

  close() {
    if (this.hasPanelTarget) {
      this.panelTarget.classList.add("translate-x-full")
    }
    document.body.classList.remove("overflow-hidden")

    // 애니메이션 후 제거
    setTimeout(() => {
      this.element.remove()
    }, 300)
  }

  handleEsc(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }
}
