import { Controller } from "@hotwired/stimulus"

/**
 * Bridge Alert Controller - JavaScript alert/confirm 대체
 *
 * Hotwire Native 앱에서 JavaScript의 alert()은 WebView에서 차단됩니다.
 * 이 컨트롤러는 네이티브 앱에서는 네이티브 알림을 표시하고,
 * 웹에서는 커스텀 모달 또는 기본 alert를 사용합니다.
 *
 * 사용법:
 *   <button data-controller="bridge--alert"
 *           data-bridge--alert-title-value="알림"
 *           data-bridge--alert-message-value="저장되었습니다"
 *           data-action="click->bridge--alert#showAlert">
 *     저장
 *   </button>
 *
 * Confirm 사용법:
 *   <button data-controller="bridge--alert"
 *           data-bridge--alert-title-value="삭제 확인"
 *           data-bridge--alert-message-value="정말 삭제하시겠습니까?"
 *           data-bridge--alert-confirm-action-value="delete"
 *           data-action="click->bridge--alert#showConfirm">
 *     삭제
 *   </button>
 */
export default class extends Controller {
  static values = {
    title: { type: String, default: "알림" },
    message: String,
    confirmAction: String,  // 확인 시 실행할 액션 이름
    confirmUrl: String      // 확인 시 이동할 URL
  }

  // Hotwire Native 앱 여부 확인
  get isNativeApp() {
    return navigator.userAgent.includes("Turbo Native")
  }

  /**
   * Alert 표시 (확인 버튼만)
   */
  showAlert(event) {
    event?.preventDefault()

    if (this.isNativeApp) {
      this.sendNativeAlert("alert")
    } else {
      this.showWebAlert()
    }
  }

  /**
   * Confirm 표시 (확인/취소 버튼)
   */
  showConfirm(event) {
    event?.preventDefault()

    if (this.isNativeApp) {
      this.sendNativeAlert("confirm")
    } else {
      this.showWebConfirm()
    }
  }

  // ==========================================================================
  // Native App 처리
  // ==========================================================================

  sendNativeAlert(type) {
    // Hotwire Native Bridge 메시지 전송
    // 네이티브 앱에서 이 메시지를 수신하여 네이티브 알림 표시
    const message = {
      type: type,
      title: this.titleValue,
      message: this.messageValue,
      buttons: type === "alert"
        ? [{ title: "확인", style: "default" }]
        : [
            { title: "취소", style: "cancel" },
            { title: "확인", style: "default" }
          ]
    }

    // WebView에서 네이티브로 메시지 전송
    if (window.webkit?.messageHandlers?.nativeApp) {
      // iOS
      window.webkit.messageHandlers.nativeApp.postMessage({
        component: "alert",
        action: "show",
        data: message
      })
    } else if (window.NativeApp?.postMessage) {
      // Android
      window.NativeApp.postMessage(JSON.stringify({
        component: "alert",
        action: "show",
        data: message
      }))
    } else {
      // 폴백: 웹 알림
      if (type === "alert") {
        this.showWebAlert()
      } else {
        this.showWebConfirm()
      }
    }
  }

  // 네이티브에서 호출하는 콜백
  onNativeResponse(buttonIndex) {
    if (buttonIndex === 1) {
      // 확인 버튼
      this.executeConfirmAction()
    }
  }

  // ==========================================================================
  // Web 처리 (폴백)
  // ==========================================================================

  showWebAlert() {
    // 커스텀 모달이 있으면 사용, 없으면 기본 alert
    const customModal = document.getElementById("alert-modal")
    if (customModal) {
      this.showCustomModal(customModal, false)
    } else {
      alert(this.messageValue)
    }
  }

  showWebConfirm() {
    // 커스텀 모달이 있으면 사용, 없으면 기본 confirm
    const customModal = document.getElementById("confirm-modal")
    if (customModal) {
      this.showCustomModal(customModal, true)
    } else {
      if (confirm(this.messageValue)) {
        this.executeConfirmAction()
      }
    }
  }

  showCustomModal(modal, isConfirm) {
    // 커스텀 모달 표시 로직
    const titleEl = modal.querySelector("[data-alert-title]")
    const messageEl = modal.querySelector("[data-alert-message]")
    const confirmBtn = modal.querySelector("[data-alert-confirm]")
    const cancelBtn = modal.querySelector("[data-alert-cancel]")

    if (titleEl) titleEl.textContent = this.titleValue
    if (messageEl) messageEl.textContent = this.messageValue

    if (confirmBtn) {
      confirmBtn.onclick = () => {
        modal.classList.add("hidden")
        this.executeConfirmAction()
      }
    }

    if (cancelBtn) {
      cancelBtn.classList.toggle("hidden", !isConfirm)
      cancelBtn.onclick = () => modal.classList.add("hidden")
    }

    modal.classList.remove("hidden")
  }

  // ==========================================================================
  // 확인 액션 실행
  // ==========================================================================

  executeConfirmAction() {
    if (this.confirmUrlValue) {
      // URL로 이동
      window.location.href = this.confirmUrlValue
    } else if (this.confirmActionValue) {
      // 커스텀 이벤트 발생
      this.element.dispatchEvent(new CustomEvent("bridge:alert:confirmed", {
        bubbles: true,
        detail: { action: this.confirmActionValue }
      }))
    }
  }
}
