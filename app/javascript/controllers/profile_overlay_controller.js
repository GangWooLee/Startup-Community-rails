import { Controller } from "@hotwired/stimulus"

// 채팅방 내 프로필 오버레이 컨트롤러
export default class extends Controller {
  static targets = ["backdrop", "card"]

  connect() {
    // 오버레이가 열리면 body 스크롤 비활성화
    document.body.style.overflow = "hidden"
  }

  disconnect() {
    // 오버레이가 닫히면 body 스크롤 복원
    document.body.style.overflow = ""
  }

  close() {
    // 닫기 애니메이션
    if (this.hasCardTarget) {
      this.cardTarget.style.animation = "slide-down 0.15s ease-in forwards"
    }
    if (this.hasBackdropTarget) {
      this.backdropTarget.style.opacity = "0"
      this.backdropTarget.style.transition = "opacity 0.15s ease-in"
    }

    // 애니메이션 후 요소 제거
    setTimeout(() => {
      this.element.remove()
    }, 150)
  }

  backdropClick(event) {
    // 배경(backdrop) 클릭 시에만 닫기 (카드 클릭은 무시)
    if (event.target === this.backdropTarget || event.target === this.element) {
      this.close()
    }
  }
}
