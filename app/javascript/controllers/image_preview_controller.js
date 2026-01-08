import { Controller } from "@hotwired/stimulus"

// 단일 이미지 파일 업로드 미리보기 컨트롤러
// 사용: 프로필 사진, 커버 이미지 등
export default class extends Controller {
  static targets = ["input", "preview", "placeholder"]
  static values = {
    maxSize: { type: Number, default: 2097152 }  // 2MB
  }

  preview() {
    const file = this.inputTarget.files[0]
    if (!file) return

    // 파일 타입 검증
    if (!file.type.startsWith('image/')) {
      alert('이미지 파일만 업로드할 수 있습니다.')
      this.inputTarget.value = ""
      return
    }

    // 파일 크기 검증
    if (file.size > this.maxSizeValue) {
      const maxMB = Math.round(this.maxSizeValue / 1024 / 1024)
      alert(`파일 크기는 ${maxMB}MB 이하만 허용됩니다.`)
      this.inputTarget.value = ""
      return
    }

    // FileReader로 미리보기
    const reader = new FileReader()
    reader.onload = (e) => {
      this.previewTarget.src = e.target.result
      this.previewTarget.classList.remove('hidden')

      // placeholder가 있으면 숨김
      if (this.hasPlaceholderTarget) {
        this.placeholderTarget.classList.add('hidden')
      }
    }
    reader.readAsDataURL(file)
  }
}
