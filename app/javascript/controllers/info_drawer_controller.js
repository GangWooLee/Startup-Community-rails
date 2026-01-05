import { Controller } from "@hotwired/stimulus"

// 채팅방 정보 패널 Drawer 컨트롤러
// 2xl 미만 화면에서 (i) 버튼 클릭 시 우측에서 슬라이드 인/아웃
export default class extends Controller {
  static targets = ["drawer", "backdrop"]

  connect() {
    // ESC 키로 닫기
    this.handleEscape = this.handleEscape.bind(this)
    document.addEventListener("keydown", this.handleEscape)
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleEscape)
    // 컨트롤러 해제 시 body overflow 복원
    document.body.classList.remove("overflow-hidden")
  }

  open() {
    // Drawer 슬라이드 인
    this.drawerTarget.classList.remove("translate-x-full")
    this.drawerTarget.classList.add("translate-x-0")

    // Backdrop 표시
    this.backdropTarget.classList.remove("opacity-0", "pointer-events-none")
    this.backdropTarget.classList.add("opacity-100")

    // 배경 스크롤 방지
    document.body.classList.add("overflow-hidden")

    // 접근성: drawer에 포커스
    this.drawerTarget.focus()
  }

  close() {
    // Drawer 슬라이드 아웃
    this.drawerTarget.classList.remove("translate-x-0")
    this.drawerTarget.classList.add("translate-x-full")

    // Backdrop 숨김
    this.backdropTarget.classList.remove("opacity-100")
    this.backdropTarget.classList.add("opacity-0", "pointer-events-none")

    // 배경 스크롤 복원
    document.body.classList.remove("overflow-hidden")
  }

  handleEscape(event) {
    if (event.key === "Escape" && !this.drawerTarget.classList.contains("translate-x-full")) {
      this.close()
    }
  }
}
