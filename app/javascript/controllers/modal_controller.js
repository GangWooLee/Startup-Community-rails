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
// 모바일: 아래로 스와이프하여 닫기 지원
//
export default class extends Controller {
  static targets = ["backdrop", "card"]
  static values = {
    closable: { type: Boolean, default: true },
    swipeThreshold: { type: Number, default: 100 }  // 스와이프 닫기 임계값 (px)
  }

  connect() {
    // 초기 상태 설정
    this.isOpen = !this.element.classList.contains("hidden")

    // 터치 이벤트 바인딩 (모바일 스와이프 닫기)
    this.boundTouchStart = this.handleTouchStart.bind(this)
    this.boundTouchMove = this.handleTouchMove.bind(this)
    this.boundTouchEnd = this.handleTouchEnd.bind(this)

    // 터치 상태 초기화
    this.touchStartY = 0
    this.touchCurrentY = 0
    this.isDragging = false
  }

  disconnect() {
    // 터치 리스너 정리
    if (this.hasCardTarget) {
      this.cardTarget.removeEventListener("touchstart", this.boundTouchStart)
      this.cardTarget.removeEventListener("touchmove", this.boundTouchMove)
      this.cardTarget.removeEventListener("touchend", this.boundTouchEnd)
    }
  }

  // 터치 시작
  handleTouchStart(event) {
    if (!this.closableValue) return

    this.touchStartY = event.touches[0].clientY
    this.touchCurrentY = this.touchStartY
    this.isDragging = true

    // 드래그 중 transition 비활성화
    if (this.hasCardTarget) {
      this.cardTarget.style.transition = "none"
    }
  }

  // 터치 이동 - 모달 카드 따라 이동
  handleTouchMove(event) {
    if (!this.isDragging || !this.closableValue) return

    this.touchCurrentY = event.touches[0].clientY
    const deltaY = this.touchCurrentY - this.touchStartY

    // 아래로만 드래그 허용 (위로는 제한)
    if (deltaY > 0 && this.hasCardTarget) {
      // 드래그 거리에 따라 모달 이동 (저항감 적용)
      const translateY = deltaY * 0.5
      this.cardTarget.style.transform = `translateY(${translateY}px)`

      // 배경 투명도 조절
      if (this.hasBackdropTarget) {
        const opacity = Math.max(0, 1 - (deltaY / 300))
        this.backdropTarget.style.opacity = opacity
      }
    }
  }

  // 터치 종료 - 임계값 초과 시 닫기
  handleTouchEnd(event) {
    if (!this.isDragging || !this.closableValue) return

    const deltaY = this.touchCurrentY - this.touchStartY
    this.isDragging = false

    // transition 복원
    if (this.hasCardTarget) {
      this.cardTarget.style.transition = ""
    }

    // 임계값 초과 시 닫기
    if (deltaY > this.swipeThresholdValue) {
      this.close()
    } else {
      // 원위치로 복원
      if (this.hasCardTarget) {
        this.cardTarget.style.transform = ""
      }
      if (this.hasBackdropTarget) {
        this.backdropTarget.style.opacity = ""
      }
    }
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

      // 모바일 터치 리스너 등록 (스와이프 닫기)
      this.cardTarget.addEventListener("touchstart", this.boundTouchStart, { passive: true })
      this.cardTarget.addEventListener("touchmove", this.boundTouchMove, { passive: true })
      this.cardTarget.addEventListener("touchend", this.boundTouchEnd)
    }
  }

  close() {
    if (!this.closableValue) return

    // 터치 리스너 제거 (누적 방지)
    if (this.hasCardTarget) {
      this.cardTarget.removeEventListener("touchstart", this.boundTouchStart)
      this.cardTarget.removeEventListener("touchmove", this.boundTouchMove)
      this.cardTarget.removeEventListener("touchend", this.boundTouchEnd)
    }

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
