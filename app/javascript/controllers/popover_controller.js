import { Controller } from "@hotwired/stimulus"

/**
 * Popover Controller
 *
 * 프로덕션급 팝오버 컴포넌트 - undrew-design 스타일
 * - 자동 위치 조정 (viewport edge detection)
 * - 화살표 포인터 (trigger 방향 지시)
 * - 외부 클릭 감지하여 닫기
 * - Escape 키 닫기
 * - 부드러운 fade + scale 애니메이션
 *
 * 사용법:
 *   <div data-controller="popover">
 *     <button data-action="click->popover#toggle">
 *       더보기
 *     </button>
 *
 *     <div data-popover-target="content" class="hidden">
 *       <!-- Popover content -->
 *     </div>
 *   </div>
 */
export default class extends Controller {
  static targets = ["content", "arrow"]

  static values = {
    placement: { type: String, default: "auto" }, // "auto", "top", "bottom", "left", "right"
    offset: { type: Number, default: 8 }, // Gap between trigger and popover
    closeOnOutsideClick: { type: Boolean, default: true }
  }

  connect() {
    this.isOpen = false
    this.triggerElement = null
    this.computedPlacement = null

    // Bind event handlers
    this.handleOutsideClick = this.handleOutsideClick.bind(this)
    this.handleEscape = this.handleEscape.bind(this)
    this.handleResize = this.handleResize.bind(this)
  }

  disconnect() {
    if (this.isOpen) {
      this.close()
    }
  }

  /**
   * Toggle popover (open/close)
   */
  toggle(event) {
    event.preventDefault()
    event.stopPropagation()

    this.triggerElement = event.currentTarget

    if (this.isOpen) {
      this.close()
    } else {
      this.open()
    }
  }

  /**
   * Open popover
   */
  open() {
    if (this.isOpen || !this.hasContentTarget) return

    this.isOpen = true

    // Show content
    this.contentTarget.classList.remove("hidden")

    // Calculate and apply position
    requestAnimationFrame(() => {
      this.calculatePosition()
      this.contentTarget.classList.add("popover-enter")
    })

    // Add event listeners
    if (this.closeOnOutsideClickValue) {
      setTimeout(() => {
        document.addEventListener("click", this.handleOutsideClick)
      }, 0)
    }
    document.addEventListener("keydown", this.handleEscape)
    window.addEventListener("resize", this.handleResize)

    // ARIA attributes
    this.contentTarget.setAttribute("aria-hidden", "false")
    if (this.triggerElement) {
      this.triggerElement.setAttribute("aria-expanded", "true")
    }
  }

  /**
   * Close popover
   */
  close() {
    if (!this.isOpen || !this.hasContentTarget) return

    this.isOpen = false

    // Fade out animation
    this.contentTarget.classList.remove("popover-enter")
    this.contentTarget.classList.add("popover-exit")

    setTimeout(() => {
      this.contentTarget.classList.add("hidden")
      this.contentTarget.classList.remove("popover-exit")
    }, 200) // Match animation duration

    // Remove event listeners
    document.removeEventListener("click", this.handleOutsideClick)
    document.removeEventListener("keydown", this.handleEscape)
    window.removeEventListener("resize", this.handleResize)

    // ARIA attributes
    this.contentTarget.setAttribute("aria-hidden", "true")
    if (this.triggerElement) {
      this.triggerElement.setAttribute("aria-expanded", "false")
    }
  }

  /**
   * Calculate optimal position based on viewport constraints
   */
  calculatePosition() {
    if (!this.triggerElement || !this.hasContentTarget) return

    const trigger = this.triggerElement.getBoundingClientRect()
    const content = this.contentTarget.getBoundingClientRect()
    const viewport = {
      width: window.innerWidth,
      height: window.innerHeight
    }

    // Determine optimal placement
    let placement = this.placementValue
    if (placement === "auto") {
      placement = this.getOptimalPlacement(trigger, content, viewport)
    }

    this.computedPlacement = placement

    // Calculate position based on placement
    const position = this.getPosition(trigger, content, placement)

    // Apply position
    this.contentTarget.style.position = "fixed"
    this.contentTarget.style.left = `${position.left}px`
    this.contentTarget.style.top = `${position.top}px`
    this.contentTarget.style.zIndex = "50"

    // Position arrow
    if (this.hasArrowTarget) {
      this.positionArrow(trigger, placement)
    }
  }

  /**
   * Determine optimal placement based on available space
   */
  getOptimalPlacement(trigger, content, viewport) {
    const spaces = {
      top: trigger.top,
      bottom: viewport.height - trigger.bottom,
      left: trigger.left,
      right: viewport.width - trigger.right
    }

    // Prefer vertical placements (top/bottom) for better UX
    const contentHeight = content.height
    const contentWidth = content.width

    if (spaces.bottom >= contentHeight + this.offsetValue) {
      return "bottom"
    } else if (spaces.top >= contentHeight + this.offsetValue) {
      return "top"
    } else if (spaces.right >= contentWidth + this.offsetValue) {
      return "right"
    } else if (spaces.left >= contentWidth + this.offsetValue) {
      return "left"
    }

    // Fallback: largest available space
    const maxSpace = Math.max(...Object.values(spaces))
    return Object.keys(spaces).find(key => spaces[key] === maxSpace)
  }

  /**
   * Calculate position coordinates
   */
  getPosition(trigger, content, placement) {
    const offset = this.offsetValue
    let left, top

    switch (placement) {
      case "top":
        left = trigger.left + (trigger.width / 2) - (content.width / 2)
        top = trigger.top - content.height - offset
        break
      case "bottom":
        left = trigger.left + (trigger.width / 2) - (content.width / 2)
        top = trigger.bottom + offset
        break
      case "left":
        left = trigger.left - content.width - offset
        top = trigger.top + (trigger.height / 2) - (content.height / 2)
        break
      case "right":
        left = trigger.right + offset
        top = trigger.top + (trigger.height / 2) - (content.height / 2)
        break
      default:
        left = trigger.left
        top = trigger.bottom + offset
    }

    // Keep within viewport bounds
    const viewport = {
      width: window.innerWidth,
      height: window.innerHeight
    }

    left = Math.max(8, Math.min(left, viewport.width - content.width - 8))
    top = Math.max(8, Math.min(top, viewport.height - content.height - 8))

    return { left, top }
  }

  /**
   * Position arrow to point at trigger
   */
  positionArrow(trigger, placement) {
    if (!this.hasArrowTarget) return

    const content = this.contentTarget.getBoundingClientRect()
    const arrowSize = 8 // Match CSS arrow size

    // Reset arrow classes
    this.arrowTarget.className = "popover-arrow absolute w-3 h-3 bg-card border-border"

    switch (placement) {
      case "top":
        this.arrowTarget.classList.add("border-b", "border-r", "bottom-[-6px]", "rotate-45")
        this.arrowTarget.style.left = `${trigger.left + (trigger.width / 2) - content.left - arrowSize}px`
        this.arrowTarget.style.top = "auto"
        break
      case "bottom":
        this.arrowTarget.classList.add("border-l", "border-t", "top-[-6px]", "rotate-45")
        this.arrowTarget.style.left = `${trigger.left + (trigger.width / 2) - content.left - arrowSize}px`
        this.arrowTarget.style.top = "auto"
        break
      case "left":
        this.arrowTarget.classList.add("border-t", "border-r", "right-[-6px]", "rotate-45")
        this.arrowTarget.style.top = `${trigger.top + (trigger.height / 2) - content.top - arrowSize}px`
        this.arrowTarget.style.left = "auto"
        break
      case "right":
        this.arrowTarget.classList.add("border-b", "border-l", "left-[-6px]", "rotate-45")
        this.arrowTarget.style.top = `${trigger.top + (trigger.height / 2) - content.top - arrowSize}px`
        this.arrowTarget.style.left = "auto"
        break
    }
  }

  /**
   * Handle outside click
   */
  handleOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  /**
   * Handle Escape key
   */
  handleEscape(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }

  /**
   * Handle window resize (recalculate position)
   */
  handleResize() {
    if (this.isOpen) {
      this.calculatePosition()
    }
  }
}

// CSS Animations
const style = document.createElement('style')
style.textContent = `
  .popover-base {
    opacity: 0;
    transform: scale(0.95);
  }

  .popover-enter {
    opacity: 1;
    transform: scale(1);
    transition: opacity 0.2s ease-out, transform 0.2s ease-out;
  }

  .popover-exit {
    opacity: 0;
    transform: scale(0.95);
    transition: opacity 0.15s ease-in, transform 0.15s ease-in;
  }

  .popover-arrow {
    filter: drop-shadow(0 1px 2px rgba(0, 0, 0, 0.1));
  }

  @media (prefers-reduced-motion: reduce) {
    .popover-enter, .popover-exit {
      transition-duration: 0.01ms !important;
    }
  }
`
if (!document.getElementById('popover-styles')) {
  style.id = 'popover-styles'
  document.head.appendChild(style)
}
