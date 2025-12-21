import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item", "button", "buttonText"]
  static values = { limit: { type: Number, default: 4 }, expanded: { type: Boolean, default: false } }

  connect() {
    this.updateVisibility()
  }

  toggle() {
    this.expandedValue = !this.expandedValue
    this.updateVisibility()
  }

  updateVisibility() {
    const items = this.itemTargets

    items.forEach((item, index) => {
      if (this.expandedValue || index < this.limitValue) {
        item.classList.remove("hidden")
      } else {
        item.classList.add("hidden")
      }
    })

    // 버튼 텍스트 업데이트
    if (this.hasButtonTextTarget) {
      const hiddenCount = items.length - this.limitValue
      this.buttonTextTarget.textContent = this.expandedValue
        ? "접기"
        : `더보기 (${hiddenCount}개)`
    }

    // 버튼 아이콘 회전
    if (this.hasButtonTarget) {
      const icon = this.buttonTarget.querySelector("svg")
      if (icon) {
        icon.classList.toggle("rotate-180", this.expandedValue)
      }
    }
  }
}
