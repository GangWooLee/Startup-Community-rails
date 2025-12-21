import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "image", "counter"]
  static values = {
    images: Array,
    index: { type: Number, default: 0 }
  }

  connect() {
    // ESC 키로 닫기
    this.handleKeydown = this.handleKeydown.bind(this)
    document.addEventListener('keydown', this.handleKeydown)
  }

  disconnect() {
    document.removeEventListener('keydown', this.handleKeydown)
    this.enableScroll()
  }

  open(event) {
    const index = parseInt(event.currentTarget.dataset.index || 0)
    this.indexValue = index
    this.updateImage()
    this.modalTarget.classList.remove('hidden')
    this.disableScroll()
  }

  close(event) {
    // 배경 클릭 또는 닫기 버튼 클릭 시만 닫기
    if (event.target === this.modalTarget || event.currentTarget.dataset.action?.includes('close')) {
      this.modalTarget.classList.add('hidden')
      this.enableScroll()
    }
  }

  next(event) {
    event.stopPropagation()
    if (this.indexValue < this.imagesValue.length - 1) {
      this.indexValue++
      this.updateImage()
    }
  }

  prev(event) {
    event.stopPropagation()
    if (this.indexValue > 0) {
      this.indexValue--
      this.updateImage()
    }
  }

  updateImage() {
    if (this.hasImageTarget && this.imagesValue.length > 0) {
      this.imageTarget.src = this.imagesValue[this.indexValue]
    }
    if (this.hasCounterTarget) {
      this.counterTarget.textContent = `${this.indexValue + 1} / ${this.imagesValue.length}`
    }
  }

  handleKeydown(event) {
    if (this.modalTarget.classList.contains('hidden')) return

    switch (event.key) {
      case 'Escape':
        this.modalTarget.classList.add('hidden')
        this.enableScroll()
        break
      case 'ArrowLeft':
        if (this.indexValue > 0) {
          this.indexValue--
          this.updateImage()
        }
        break
      case 'ArrowRight':
        if (this.indexValue < this.imagesValue.length - 1) {
          this.indexValue++
          this.updateImage()
        }
        break
    }
  }

  disableScroll() {
    document.body.style.overflow = 'hidden'
  }

  enableScroll() {
    document.body.style.overflow = ''
  }

  // 이미지 클릭 시 이벤트 전파 방지
  stopPropagation(event) {
    event.stopPropagation()
  }
}
