import { Controller } from "@hotwired/stimulus"

/**
 * Sheet (Slide Panel) Controller
 *
 * 프로덕션급 슬라이드 패널 컴포넌트
 * - 오른쪽/아래에서 슬라이드 (반응형)
 * - Backdrop blur 효과
 * - 키보드 접근성 (Escape, Tab trap)
 * - 부드러운 스프링 애니메이션
 *
 * 사용법:
 *   <div data-controller="sheet" data-sheet-side-value="right">
 *     <button data-action="sheet#open">Open Sheet</button>
 *
 *     <div data-sheet-target="backdrop" class="hidden ..."></div>
 *     <div data-sheet-target="panel" class="hidden ...">
 *       <button data-action="sheet#close">Close</button>
 *       <!-- Content -->
 *     </div>
 *   </div>
 */
export default class extends Controller {
  static targets = ["backdrop", "panel", "closeButton"]

  static values = {
    side: { type: String, default: "right" }, // "right", "left", "top", "bottom"
    closable: { type: Boolean, default: true }
  }

  static classes = [
    "backdropOpen",
    "panelOpen"
  ]

  connect() {
    this.isOpen = false
    this.originalOverflow = document.body.style.overflow
    this.focusableElements = []
    this.previousActiveElement = null

    // Escape 키 핸들러 바인딩
    this.handleEscape = this.handleEscape.bind(this)
    this.handleTab = this.handleTab.bind(this)
  }

  disconnect() {
    if (this.isOpen) {
      this.restoreBodyScroll()
      document.removeEventListener("keydown", this.handleEscape)
      document.removeEventListener("keydown", this.handleTab)
    }
  }

  /**
   * Sheet 열기
   */
  open(event) {
    if (event) event.preventDefault()
    if (this.isOpen) return

    this.isOpen = true
    this.previousActiveElement = document.activeElement

    // Body 스크롤 잠금
    this.lockBodyScroll()

    // Backdrop 표시
    if (this.hasBackdropTarget) {
      this.backdropTarget.classList.remove("hidden")
      // 다음 프레임에서 opacity 전환 (애니메이션 트리거)
      requestAnimationFrame(() => {
        this.backdropTarget.classList.add("opacity-100")
      })
    }

    // Panel 표시 (side에 따라 다른 애니메이션)
    if (this.hasPanelTarget) {
      this.panelTarget.classList.remove("hidden")
      requestAnimationFrame(() => {
        this.panelTarget.classList.add(this.getOpenClass())
      })

      // 포커스 관리
      this.trapFocus()
    }

    // 키보드 이벤트 리스너 추가
    document.addEventListener("keydown", this.handleEscape)
    document.addEventListener("keydown", this.handleTab)

    // ARIA 속성 설정
    this.panelTarget.setAttribute("aria-modal", "true")
    this.panelTarget.setAttribute("role", "dialog")
  }

  /**
   * Sheet 닫기
   */
  close(event) {
    if (event) event.preventDefault()
    if (!this.isOpen || !this.closableValue) return

    this.isOpen = false

    // Backdrop 페이드 아웃
    if (this.hasBackdropTarget) {
      this.backdropTarget.classList.remove("opacity-100")
    }

    // Panel 슬라이드 아웃
    if (this.hasPanelTarget) {
      this.panelTarget.classList.remove(this.getOpenClass())
    }

    // 애니메이션 완료 후 DOM 정리
    setTimeout(() => {
      if (this.hasBackdropTarget) {
        this.backdropTarget.classList.add("hidden")
      }
      if (this.hasPanelTarget) {
        this.panelTarget.classList.add("hidden")
        this.panelTarget.removeAttribute("aria-modal")
        this.panelTarget.removeAttribute("role")
      }

      this.restoreBodyScroll()

      // 포커스 복원
      if (this.previousActiveElement) {
        this.previousActiveElement.focus()
      }
    }, 300) // 애니메이션 duration과 일치

    // 키보드 이벤트 리스너 제거
    document.removeEventListener("keydown", this.handleEscape)
    document.removeEventListener("keydown", this.handleTab)
  }

  /**
   * Backdrop 클릭 핸들러
   */
  backdropClick(event) {
    if (this.closableValue && event.target === this.backdropTarget) {
      this.close()
    }
  }

  /**
   * Panel 내부 클릭 시 이벤트 전파 차단
   */
  stopPropagation(event) {
    event.stopPropagation()
  }

  /**
   * Escape 키 핸들러
   */
  handleEscape(event) {
    if (event.key === "Escape" && this.closableValue) {
      this.close()
    }
  }

  /**
   * Tab 키 핸들러 (포커스 트랩)
   */
  handleTab(event) {
    if (event.key !== "Tab" || !this.isOpen) return

    const focusable = this.getFocusableElements()
    if (focusable.length === 0) return

    const firstElement = focusable[0]
    const lastElement = focusable[focusable.length - 1]

    if (event.shiftKey) {
      // Shift + Tab
      if (document.activeElement === firstElement) {
        event.preventDefault()
        lastElement.focus()
      }
    } else {
      // Tab
      if (document.activeElement === lastElement) {
        event.preventDefault()
        firstElement.focus()
      }
    }
  }

  /**
   * Side 값에 따른 open 클래스 반환
   */
  getOpenClass() {
    const sideClasses = {
      right: "translate-x-0",
      left: "translate-x-0",
      top: "translate-y-0",
      bottom: "translate-y-0"
    }
    return sideClasses[this.sideValue] || sideClasses.right
  }

  /**
   * Body 스크롤 잠금
   */
  lockBodyScroll() {
    this.originalOverflow = document.body.style.overflow
    document.body.style.overflow = "hidden"
  }

  /**
   * Body 스크롤 복원
   */
  restoreBodyScroll() {
    document.body.style.overflow = this.originalOverflow
  }

  /**
   * 포커스 가능한 요소 가져오기
   */
  getFocusableElements() {
    if (!this.hasPanelTarget) return []

    const selector = [
      'button:not([disabled])',
      '[href]',
      'input:not([disabled])',
      'select:not([disabled])',
      'textarea:not([disabled])',
      '[tabindex]:not([tabindex="-1"])'
    ].join(', ')

    return Array.from(this.panelTarget.querySelectorAll(selector))
  }

  /**
   * 첫 번째 포커스 가능한 요소에 포커스
   */
  trapFocus() {
    const focusable = this.getFocusableElements()
    if (focusable.length > 0) {
      // Close 버튼이 있으면 우선 포커스
      if (this.hasCloseButtonTarget) {
        this.closeButtonTarget.focus()
      } else {
        focusable[0].focus()
      }
    }
  }
}
