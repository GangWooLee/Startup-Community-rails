import { Controller } from "@hotwired/stimulus"

// Modal/Dialog 컨트롤러 - undrew-design 스타일
// data-controller="modal" 로 사용
//
// 트리거 예시:
//   <button data-action="modal#open" data-modal-target-param="my-modal-id">열기</button>
//
// 모달 내부에서 닫기:
//   <button data-action="modal#close">닫기</button>
//
export default class extends Controller {
  static targets = ["backdrop", "card"]
  static values = {
    closable: { type: Boolean, default: true }
  }

  connect() {
    // 초기 상태 설정
    this.isOpen = !this.element.classList.contains("hidden")
  }

  open(event) {
    // 다른 요소에서 특정 모달을 열 때
    if (event && event.params && event.params.target) {
      const targetModal = document.getElementById(event.params.target)
      if (targetModal) {
        targetModal.classList.remove("hidden")
        document.body.style.overflow = "hidden"
        return
      }
    }

    // 현재 모달 열기
    this.element.classList.remove("hidden")
    document.body.style.overflow = "hidden"
    this.isOpen = true

    // 카드 애니메이션
    if (this.hasCardTarget) {
      this.cardTarget.classList.add("animate-modal-in")
    }
  }

  close() {
    if (!this.closableValue) return

    // 페이드 아웃 애니메이션
    if (this.hasBackdropTarget) {
      this.backdropTarget.style.opacity = "0"
    }
    if (this.hasCardTarget) {
      this.cardTarget.style.opacity = "0"
      this.cardTarget.style.transform = "scale(0.95)"
    }

    // 애니메이션 완료 후 숨기기
    setTimeout(() => {
      this.element.classList.add("hidden")
      document.body.style.overflow = ""
      this.isOpen = false

      // 스타일 리셋
      if (this.hasBackdropTarget) {
        this.backdropTarget.style.opacity = ""
      }
      if (this.hasCardTarget) {
        this.cardTarget.style.opacity = ""
        this.cardTarget.style.transform = ""
        this.cardTarget.classList.remove("animate-modal-in")
      }
    }, 150)
  }

  backdropClick(event) {
    if (this.closableValue) {
      this.close()
    }
  }

  stopPropagation(event) {
    event.stopPropagation()
  }

  // ESC 키 처리는 data-action="keydown.esc->modal#close"로 처리
}
