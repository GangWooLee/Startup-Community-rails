import { Controller } from "@hotwired/stimulus"

/**
 * Toast Notification Controller (Upgraded)
 *
 * 프로덕션급 토스트 알림 시스템 - XSS 안전
 * - 4가지 variant: success, error, warning, info
 * - 스택 관리 (최대 3개 표시)
 * - 아이콘 + 메시지 + 액션 버튼
 * - 진행 바 애니메이션
 * - 스태거드 리빌 애니메이션
 *
 * 사용법 (JavaScript):
 *   ToastManager.show("success", "저장되었습니다", {
 *     action: "실행취소",
 *     onAction: () => console.log("Undo clicked")
 *   })
 */

// 전역 ToastManager 싱글톤
class ToastManager {
  constructor() {
    this.toasts = []
    this.maxVisible = 3
    this.container = null
  }

  /**
   * Toast 컨테이너 가져오기/생성
   */
  getContainer() {
    if (!this.container || !document.body.contains(this.container)) {
      this.container = document.getElementById("toast-container")

      if (!this.container) {
        this.container = document.createElement("div")
        this.container.id = "toast-container"
        this.container.className = "fixed top-4 right-4 z-50 flex flex-col gap-2 max-w-sm"
        this.container.setAttribute("aria-live", "polite")
        this.container.setAttribute("aria-atomic", "true")
        document.body.appendChild(this.container)
      }
    }
    return this.container
  }

  /**
   * Toast 표시
   */
  show(variant, message, options = {}) {
    const container = this.getContainer()

    // 최대 개수 초과 시 가장 오래된 Toast 제거
    while (this.toasts.length >= this.maxVisible) {
      const oldest = this.toasts.shift()
      if (oldest && oldest.parentElement) {
        this.removeToast(oldest)
      }
    }

    // Toast 엘리먼트 생성
    const toast = this.createToastElement(variant, message, options)
    this.toasts.push(toast)

    // DOM에 추가
    container.appendChild(toast)

    // 스태거드 애니메이션을 위한 delay
    const delay = this.toasts.length * 50
    setTimeout(() => {
      toast.classList.add("toast-enter")
    }, delay)

    return toast
  }

  /**
   * Toast 엘리먼트 생성 (안전한 DOM API 사용)
   */
  createToastElement(variant, message, options = {}) {
    const {
      duration = 3000,
      action = null,
      onAction = null
    } = options

    const toast = document.createElement("div")
    toast.setAttribute("data-controller", "toast")
    toast.setAttribute("data-toast-variant-value", variant)
    toast.setAttribute("data-toast-duration-value", duration)
    toast.className = this.getToastClasses(variant)

    // 컨테이너 div
    const container = document.createElement("div")
    container.className = "flex items-start gap-3 p-4 relative overflow-hidden"

    // 아이콘
    const iconSvg = this.createIcon(variant)
    container.appendChild(iconSvg)

    // 메시지
    const messageDiv = document.createElement("div")
    messageDiv.className = "flex-1 min-w-0"
    const messageP = document.createElement("p")
    messageP.className = "text-sm font-medium"
    messageP.textContent = message // ✅ textContent 사용 (XSS 안전)
    messageDiv.appendChild(messageP)
    container.appendChild(messageDiv)

    // 액션 버튼
    if (action) {
      const actionBtn = document.createElement("button")
      actionBtn.type = "button"
      actionBtn.className = "ml-auto flex-shrink-0 px-3 py-1 text-sm font-medium rounded-md hover:bg-black/5 transition-colors"
      actionBtn.textContent = action // ✅ textContent 사용 (XSS 안전)
      actionBtn.setAttribute("data-action", "click->toast#action")
      container.appendChild(actionBtn)
    }

    // 닫기 버튼
    const closeBtn = document.createElement("button")
    closeBtn.type = "button"
    closeBtn.className = "flex-shrink-0 p-1 -mr-2 hover:bg-black/5 rounded transition-colors"
    closeBtn.setAttribute("data-action", "click->toast#dismiss")
    closeBtn.setAttribute("aria-label", "닫기")

    const closeSvg = document.createElementNS("http://www.w3.org/2000/svg", "svg")
    closeSvg.setAttribute("class", "w-4 h-4")
    closeSvg.setAttribute("fill", "none")
    closeSvg.setAttribute("viewBox", "0 0 24 24")
    closeSvg.setAttribute("stroke", "currentColor")
    const closePath = document.createElementNS("http://www.w3.org/2000/svg", "path")
    closePath.setAttribute("stroke-linecap", "round")
    closePath.setAttribute("stroke-linejoin", "round")
    closePath.setAttribute("stroke-width", "2")
    closePath.setAttribute("d", "M6 18L18 6M6 6l12 12")
    closeSvg.appendChild(closePath)
    closeBtn.appendChild(closeSvg)
    container.appendChild(closeBtn)

    // 진행 바
    const progressBar = document.createElement("div")
    progressBar.className = `absolute bottom-0 left-0 h-1 ${this.getProgressBarClass(variant)} toast-progress`
    progressBar.style.animation = `shrink ${duration}ms linear forwards`
    container.appendChild(progressBar)

    toast.appendChild(container)

    // ✅ 안전한 방식으로 콜백 저장
    if (onAction && typeof onAction === 'function') {
      toast._onActionCallback = onAction
    }

    return toast
  }

  /**
   * SVG 아이콘 생성 (안전한 DOM API)
   */
  createIcon(variant) {
    const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg")
    svg.setAttribute("class", `w-5 h-5 flex-shrink-0 ${this.getIconColor(variant)}`)
    svg.setAttribute("fill", "none")
    svg.setAttribute("viewBox", "0 0 24 24")
    svg.setAttribute("stroke", "currentColor")

    const path = document.createElementNS("http://www.w3.org/2000/svg", "path")
    path.setAttribute("stroke-linecap", "round")
    path.setAttribute("stroke-linejoin", "round")
    path.setAttribute("stroke-width", "2")
    path.setAttribute("d", this.getIconPath(variant))

    svg.appendChild(path)
    return svg
  }

  /**
   * Variant별 아이콘 경로
   */
  getIconPath(variant) {
    const paths = {
      success: "M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z",
      error: "M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z",
      warning: "M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z",
      info: "M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
    }
    return paths[variant] || paths.info
  }

  /**
   * Variant별 아이콘 색상
   */
  getIconColor(variant) {
    const colors = {
      success: "text-green-500",
      error: "text-red-500",
      warning: "text-yellow-600",
      info: "text-blue-500"
    }
    return colors[variant] || colors.info
  }

  /**
   * Toast 제거
   */
  removeToast(toast) {
    toast.classList.remove("toast-enter")
    toast.classList.add("toast-exit")

    setTimeout(() => {
      if (toast.parentElement) {
        toast.remove()
      }
      const index = this.toasts.indexOf(toast)
      if (index > -1) {
        this.toasts.splice(index, 1)
      }
    }, 300)
  }

  /**
   * Variant별 클래스
   */
  getToastClasses(variant) {
    const base = "toast-base rounded-lg shadow-lg border backdrop-blur-sm transition-all duration-300"
    const variants = {
      success: "bg-green-50/95 border-green-200 text-green-800",
      error: "bg-red-50/95 border-red-200 text-red-800",
      warning: "bg-yellow-50/95 border-yellow-200 text-yellow-800",
      info: "bg-blue-50/95 border-blue-200 text-blue-800"
    }
    return `${base} ${variants[variant] || variants.info}`
  }

  /**
   * 진행 바 클래스
   */
  getProgressBarClass(variant) {
    const classes = {
      success: "bg-green-500",
      error: "bg-red-500",
      warning: "bg-yellow-500",
      info: "bg-blue-500"
    }
    return classes[variant] || classes.info
  }
}

// 전역 ToastManager 인스턴스
window.ToastManager = window.ToastManager || new ToastManager()

/**
 * Toast Stimulus Controller
 */
export default class extends Controller {
  static values = {
    variant: { type: String, default: "info" },
    duration: { type: Number, default: 3000 }
  }

  connect() {
    // 자동 dismiss 타이머
    if (this.durationValue > 0) {
      this.timeout = setTimeout(() => {
        this.dismiss()
      }, this.durationValue)
    }
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  /**
   * Toast 닫기
   */
  dismiss() {
    window.ToastManager.removeToast(this.element)
  }

  /**
   * 액션 버튼 클릭
   */
  action(event) {
    event.preventDefault()

    // ✅ 안전하게 저장된 콜백 실행
    if (this.element._onActionCallback && typeof this.element._onActionCallback === 'function') {
      try {
        this.element._onActionCallback()
      } catch (e) {
        console.error("Toast action callback error:", e)
      }
    } else {
      // 커스텀 이벤트 발생 (대안적 방법)
      const actionEvent = new CustomEvent('toast:action', {
        detail: { variant: this.variantValue },
        bubbles: true
      })
      this.element.dispatchEvent(actionEvent)
    }

    this.dismiss()
  }
}

// CSS 애니메이션
const style = document.createElement('style')
style.textContent = `
  .toast-base {
    opacity: 0;
    transform: translateX(100%) scale(0.95);
  }

  .toast-enter {
    opacity: 1;
    transform: translateX(0) scale(1);
  }

  .toast-exit {
    opacity: 0;
    transform: translateX(100%) scale(0.9);
  }

  @keyframes shrink {
    from { width: 100%; }
    to { width: 0%; }
  }

  .toast-progress {
    transition: width linear;
  }

  @media (prefers-reduced-motion: reduce) {
    .toast-base, .toast-enter, .toast-exit {
      transition-duration: 0.01ms !important;
      animation-duration: 0.01ms !important;
    }
  }
`
if (!document.getElementById('toast-styles')) {
  style.id = 'toast-styles'
  document.head.appendChild(style)
}
