import { Controller } from "@hotwired/stimulus"

/**
 * Bridge Button Controller - 네이티브 네비게이션 바 버튼
 *
 * Hotwire Native 앱의 네비게이션 바에 버튼을 추가합니다.
 * 웹에서는 화면에 직접 버튼을 렌더링합니다.
 *
 * 네이티브 앱에서는 이 컨트롤러가 네비게이션 바에 버튼을 추가하고,
 * 버튼 클릭 시 웹에서 정의한 액션을 실행합니다.
 *
 * 사용법:
 *   <!-- 페이지 로드 시 네비게이션 바에 버튼 추가 -->
 *   <div data-controller="bridge--button"
 *        data-bridge--button-title-value="저장"
 *        data-bridge--button-icon-value="checkmark"
 *        data-bridge--button-position-value="right"
 *        data-action="bridge:button:tap->someController#save">
 *   </div>
 */
export default class extends Controller {
  static values = {
    title: String,
    icon: String,       // SF Symbols (iOS) / Material Icons (Android)
    position: { type: String, default: "right" },  // left, right
    enabled: { type: Boolean, default: true }
  }

  get isNativeApp() {
    return navigator.userAgent.includes("Turbo Native")
  }

  connect() {
    if (this.isNativeApp && this.hasTitleValue) {
      this.addNativeButton()
    }
  }

  disconnect() {
    if (this.isNativeApp) {
      this.removeNativeButton()
    }
  }

  // ==========================================================================
  // Native App 처리
  // ==========================================================================

  addNativeButton() {
    this.buttonId = `button_${Date.now()}`

    const message = {
      id: this.buttonId,
      title: this.titleValue,
      icon: this.iconValue,
      position: this.positionValue,
      enabled: this.enabledValue
    }

    this.sendNativeMessage("addButton", message)

    // 네이티브 버튼 클릭 이벤트 리스너
    window.bridgeButtonCallbacks = window.bridgeButtonCallbacks || {}
    window.bridgeButtonCallbacks[this.buttonId] = () => {
      this.onButtonTap()
    }
  }

  removeNativeButton() {
    if (this.buttonId) {
      this.sendNativeMessage("removeButton", { id: this.buttonId })
      delete window.bridgeButtonCallbacks?.[this.buttonId]
    }
  }

  updateButton() {
    if (this.isNativeApp && this.buttonId) {
      this.sendNativeMessage("updateButton", {
        id: this.buttonId,
        enabled: this.enabledValue
      })
    }
  }

  enabledValueChanged() {
    this.updateButton()
  }

  // ==========================================================================
  // 버튼 탭 처리
  // ==========================================================================

  onButtonTap() {
    // 커스텀 이벤트 발생 (다른 컨트롤러에서 처리)
    this.element.dispatchEvent(new CustomEvent("bridge:button:tap", {
      bubbles: true,
      detail: { buttonId: this.buttonId }
    }))
  }

  // 네이티브에서 직접 호출하는 전역 함수
  static handleNativeButtonTap(buttonId) {
    if (window.bridgeButtonCallbacks?.[buttonId]) {
      window.bridgeButtonCallbacks[buttonId]()
    }
  }

  // ==========================================================================
  // Native 통신
  // ==========================================================================

  sendNativeMessage(action, data) {
    const message = {
      component: "button",
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

// 전역 함수 등록 (네이티브에서 호출)
window.handleBridgeButtonTap = (buttonId) => {
  if (window.bridgeButtonCallbacks?.[buttonId]) {
    window.bridgeButtonCallbacks[buttonId]()
  }
}
