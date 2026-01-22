import { Controller } from "@hotwired/stimulus"

/**
 * Bridge Menu Controller - 네이티브 액션 시트
 *
 * Hotwire Native 앱에서 네이티브 액션 시트(Bottom Sheet)를 표시합니다.
 * 웹에서는 드롭다운 메뉴를 표시합니다.
 *
 * 사용법:
 *   <div data-controller="bridge--menu"
 *        data-bridge--menu-items-value='[
 *          {"title": "수정", "action": "edit", "icon": "pencil"},
 *          {"title": "삭제", "action": "delete", "icon": "trash", "destructive": true},
 *          {"title": "취소", "action": "cancel", "cancel": true}
 *        ]'>
 *     <button data-action="click->bridge--menu#show">더보기</button>
 *     <div data-bridge--menu-target="dropdown" class="hidden">
 *       <!-- 웹용 드롭다운 메뉴 -->
 *     </div>
 *   </div>
 */
export default class extends Controller {
  static targets = ["dropdown"]
  static values = {
    items: { type: Array, default: [] },
    title: String  // 액션 시트 제목 (선택)
  }

  get isNativeApp() {
    return navigator.userAgent.includes("Turbo Native")
  }

  /**
   * 메뉴 표시
   */
  show(event) {
    event?.preventDefault()
    event?.stopPropagation()

    if (this.isNativeApp) {
      this.showNativeMenu()
    } else {
      this.showWebMenu()
    }
  }

  /**
   * 메뉴 숨기기
   */
  hide() {
    if (this.hasDropdownTarget) {
      this.dropdownTarget.classList.add("hidden")
    }
  }

  // ==========================================================================
  // Native App 처리
  // ==========================================================================

  showNativeMenu() {
    const message = {
      title: this.titleValue || null,
      items: this.itemsValue.map(item => ({
        title: item.title,
        action: item.action,
        icon: item.icon,
        style: item.destructive ? "destructive" : item.cancel ? "cancel" : "default"
      }))
    }

    if (window.webkit?.messageHandlers?.nativeApp) {
      // iOS
      window.webkit.messageHandlers.nativeApp.postMessage({
        component: "menu",
        action: "show",
        data: message
      })
    } else if (window.NativeApp?.postMessage) {
      // Android
      window.NativeApp.postMessage(JSON.stringify({
        component: "menu",
        action: "show",
        data: message
      }))
    } else {
      this.showWebMenu()
    }
  }

  // 네이티브에서 호출하는 콜백
  onNativeMenuSelect(action) {
    this.executeAction(action)
  }

  // ==========================================================================
  // Web 처리 (폴백)
  // ==========================================================================

  showWebMenu() {
    if (this.hasDropdownTarget) {
      this.dropdownTarget.classList.toggle("hidden")

      // 외부 클릭 시 닫기
      if (!this.dropdownTarget.classList.contains("hidden")) {
        this.boundCloseOnClick = this.closeOnClickOutside.bind(this)
        document.addEventListener("click", this.boundCloseOnClick)
      }
    }
  }

  closeOnClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hide()
      document.removeEventListener("click", this.boundCloseOnClick)
    }
  }

  /**
   * 메뉴 아이템 선택 (웹용)
   */
  select(event) {
    const action = event.currentTarget.dataset.action
    this.hide()
    this.executeAction(action)
  }

  // ==========================================================================
  // 액션 실행
  // ==========================================================================

  executeAction(action) {
    const item = this.itemsValue.find(i => i.action === action)
    if (!item || item.cancel) return

    // 커스텀 이벤트 발생
    this.element.dispatchEvent(new CustomEvent("bridge:menu:select", {
      bubbles: true,
      detail: { action, item }
    }))
  }

  disconnect() {
    if (this.boundCloseOnClick) {
      document.removeEventListener("click", this.boundCloseOnClick)
    }
  }
}
