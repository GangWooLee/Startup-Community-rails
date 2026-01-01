import { Controller } from "@hotwired/stimulus"

/**
 * 신고 모달 컨트롤러
 *
 * 버튼과 모달이 다른 DOM 위치에 있어도 작동하도록 document.getElementById 사용
 *
 * 사용법: 버튼에 data-action="click->report-modal#open"
 *        data-reportable-type="Post" data-reportable-id="123" 추가
 */
export default class extends Controller {
  connect() {
    // ESC 키로 닫기
    this.escHandler = this.handleEsc.bind(this)
    document.addEventListener("keydown", this.escHandler)
  }

  disconnect() {
    document.removeEventListener("keydown", this.escHandler)
  }

  // 모달 요소 찾기 (버튼과 모달이 다른 위치에 있어도 작동)
  get modal() {
    return document.getElementById("report-modal")
  }

  // 모달 열기
  open(event) {
    event.preventDefault()
    event.stopPropagation()

    const modal = this.modal
    if (!modal) {
      console.error("Report modal not found")
      return
    }

    const button = event.currentTarget
    const reportableType = button.dataset.reportableType
    const reportableId = button.dataset.reportableId
    const targetName = button.dataset.targetName || this.getDefaultTargetName(reportableType)

    // hidden 필드 설정
    const typeField = modal.querySelector('[data-report-modal-target="reportableType"]')
    const idField = modal.querySelector('[data-report-modal-target="reportableId"]')
    const labelField = modal.querySelector('[data-report-modal-target="targetLabel"]')

    if (typeField) typeField.value = reportableType
    if (idField) idField.value = reportableId
    if (labelField) labelField.textContent = targetName

    // 모달 표시
    modal.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")

    // 폼 리셋
    const form = modal.querySelector("form")
    if (form) {
      form.reset()
      // 첫 번째 라디오 버튼 선택
      const firstRadio = form.querySelector('input[type="radio"]')
      if (firstRadio) firstRadio.checked = true
    }
  }

  // 모달 닫기
  close() {
    const modal = this.modal
    if (modal) {
      modal.classList.add("hidden")
      document.body.classList.remove("overflow-hidden")
    }
  }

  // ESC 키 처리
  handleEsc(event) {
    const modal = this.modal
    if (event.key === "Escape" && modal && !modal.classList.contains("hidden")) {
      this.close()
    }
  }

  // 폼 제출
  submit(event) {
    const modal = this.modal
    if (modal) {
      const submitBtn = modal.querySelector('[data-report-modal-target="submitBtn"]')
      if (submitBtn) {
        submitBtn.disabled = true
        submitBtn.textContent = "처리 중..."
      }
    }
  }

  // 기본 대상 이름 생성
  getDefaultTargetName(type) {
    const names = {
      "Post": "게시글",
      "User": "사용자",
      "ChatRoom": "채팅방"
    }
    return names[type] || type
  }
}
