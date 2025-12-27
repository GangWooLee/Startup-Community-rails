import { Controller } from "@hotwired/stimulus"

// Admin 벌크 선택 컨트롤러
// 체크박스 선택 시 하단 액션 바 표시
export default class extends Controller {
  static targets = ["checkbox", "actionBar", "count"]

  connect() {
    this.updateUI()
  }

  toggle(event) {
    event.stopPropagation()
    this.updateUI()
  }

  toggleAll(event) {
    const checked = event.target.checked
    this.checkboxTargets.forEach(cb => cb.checked = checked)
    this.updateUI()
  }

  cancel() {
    this.checkboxTargets.forEach(cb => cb.checked = false)
    this.updateUI()
  }

  stopPropagation(event) {
    event.stopPropagation()
  }

  rowClick(event) {
    const userId = event.currentTarget.dataset.userId
    if (userId) {
      window.location.href = `/admin/users/${userId}`
    }
  }

  updateUI() {
    const selected = this.checkboxTargets.filter(cb => cb.checked)

    if (this.hasCountTarget) {
      this.countTarget.textContent = selected.length
    }

    if (this.hasActionBarTarget) {
      if (selected.length > 0) {
        this.actionBarTarget.classList.remove("translate-y-full")
      } else {
        this.actionBarTarget.classList.add("translate-y-full")
      }
    }
  }

  getSelectedIds() {
    return this.checkboxTargets
      .filter(cb => cb.checked)
      .map(cb => cb.value)
  }
}
