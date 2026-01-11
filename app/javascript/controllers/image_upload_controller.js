import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview", "counter", "dropzone", "existingImage"]
  static values = { existingCount: { type: Number, default: 0 } }

  connect() {
    this.maxFiles = 5
    this.maxFileSize = 10 * 1024 * 1024 // 10MB
    this.files = []
    this.updateCounter()

    // Paste 이벤트 리스너 등록 (document 레벨에서 수신)
    // textarea 등에 포커스가 있어도 이미지 paste를 감지할 수 있음
    this.boundHandlePaste = this.handlePaste.bind(this)
    document.addEventListener("paste", this.boundHandlePaste)
  }

  disconnect() {
    // Paste 이벤트 리스너 제거
    document.removeEventListener("paste", this.boundHandlePaste)
  }

  // 클립보드에서 이미지 붙여넣기 처리
  // textarea 등 어디서든 이미지를 붙여넣으면 사진 첨부 영역에 추가됨
  handlePaste(event) {
    // 이 컨트롤러가 보이는 상태인지 확인 (여러 컨트롤러 중복 처리 방지)
    if (!this.isVisible()) return

    const items = event.clipboardData?.items
    if (!items) return

    // 클립보드에서 이미지 파일만 추출
    const imageFiles = []
    for (const item of items) {
      if (item.type.startsWith("image/")) {
        const file = item.getAsFile()
        if (file) imageFiles.push(file)
      }
    }

    // 이미지가 있을 때만 처리 (텍스트만 있으면 기본 동작 유지)
    if (imageFiles.length > 0) {
      event.preventDefault()
      this.processFiles(imageFiles)
    }
  }

  // 컨트롤러 요소가 화면에 보이는지 확인
  isVisible() {
    const rect = this.element.getBoundingClientRect()
    // 요소가 화면에 표시되고 있는지 (숨겨져 있거나 display:none이 아닌지)
    return rect.width > 0 && rect.height > 0 &&
           getComputedStyle(this.element).display !== 'none' &&
           getComputedStyle(this.element).visibility !== 'hidden'
  }

  // 파일 배열 처리 (handleFiles와 handlePaste에서 공통 사용)
  processFiles(newFiles) {
    // 남은 슬롯보다 많으면 경고 후 가능한 만큼만 추가
    if (newFiles.length > this.remainingSlots) {
      alert(`최대 ${this.maxFiles}장까지 업로드할 수 있습니다. (현재 ${this.totalCount}장, 추가 가능 ${this.remainingSlots}장)`)
      newFiles = newFiles.slice(0, this.remainingSlots)
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
    this.processFiles(newFiles)
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

      // 안전하게 DOM 요소 생성 (innerHTML 대신 DOM API 사용)
      const img = document.createElement('img')
      img.src = e.target.result
      img.className = 'w-full h-full object-cover'
      img.alt = '업로드 이미지 미리보기'

      const button = document.createElement('button')
      button.type = 'button'
      button.className = 'absolute top-1 right-1 w-6 h-6 flex items-center justify-center bg-black/60 rounded-full text-white hover:bg-black/80 transition-colors'
      button.setAttribute('aria-label', '이미지 삭제')
      button.dataset.action = 'click->image-upload#removeNewImage'
      button.dataset.index = index


      // SVG 아이콘 (DOM API로 안전하게 생성)
      const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg')
      svg.setAttribute('class', 'h-4 w-4')
      svg.setAttribute('fill', 'none')
      svg.setAttribute('stroke', 'currentColor')
      svg.setAttribute('viewBox', '0 0 24 24')
      svg.setAttribute('aria-hidden', 'true')

      const path = document.createElementNS('http://www.w3.org/2000/svg', 'path')
      path.setAttribute('stroke-linecap', 'round')
      path.setAttribute('stroke-linejoin', 'round')
      path.setAttribute('stroke-width', '2')
      path.setAttribute('d', 'M6 18L18 6M6 6l12 12')

      svg.appendChild(path)
      button.appendChild(svg)
      div.appendChild(img)
      div.appendChild(button)
      this.previewTarget.appendChild(div)
    }

    reader.onerror = () => {
      console.error('Failed to read file:', file.name)
      alert('이미지 미리보기 생성에 실패했습니다.')
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
