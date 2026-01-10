import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "button", "imageInput", "imagePreview", "imagePreviewContainer"]

  connect() {
    this.autoResize()
    this.selectedFile = null

    // Paste 이벤트 리스너 등록
    this.boundHandlePaste = this.handlePaste.bind(this)
    this.element.addEventListener("paste", this.boundHandlePaste)
  }

  disconnect() {
    this.element.removeEventListener("paste", this.boundHandlePaste)
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
      // 텍스트나 이미지 중 하나라도 있으면 전송
      if (this.canSubmit()) {
        this.element.requestSubmit()
      }
    }
  }

  submit(event) {
    // 직접 호출 시 전송
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
