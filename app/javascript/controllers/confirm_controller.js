import { Controller } from "@hotwired/stimulus"

// Confirm Controller
// 폼 제출 전 확인 다이얼로그를 표시하는 컨트롤러
//
// 사용법:
// <form data-controller="confirm" data-confirm-message-value="정말 삭제하시겠습니까?">
//   <button type="submit">삭제</button>
// </form>
//
// 또는 버튼에 직접:
// <button data-controller="confirm" data-action="click->confirm#check"
//         data-confirm-message-value="삭제하시겠습니까?">삭제</button>

export default class extends Controller {
  static values = {
    message: { type: String, default: "정말 진행하시겠습니까?" }
  }

  connect() {
    // 폼인 경우 submit 이벤트에 리스너 추가
    if (this.element.tagName === "FORM") {
      this.element.addEventListener("submit", this.handleSubmit.bind(this))
    }
  }

  disconnect() {
    if (this.element.tagName === "FORM") {
      this.element.removeEventListener("submit", this.handleSubmit.bind(this))
    }
  }

  handleSubmit(event) {
    if (!confirm(this.messageValue)) {
      event.preventDefault()
      event.stopPropagation()
    }
  }

  // 버튼 클릭 시 직접 호출용
  check(event) {
    if (!confirm(this.messageValue)) {
      event.preventDefault()
      event.stopPropagation()
    }
  }
}
