import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

/**
 * AI 분석 결과 저장 체크박스 컨트롤러 (v2)
 *
 * 동작 방식:
 * - 체크박스 자유롭게 on/off 토글
 * - 페이지 이탈 시 체크 상태면 저장 API 호출
 *
 * 이벤트 처리:
 * - turbo:before-visit (Turbo 링크 클릭)
 * - beforeunload (탭 닫기, URL 직접 입력)
 *
 * 사용법:
 * <div data-controller="save-analysis"
 *      data-save-analysis-url-value="/ai/result/123/save"
 *      data-save-analysis-already-saved-value="false">
 *   <input type="checkbox"
 *          data-save-analysis-target="checkbox"
 *          data-action="change->save-analysis#toggle">
 *   <span data-save-analysis-target="label">아이디어 저장</span>
 * </div>
 */
export default class extends Controller {
  static targets = ["checkbox", "label"]
  static values = {
    url: String,
    alreadySaved: { type: Boolean, default: false }
  }

  connect() {
    // 페이지 이탈 이벤트 바인딩
    this.boundBeforeVisit = this.saveOnLeave.bind(this)
    this.boundBeforeUnload = this.saveOnUnload.bind(this)

    document.addEventListener("turbo:before-visit", this.boundBeforeVisit)
    window.addEventListener("beforeunload", this.boundBeforeUnload)
  }

  disconnect() {
    // 이벤트 리스너 정리
    document.removeEventListener("turbo:before-visit", this.boundBeforeVisit)
    window.removeEventListener("beforeunload", this.boundBeforeUnload)
  }

  // 체크박스 토글 (즉시 저장 X, 상태만 변경)
  toggle() {
    // 이미 저장된 분석은 체크 해제 불가
    if (this.alreadySavedValue && !this.checkboxTarget.checked) {
      this.checkboxTarget.checked = true
      return
    }

    this.updateLabel()
  }

  // 라벨 색상 업데이트 (텍스트는 항상 "아이디어 저장" 유지)
  updateLabel() {
    if (!this.hasLabelTarget) return

    if (this.checkboxTarget.checked) {
      this.labelTarget.classList.add("text-emerald-600")
      this.labelTarget.classList.remove("text-slate-600")
    } else {
      this.labelTarget.classList.add("text-slate-600")
      this.labelTarget.classList.remove("text-emerald-600")
    }
  }

  // Turbo 링크 클릭 시 저장
  async saveOnLeave(event) {
    if (this.shouldSave()) {
      // 저장할 내용이 있으면 먼저 네비게이션 중지
      event.preventDefault()

      // 저장 완료 대기
      await this.performSave()

      // 저장 후 원래 목적지로 이동
      Turbo.visit(event.detail.url)
    }
  }

  // 탭 닫기/URL 직접 입력 시 저장 (sendBeacon 사용)
  saveOnUnload(event) {
    if (this.shouldSave()) {
      // sendBeacon은 페이지 종료 시에도 안정적으로 전송
      const formData = new FormData()
      formData.append("authenticity_token", this.csrfToken)

      navigator.sendBeacon(this.urlValue, formData)
    }
  }

  // 저장 조건: 체크됨 + 아직 저장 안 됨
  shouldSave() {
    return this.checkboxTarget.checked && !this.alreadySavedValue
  }

  // fetch로 저장 요청
  async performSave() {
    try {
      const response = await fetch(this.urlValue, {
        method: "POST",
        headers: {
          "X-CSRF-Token": this.csrfToken,
          "Accept": "application/json",
          "Content-Type": "application/json"
        }
      })

      if (response.ok) {
        this.alreadySavedValue = true
      }
    } catch (error) {
      console.error("[SaveAnalysis] 저장 오류:", error)
    }
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content || ""
  }
}
