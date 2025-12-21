import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview", "counter", "dropzone", "existingImage"]
  static values = { existingCount: { type: Number, default: 0 } }

  connect() {
    this.maxFiles = 5
    this.maxFileSize = 10 * 1024 * 1024 // 10MB
    this.files = []
    this.updateCounter()
  }

  // 현재 총 이미지 수 (기존 + 새로 추가된)
  get totalCount() {
    const existingCount = this.hasExistingImageTarget ? this.existingImageTargets.length : 0
    return existingCount + this.files.length
  }

  // 남은 업로드 가능 수
  get remainingSlots() {
    return this.maxFiles - this.totalCount
  }

  handleFiles(event) {
    const newFiles = Array.from(event.target.files)

    // 최대 파일 수 체크
    if (newFiles.length > this.remainingSlots) {
      alert(`최대 ${this.maxFiles}장까지 업로드할 수 있습니다. (현재 ${this.totalCount}장, 추가 가능 ${this.remainingSlots}장)`)
      return
    }

    // 각 파일 검증 및 추가
    newFiles.forEach(file => {
      if (!this.validateFile(file)) return
      if (this.remainingSlots <= 0) return

      this.files.push(file)
      this.addPreview(file, this.files.length - 1)
    })

    this.updateFileInput()
    this.updateCounter()
  }

  validateFile(file) {
    // 파일 타입 체크
    if (!file.type.startsWith('image/')) {
      alert('이미지 파일만 업로드할 수 있습니다.')
      return false
    }

    // 파일 크기 체크
    if (file.size > this.maxFileSize) {
      alert('파일 크기는 10MB 이하만 가능합니다.')
      return false
    }

    return true
  }

  addPreview(file, index) {
    const reader = new FileReader()

    reader.onload = (e) => {
      const div = document.createElement('div')
      div.className = 'relative aspect-square rounded-lg overflow-hidden bg-secondary'
      div.dataset.index = index
      div.dataset.imageUploadTarget = 'newImage'
      div.innerHTML = `
        <img src="${e.target.result}" class="w-full h-full object-cover" alt="Preview">
        <button
          type="button"
          class="absolute top-1 right-1 w-6 h-6 flex items-center justify-center bg-black/60 rounded-full text-white hover:bg-black/80 transition-colors"
          data-action="click->image-upload#removeNewImage"
          data-index="${index}"
        >
          <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
          </svg>
        </button>
      `
      this.previewTarget.appendChild(div)
    }

    reader.readAsDataURL(file)
  }

  removeNewImage(event) {
    event.preventDefault()
    const index = parseInt(event.currentTarget.dataset.index)

    // 파일 배열에서 제거
    this.files.splice(index, 1)

    // 새 이미지 프리뷰만 다시 그리기 (기존 이미지는 유지)
    this.element.querySelectorAll('[data-image-upload-target="newImage"]').forEach(el => el.remove())
    this.files.forEach((file, i) => {
      this.addPreview(file, i)
    })

    this.updateFileInput()
    this.updateCounter()
  }

  updateFileInput() {
    // DataTransfer를 사용해 새 FileList 생성
    const dataTransfer = new DataTransfer()
    this.files.forEach(file => {
      dataTransfer.items.add(file)
    })
    this.inputTarget.files = dataTransfer.files
  }

  updateCounter() {
    if (this.hasCounterTarget) {
      this.counterTarget.textContent = `${this.totalCount}/${this.maxFiles}`
    }

    // 최대 개수 도달 시 업로드 버튼 숨김
    if (this.hasDropzoneTarget) {
      if (this.remainingSlots <= 0) {
        this.dropzoneTarget.classList.add('hidden')
      } else {
        this.dropzoneTarget.classList.remove('hidden')
      }
    }
  }

  // 기존 이미지가 삭제되면 카운터 업데이트 (Turbo Stream으로 삭제 후 호출)
  existingImageTargetDisconnected() {
    this.updateCounter()
  }
}
