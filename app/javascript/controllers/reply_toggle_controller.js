import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "replies", "repliesButtonText"]
  static values = { repliesVisible: Boolean }

  connect() {
    this.repliesVisibleValue = false
  }

  // 답글 작성 폼 토글
  toggle() {
    if (this.hasFormTarget) {
      this.formTarget.classList.toggle("hidden")

      // 폼이 보이면 입력 필드에 포커스
      if (!this.formTarget.classList.contains("hidden")) {
        const input = this.formTarget.querySelector("textarea")
        if (input) {
          input.focus()
        }
      }
    }
  }

  // 답글 작성 폼 숨기기
  hide() {
    if (this.hasFormTarget) {
      this.formTarget.classList.add("hidden")
    }
  }

  // 대댓글 목록 토글 (답글 보기/숨기기)
  toggleReplies() {
    if (this.hasRepliesTarget) {
      this.repliesVisibleValue = !this.repliesVisibleValue
      this.repliesTarget.classList.toggle("hidden", !this.repliesVisibleValue)

      // 버튼 텍스트 변경
      if (this.hasRepliesButtonTextTarget) {
        const count = this.repliesTarget.querySelectorAll('[id^="comment-"]').length
        this.repliesButtonTextTarget.textContent = this.repliesVisibleValue
          ? `답글 숨기기`
          : `답글 보기(${count}개)`
      }
    }
  }
}
