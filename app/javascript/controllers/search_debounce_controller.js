import { Controller } from "@hotwired/stimulus"

// Debounce된 검색 폼 제출을 위한 컨트롤러
export default class extends Controller {
  static targets = ["input"]

  connect() {
    this.timeout = null
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  search(event) {
    // 기존 타임아웃 취소
    if (this.timeout) {
      clearTimeout(this.timeout)
    }

    // 300ms 후 폼 제출
    this.timeout = setTimeout(() => {
      this.element.requestSubmit()
    }, 300)
  }
}
