import { Controller } from "@hotwired/stimulus"

/**
 * 저장됨 탭 필터 컨트롤러
 * 스크랩/좋아요/댓글 세 가지 필터 간 전환
 */
export default class extends Controller {
  static targets = ["menu", "arrow", "label", "filterButton", "content"]
  static values = { current: { type: String, default: "bookmarks" } }

  connect() {
    this.isOpen = false
    this.updateUI()
    this.boundCloseOnOutsideClick = this.closeOnOutsideClick.bind(this)
    document.addEventListener("click", this.boundCloseOnOutsideClick)
  }

  disconnect() {
    document.removeEventListener("click", this.boundCloseOnOutsideClick)
  }

  toggle(event) {
    event.stopPropagation()
    this.isOpen = !this.isOpen
    this.updateMenuVisibility()
  }

  select(event) {
    event.stopPropagation()
    const filter = event.currentTarget.dataset.filter
    if (filter === this.currentValue) {
      this.isOpen = false
      this.updateMenuVisibility()
      return
    }

    this.currentValue = filter
    this.isOpen = false
    this.updateUI()
  }

  updateUI() {
    this.updateMenuVisibility()
    this.updateLabel()
    this.updateActiveButton()
    this.showContent()
  }

  updateMenuVisibility() {
    if (this.hasMenuTarget) {
      this.menuTarget.classList.toggle("hidden", !this.isOpen)
    }
    if (this.hasArrowTarget) {
      this.arrowTarget.classList.toggle("rotate-180", this.isOpen)
    }
  }

  updateLabel() {
    if (!this.hasLabelTarget) return

    const labels = {
      bookmarks: "스크랩",
      likes: "좋아요",
      comments: "댓글"
    }
    this.labelTarget.textContent = labels[this.currentValue] || "스크랩"
  }

  updateActiveButton() {
    this.filterButtonTargets.forEach(button => {
      const isActive = button.dataset.filter === this.currentValue
      button.classList.toggle("bg-orange-50", isActive)
      button.classList.toggle("text-orange-600", isActive)
      button.classList.toggle("font-medium", isActive)
    })
  }

  showContent() {
    this.contentTargets.forEach(content => {
      const isMatch = content.dataset.filterType === this.currentValue
      content.classList.toggle("hidden", !isMatch)
    })
  }

  closeOnOutsideClick(event) {
    if (!this.element.contains(event.target) && this.isOpen) {
      this.isOpen = false
      this.updateMenuVisibility()
    }
  }
}
