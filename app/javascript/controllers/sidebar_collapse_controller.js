import { Controller } from "@hotwired/stimulus"

/**
 * Sidebar Controller - 데스크톱/모바일 분리 방식
 *
 * 데스크톱: w-64 ↔ w-16 레이아웃 내 너비 변경 (콘텐츠 밀림)
 * 모바일: 완전히 숨김 ↔ 오버레이로 열림 (콘텐츠 밀림 없음)
 */
export default class extends Controller {
  static targets = ["sidebar", "expandedContent", "collapsedContent", "toggleIcon"]
  static values = {
    collapsed: { type: Boolean, default: false },   // 데스크톱: 접힘 상태
    mobileOpen: { type: Boolean, default: false }   // 모바일: 열림 상태
  }

  connect() {
    // 사이드바 내 링크 클릭 시 자동 닫기 (모바일 전용)
    this.boundHandleNavClick = this.handleNavClick.bind(this)
    if (this.hasSidebarTarget) {
      this.sidebarTarget.addEventListener("click", this.boundHandleNavClick)
    }

    // 화면 크기 변경 감지
    this.boundHandleResize = this.handleResize.bind(this)
    window.addEventListener("resize", this.boundHandleResize)

    // localStorage에서 데스크톱 상태 복원
    const savedCollapsed = localStorage.getItem("globalSidebarCollapsed")
    if (savedCollapsed !== null) {
      this.collapsedValue = savedCollapsed === "true"
    }

    // 초기 UI 설정
    this.updateUI()
  }

  disconnect() {
    if (this.hasSidebarTarget) {
      this.sidebarTarget.removeEventListener("click", this.boundHandleNavClick)
    }
    window.removeEventListener("resize", this.boundHandleResize)
    this.removeOverlay()
  }

  handleNavClick(event) {
    // 모바일에서만 링크 클릭 시 사이드바 닫기
    if (this.isMobile && event.target.closest("a")) {
      this.mobileOpenValue = false
      this.updateUI()
    }
  }

  handleResize() {
    // 화면 크기 변경 시 UI 업데이트
    this.updateUI()
  }

  get isMobile() {
    return window.innerWidth < 768
  }

  /**
   * 토글 - 화면 크기에 따라 다른 동작
   */
  toggle() {
    if (this.isMobile) {
      this.mobileOpenValue = !this.mobileOpenValue
    } else {
      this.collapsedValue = !this.collapsedValue
      localStorage.setItem("globalSidebarCollapsed", this.collapsedValue)
    }
    this.updateUI()
  }

  /**
   * 닫기 - 화면 크기에 따라 다른 동작
   */
  close() {
    if (this.isMobile) {
      this.mobileOpenValue = false
    } else {
      this.collapsedValue = true
      localStorage.setItem("globalSidebarCollapsed", this.collapsedValue)
    }
    this.updateUI()
  }

  /**
   * 열기 - 화면 크기에 따라 다른 동작
   */
  open() {
    if (this.isMobile) {
      this.mobileOpenValue = true
    } else {
      this.collapsedValue = false
      localStorage.setItem("globalSidebarCollapsed", this.collapsedValue)
    }
    this.updateUI()
  }

  updateUI() {
    if (!this.hasSidebarTarget) return

    if (this.isMobile) {
      this.updateMobileUI()
    } else {
      this.updateDesktopUI()
    }
  }

  /**
   * 모바일: 완전히 숨김 ↔ 오버레이로 열림 (콘텐츠 밀림 없음)
   */
  updateMobileUI() {
    const sidebar = this.sidebarTarget

    // 모바일에서는 fixed 포지션 (레이아웃 밖)
    sidebar.classList.remove(
      "relative", "w-16", "md:w-16"
    )
    sidebar.classList.add(
      "fixed", "inset-y-0", "left-0", "z-50",
      "w-64", "flex", "flex-col", "bg-white",
      "transition-transform", "duration-300", "ease-in-out",
      "shadow-xl", "border-r", "border-stone-200/60"
    )

    if (this.mobileOpenValue) {
      // 열린 상태: 슬라이드 인
      sidebar.classList.remove("hidden", "-translate-x-full")
      sidebar.classList.add("translate-x-0")
      this.showExpandedContent()
      this.updateToggleIcon(false)  // '<<' 아이콘 (닫기 방향)
      this.createOverlay()
      document.body.classList.add("overflow-hidden")
    } else {
      // 닫힌 상태: 슬라이드 아웃 & 숨김
      sidebar.classList.remove("translate-x-0")
      sidebar.classList.add("hidden", "-translate-x-full")
      this.removeOverlay()
      document.body.classList.remove("overflow-hidden")
    }
  }

  /**
   * 데스크톱: w-64 ↔ w-16 레이아웃 내 너비 변경 (콘텐츠 밀림)
   */
  updateDesktopUI() {
    const sidebar = this.sidebarTarget

    // 데스크톱에서는 relative 포지션 (레이아웃 내)
    sidebar.classList.remove(
      "hidden", "-translate-x-full", "translate-x-0",
      "fixed", "inset-y-0", "left-0", "shadow-xl", "z-50"
    )
    sidebar.classList.add(
      "relative", "flex", "flex-col", "bg-white",
      "border-r", "border-stone-200/60", "h-screen",
      "transition-all", "duration-300", "ease-in-out"
    )

    // 오버레이 제거 (데스크톱은 오버레이 없음)
    this.removeOverlay()

    if (this.collapsedValue) {
      // 접힌 상태: w-16
      sidebar.classList.remove("w-64")
      sidebar.classList.add("w-16")
      this.showCollapsedContent()
      this.updateToggleIcon(true)
    } else {
      // 펼친 상태: w-64
      sidebar.classList.remove("w-16", "md:w-16")
      sidebar.classList.add("w-64")
      this.showExpandedContent()
      this.updateToggleIcon(false)
    }
  }

  /**
   * 펼친 콘텐츠 표시 (아이콘 + 텍스트)
   */
  showExpandedContent() {
    this.expandedContentTargets.forEach(el => {
      el.classList.remove("hidden")
      el.classList.add("flex")
    })
    this.collapsedContentTargets.forEach(el => {
      el.classList.add("hidden")
      el.classList.remove("flex")
    })
  }

  /**
   * 접힌 콘텐츠 표시 (아이콘만)
   */
  showCollapsedContent() {
    this.expandedContentTargets.forEach(el => {
      el.classList.add("hidden")
      el.classList.remove("flex")
    })
    this.collapsedContentTargets.forEach(el => {
      el.classList.remove("hidden")
      el.classList.add("flex")
    })
  }

  /**
   * 토글 아이콘 회전 (데스크톱용)
   */
  updateToggleIcon(collapsed) {
    if (!this.hasToggleIconTarget) return

    if (collapsed) {
      this.toggleIconTarget.classList.add("rotate-180")
    } else {
      this.toggleIconTarget.classList.remove("rotate-180")
    }
  }

  /**
   * 오버레이 생성 (모바일 전용)
   */
  createOverlay() {
    if (this.overlayElement) return

    this.overlayElement = document.createElement("div")
    this.overlayElement.className = "fixed inset-0 bg-black/0 z-40 transition-colors duration-300"
    this.overlayElement.addEventListener("click", () => this.close())
    document.body.appendChild(this.overlayElement)

    // 다음 프레임에서 배경색 적용 (페이드 인)
    requestAnimationFrame(() => {
      if (this.overlayElement) {
        this.overlayElement.classList.remove("bg-black/0")
        this.overlayElement.classList.add("bg-black/50")
      }
    })
  }

  /**
   * 오버레이 제거
   */
  removeOverlay() {
    if (this.overlayElement) {
      // 페이드 아웃
      this.overlayElement.classList.remove("bg-black/50")
      this.overlayElement.classList.add("bg-black/0")

      // 애니메이션 완료 후 제거
      const overlay = this.overlayElement
      this.overlayElement = null
      setTimeout(() => {
        overlay.remove()
      }, 300)
    }
    document.body.classList.remove("overflow-hidden")
  }
}
