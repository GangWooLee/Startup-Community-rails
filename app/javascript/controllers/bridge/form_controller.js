import { Controller } from "@hotwired/stimulus"

/**
 * Bridge Form Controller - 폼 상태 동기화
 *
 * Hotwire Native 앱에서 폼 제출 상태를 네이티브와 동기화합니다.
 * - 제출 중 로딩 인디케이터 표시
 * - 네이티브 키보드 닫기
 * - 유효성 검사 결과 네이티브 표시
 *
 * 사용법:
 *   <form data-controller="bridge--form"
 *         data-action="turbo:submit-start->bridge--form#onSubmitStart
 *                      turbo:submit-end->bridge--form#onSubmitEnd">
 *     <input type="text" data-bridge--form-target="input">
 *     <button data-bridge--form-target="submit">저장</button>
 *   </form>
 */
export default class extends Controller {
  static targets = ["input", "submit"]
  static values = {
    loadingText: { type: String, default: "저장 중..." },
    submittingClass: { type: String, default: "opacity-50 pointer-events-none" }
  }

  get isNativeApp() {
    return navigator.userAgent.includes("Turbo Native")
  }

  /**
   * 폼 제출 시작
   */
  onSubmitStart(event) {
    // 버튼 비활성화
    if (this.hasSubmitTarget) {
      this.originalText = this.submitTarget.textContent
      this.submitTarget.textContent = this.loadingTextValue
      this.submitTarget.disabled = true
      this.submitTarget.classList.add(...this.submittingClassValue.split(" "))
    }

    // 네이티브 앱: 키보드 닫기 + 로딩 표시
    if (this.isNativeApp) {
      this.sendNativeMessage("formSubmitStart", {
        formId: this.element.id
      })

      // 입력 필드에서 포커스 제거 (키보드 닫기)
      if (document.activeElement instanceof HTMLElement) {
        document.activeElement.blur()
      }
    }
  }

  /**
   * 폼 제출 완료
   */
  onSubmitEnd(event) {
    // 버튼 복원
    if (this.hasSubmitTarget) {
      this.submitTarget.textContent = this.originalText || "저장"
      this.submitTarget.disabled = false
      this.submitTarget.classList.remove(...this.submittingClassValue.split(" "))
    }

    // 네이티브 앱: 로딩 숨기기
    if (this.isNativeApp) {
      const success = event.detail?.success !== false
      this.sendNativeMessage("formSubmitEnd", {
        formId: this.element.id,
        success: success
      })
    }
  }

  /**
   * 유효성 검사 에러 표시
   */
  showValidationErrors(errors) {
    if (this.isNativeApp) {
      // 네이티브 알림으로 에러 표시
      this.sendNativeMessage("validationError", {
        errors: errors
      })
    } else {
      // 웹: 각 필드에 에러 표시
      Object.entries(errors).forEach(([field, messages]) => {
        const input = this.element.querySelector(`[name*="${field}"]`)
        if (input) {
          input.classList.add("border-red-500")
          const errorEl = document.createElement("p")
          errorEl.className = "text-red-500 text-sm mt-1"
          errorEl.textContent = messages.join(", ")
          input.parentNode.appendChild(errorEl)
        }
      })
    }
  }

  /**
   * 에러 초기화
   */
  clearErrors() {
    this.element.querySelectorAll(".text-red-500").forEach(el => el.remove())
    this.element.querySelectorAll(".border-red-500").forEach(el => {
      el.classList.remove("border-red-500")
    })
  }

  // ==========================================================================
  // Native 통신
  // ==========================================================================

  sendNativeMessage(action, data) {
    const message = {
      component: "form",
      action: action,
      data: data
    }

    if (window.webkit?.messageHandlers?.nativeApp) {
      window.webkit.messageHandlers.nativeApp.postMessage(message)
    } else if (window.NativeApp?.postMessage) {
      window.NativeApp.postMessage(JSON.stringify(message))
    }
  }
}
