import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["slide", "indicator", "prevButton", "nextButton", "current"]
  static values = { index: { type: Number, default: 0 } }

  connect() {
    this.totalSlides = this.slideTargets.length
    this.updateUI()

    // 터치/스와이프 지원
    this.element.addEventListener('touchstart', this.handleTouchStart.bind(this), { passive: true })
    this.element.addEventListener('touchend', this.handleTouchEnd.bind(this), { passive: true })
  }

  disconnect() {
    this.element.removeEventListener('touchstart', this.handleTouchStart.bind(this))
    this.element.removeEventListener('touchend', this.handleTouchEnd.bind(this))
  }

  next() {
    if (this.indexValue < this.totalSlides - 1) {
      this.indexValue++
      this.updateUI()
    }
  }

  prev() {
    if (this.indexValue > 0) {
      this.indexValue--
      this.updateUI()
    }
  }

  goToSlide(event) {
    const index = parseInt(event.currentTarget.dataset.index)
    if (index >= 0 && index < this.totalSlides) {
      this.indexValue = index
      this.updateUI()
    }
  }

  updateUI() {
    // 슬라이드 위치 업데이트
    this.slideTargets.forEach((slide, index) => {
      if (index === this.indexValue) {
        slide.classList.remove('hidden')
        slide.classList.add('flex')
      } else {
        slide.classList.remove('flex')
        slide.classList.add('hidden')
      }
    })

    // 인디케이터 업데이트
    this.indicatorTargets.forEach((indicator, index) => {
      if (index === this.indexValue) {
        indicator.classList.remove('bg-white/50')
        indicator.classList.add('bg-white')
      } else {
        indicator.classList.remove('bg-white')
        indicator.classList.add('bg-white/50')
      }
    })

    // 버튼 상태 업데이트
    if (this.hasPrevButtonTarget) {
      if (this.indexValue === 0) {
        this.prevButtonTarget.classList.add('opacity-30', 'cursor-not-allowed')
        this.prevButtonTarget.classList.remove('hover:bg-black/60')
      } else {
        this.prevButtonTarget.classList.remove('opacity-30', 'cursor-not-allowed')
        this.prevButtonTarget.classList.add('hover:bg-black/60')
      }
    }

    if (this.hasNextButtonTarget) {
      if (this.indexValue === this.totalSlides - 1) {
        this.nextButtonTarget.classList.add('opacity-30', 'cursor-not-allowed')
        this.nextButtonTarget.classList.remove('hover:bg-black/60')
      } else {
        this.nextButtonTarget.classList.remove('opacity-30', 'cursor-not-allowed')
        this.nextButtonTarget.classList.add('hover:bg-black/60')
      }
    }

    // 페이지 카운터 업데이트
    if (this.hasCurrentTarget) {
      this.currentTarget.textContent = this.indexValue + 1
    }
  }

  // 터치 스와이프 처리
  handleTouchStart(event) {
    this.touchStartX = event.touches[0].clientX
  }

  handleTouchEnd(event) {
    if (!this.touchStartX) return

    const touchEndX = event.changedTouches[0].clientX
    const diff = this.touchStartX - touchEndX

    // 50px 이상 스와이프 시 슬라이드 전환
    if (Math.abs(diff) > 50) {
      if (diff > 0) {
        this.next()
      } else {
        this.prev()
      }
    }

    this.touchStartX = null
  }
}
