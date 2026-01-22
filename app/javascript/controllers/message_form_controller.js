import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "button", "imageInput", "imagePreview", "imagePreviewContainer"]

  connect() {
    this.autoResize()
    this.selectedFile = null
    this.isSubmitting = false  // 중복 제출 방지 플래그

    // Paste 이벤트 리스너 등록
    this.boundHandlePaste = this.handlePaste.bind(this)
    this.element.addEventListener("paste", this.boundHandlePaste)

    // Page Visibility API: 탭 재활성화 시 상태 복구
    this.boundHandleVisibilityChange = this.handleVisibilityChange.bind(this)
    document.addEventListener("visibilitychange", this.boundHandleVisibilityChange)

    // 모바일 터치 이벤트: 스와이프 제스처 지원
    this.touchStartX = 0
    this.touchStartY = 0
    this.boundTouchStart = this.handleTouchStart.bind(this)
    this.boundTouchEnd = this.handleTouchEnd.bind(this)
    this.element.addEventListener("touchstart", this.boundTouchStart, { passive: true })
    this.element.addEventListener("touchend", this.boundTouchEnd)
  }

  disconnect() {
    this.element.removeEventListener("paste", this.boundHandlePaste)
    document.removeEventListener("visibilitychange", this.boundHandleVisibilityChange)
    this.element.removeEventListener("touchstart", this.boundTouchStart)
    this.element.removeEventListener("touchend", this.boundTouchEnd)
  }

  // 터치 시작 위치 기록
  handleTouchStart(event) {
    this.touchStartX = event.touches[0].clientX
    this.touchStartY = event.touches[0].clientY
  }

  // 터치 종료: 왼쪽 스와이프로 입력 초기화
  handleTouchEnd(event) {
    const deltaX = event.changedTouches[0].clientX - this.touchStartX
    const deltaY = event.changedTouches[0].clientY - this.touchStartY

    // 가로 스와이프가 세로보다 크고, 왼쪽으로 80px 이상 스와이프
    if (Math.abs(deltaX) > Math.abs(deltaY) && deltaX < -80) {
      // 왼쪽 스와이프: 이미지 첨부 제거 (첨부된 경우)
      if (this.selectedFile) {
        this.removeImage()
        // Haptic 피드백 (지원되는 경우)
        if (navigator.vibrate) {
          navigator.vibrate(10)
        }
      }
    }
  }

  // 탭 가시성 변경 시 호출 (탭 복귀 시 상태 복구)
  handleVisibilityChange() {
    if (document.visibilityState === "visible") {
      // 탭이 다시 활성화됨 - 고정된 상태 복구
      // 5초 이상 제출 중이었다면 비정상 상태로 간주하고 리셋
      if (this.isSubmitting && this.submitStartTime) {
        const elapsed = Date.now() - this.submitStartTime
        if (elapsed > 5000) {
          console.debug("[message-form] 탭 복귀: 고정된 제출 상태 리셋")
          this.resetSubmitState()
        }
      }
    }
  }

  // 제출 상태 완전 리셋
  resetSubmitState() {
    this.isSubmitting = false
    this.submitStartTime = null
    if (this.hasButtonTarget) {
      this.buttonTarget.disabled = false
    }
  }

  // Turbo 제출 시작 - 중복 제출 방지
  handleSubmitStart() {
    this.isSubmitting = true
    this.submitStartTime = Date.now()  // 탭 복귀 시 상태 판단용
    if (this.hasButtonTarget) {
      this.buttonTarget.disabled = true
    }
  }

  // Turbo 제출 완료 - 상태 초기화 및 폼 리셋
  handleSubmitEnd() {
    this.isSubmitting = false
    this.submitStartTime = null
    if (this.hasButtonTarget) {
      this.buttonTarget.disabled = false
    }
    this.reset()
  }

  // 클립보드에서 이미지 붙여넣기 처리
  handlePaste(event) {
    const items = event.clipboardData?.items
    if (!items) return

    for (const item of items) {
      if (item.type.startsWith("image/")) {
        const file = item.getAsFile()
        if (file) {
          event.preventDefault()
          this.attachImage(file)
          return
        }
      }
    }
  }

  // 파일 input에서 이미지 선택 시
  handleImageSelect(event) {
    const file = event.target.files[0]
    if (file) {
      this.attachImage(file)
    }
  }

  // 이미지 첨부 처리
  attachImage(file) {
    // 파일 크기 검증 (5MB)
    if (file.size > 5 * 1024 * 1024) {
      alert("이미지는 5MB 이하만 가능합니다.")
      return
    }

    // 파일 타입 검증
    if (!file.type.startsWith("image/")) {
      alert("이미지 파일만 업로드할 수 있습니다.")
      return
    }

    this.selectedFile = file

    // 미리보기 표시
    const reader = new FileReader()
    reader.onload = (e) => {
      if (this.hasImagePreviewTarget && this.hasImagePreviewContainerTarget) {
        this.imagePreviewTarget.src = e.target.result
        this.imagePreviewContainerTarget.classList.remove("hidden")
      }
    }
    reader.readAsDataURL(file)

    // file input에 설정
    if (this.hasImageInputTarget) {
      const dataTransfer = new DataTransfer()
      dataTransfer.items.add(file)
      this.imageInputTarget.files = dataTransfer.files
    }
  }

  // 이미지 제거
  removeImage(event) {
    if (event) event.preventDefault()

    this.selectedFile = null

    if (this.hasImagePreviewContainerTarget) {
      this.imagePreviewContainerTarget.classList.add("hidden")
    }

    if (this.hasImageInputTarget) {
      this.imageInputTarget.value = ""
    }
  }

  // Enter로 전송, Shift+Enter로 줄바꿈
  handleKeydown(event) {
    // 한글 IME 조합 중이면 무시 (중복 전송 방지)
    if (event.isComposing) return

    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      // 이미 제출 중이면 무시 (Enter 연타 방지)
      if (this.isSubmitting) return
      // 텍스트나 이미지 중 하나라도 있으면 전송
      if (this.canSubmit()) {
        this.element.requestSubmit()
      }
    }
  }

  submit(event) {
    // 직접 호출 시 전송
    if (this.isSubmitting) return  // 중복 제출 방지
    if (this.canSubmit()) {
      event.preventDefault()
      this.element.requestSubmit()
    }
  }

  // 전송 가능 여부 확인 (텍스트 또는 이미지 중 하나라도 있으면)
  canSubmit() {
    const hasText = this.hasInputTarget && this.inputTarget.value.trim() !== ""
    const hasImage = this.selectedFile !== null
    return hasText || hasImage
  }

  reset() {
    // 텍스트 초기화
    if (this.hasInputTarget) {
      this.inputTarget.value = ""
      this.inputTarget.style.height = "auto"
      this.inputTarget.focus()
    }

    // 이미지 초기화
    this.removeImage()
  }

  autoResize() {
    if (this.hasInputTarget) {
      const input = this.inputTarget
      input.style.height = "auto"
      input.style.height = Math.min(input.scrollHeight, 128) + "px"
    }
  }
}
