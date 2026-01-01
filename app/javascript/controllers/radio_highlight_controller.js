import { Controller } from "@hotwired/stimulus"

/**
 * Radio Highlight Controller
 *
 * 라디오 버튼 선택 시 부모 요소에 시각적 하이라이트 적용
 *
 * 사용법:
 * <div data-controller="radio-highlight">
 *   <label data-radio-highlight-target="option">
 *     <input type="radio" data-action="change->radio-highlight#highlight">
 *   </label>
 * </div>
 */
export default class extends Controller {
  static targets = ["option"]
  static classes = ["active"]

  connect() {
    // 페이지 로드 시 선택된 라디오 버튼의 부모에 하이라이트 적용
    this.optionTargets.forEach(option => {
      const radio = option.querySelector('input[type="radio"]')
      if (radio && radio.checked) {
        this.applyHighlight(option)
      }
    })
  }

  highlight(event) {
    // 모든 옵션에서 하이라이트 제거
    this.optionTargets.forEach(option => {
      this.removeHighlight(option)
    })

    // 선택된 옵션에 하이라이트 적용
    const selectedOption = event.target.closest('[data-radio-highlight-target="option"]')
    if (selectedOption) {
      this.applyHighlight(selectedOption)
    }
  }

  applyHighlight(element) {
    element.classList.remove("border-gray-200", "bg-white")
    element.classList.add("border-blue-500", "bg-blue-50")
  }

  removeHighlight(element) {
    element.classList.remove("border-blue-500", "bg-blue-50")
    element.classList.add("border-gray-200", "bg-white")
  }
}
