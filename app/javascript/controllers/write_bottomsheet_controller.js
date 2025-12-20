import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "sheet"]

  connect() {
    // ESC 키로 닫기
    this.boundHandleKeydown = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this.boundHandleKeydown)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundHandleKeydown)
  }

  open() {
    // 오버레이 표시
    this.overlayTarget.classList.remove("hidden")
    // 스크롤 방지
    document.body.style.overflow = "hidden"

    // 애니메이션 (약간의 딜레이 후 적용)
    requestAnimationFrame(() => {
      this.overlayTarget.classList.remove("opacity-0")
      this.overlayTarget.classList.add("opacity-100")
      this.sheetTarget.classList.remove("translate-y-full")
      this.sheetTarget.classList.add("translate-y-0")
    })
  }

  close() {
    // 애니메이션
    this.overlayTarget.classList.remove("opacity-100")
    this.overlayTarget.classList.add("opacity-0")
    this.sheetTarget.classList.remove("translate-y-0")
    this.sheetTarget.classList.add("translate-y-full")

    // 애니메이션 완료 후 숨기기
    setTimeout(() => {
      this.overlayTarget.classList.add("hidden")
      document.body.style.overflow = ""
    }, 300)
  }

  handleKeydown(event) {
    if (event.key === "Escape" && !this.overlayTarget.classList.contains("hidden")) {
      this.close()
    }
  }
}
