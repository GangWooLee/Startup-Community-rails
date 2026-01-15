import { Controller } from "@hotwired/stimulus"

/**
 * Sidebar Collapse Controller
 *
 * 글로벌 사이드바의 접기/펼치기를 제어합니다.
 *
 * Desktop (≥768px):
 * - 펼친 상태: w-64 (256px) - 전체 정보 표시
 * - 접힌 상태: w-16 (64px) - 아이콘만 표시
 *
 * Mobile (<768px):
 * - 펼친 상태: 오버레이와 함께 전체 사이드바 표시
 * - 접힌 상태: 완전히 숨김 (hidden)
 */
export default class extends Controller {
  static targets = ["sidebar", "toggleIcon", "expandedContent", "collapsedContent"]
  static values = {
    collapsed: { type: Boolean, default: false },
    mobileOpen: { type: Boolean, default: false }
  }

  connect() {
    // 로컬 스토리지에서 상태 복원 (데스크톱 전용)
    const saved = localStorage.getItem("globalSidebarCollapsed")
    if (saved === "true") {
      this.collapsedValue = true
    }

    // 모바일 감지 및 반응형 처리
    this.boundHandleResize = this.handleResize.bind(this)
    window.addEventListener("resize", this.boundHandleResize)

    // 초기 UI 업데이트
    this.handleResize()

    // 사이드바 내 링크 클릭 시 모바일에서 자동 닫기
    this.boundHandleNavClick = this.handleNavClick.bind(this)
    if (this.hasSidebarTarget) {
      this.sidebarTarget.addEventListener("click", this.boundHandleNavClick)
    }
  }

  disconnect() {
    window.removeEventListener("resize", this.boundHandleResize)
    if (this.hasSidebarTarget) {
      this.sidebarTarget.removeEventListener("click", this.boundHandleNavClick)
    }
    this.removeOverlay()
  }

  // 현재 모바일인지 확인 (매번 계산)
  get isMobile() {
    return window.innerWidth < 768
  }

  handleResize() {
    this.updateUI()
  }

  handleNavClick(event) {
    // 모바일에서 네비게이션 링크 클릭 시 사이드바 닫기
    if (this.isMobile && event.target.closest("a")) {
      this.mobileOpenValue = false
      this.updateUI()
    }
  }

  toggle() {
    if (this.isMobile) {
      // 모바일: 열림/닫힘 토글
      this.mobileOpenValue = !this.mobileOpenValue
    } else {
      // 데스크톱: 접힘/펼침 토글
      this.collapsedValue = !this.collapsedValue
      localStorage.setItem("globalSidebarCollapsed", this.collapsedValue)
    }
    this.updateUI()
  }

  // 오버레이 클릭 시 닫기 (모바일)
  closeFromOverlay() {
    this.mobileOpenValue = false
    this.updateUI()
  }

  updateUI() {
    if (!this.hasSidebarTarget) return

    const sidebar = this.sidebarTarget

    if (this.isMobile) {
      this.updateMobileUI(sidebar)
    } else {
      this.updateDesktopUI(sidebar)
    }
  }

  updateMobileUI(sidebar) {
    // 모바일에서는 항상 펼친 스타일 사용 (w-64)
    sidebar.classList.remove("w-16", "md:flex", "md:flex-col", "hidden")
    sidebar.classList.add("w-64")

    // 항상 펼친 콘텐츠 표시
    this.expandedContentTargets.forEach(el => el.classList.remove("hidden"))
    this.collapsedContentTargets.forEach(el => el.classList.add("hidden"))

    // 슬라이드 애니메이션을 위한 기본 클래스 설정
    sidebar.classList.add(
      "fixed", "inset-y-0", "left-0", "z-50",
      "flex", "flex-col", "bg-white",
      "transition-transform", "duration-300", "ease-in-out"
    )

    if (this.mobileOpenValue) {
      // 열린 상태: 화면에 슬라이드 인
      sidebar.classList.remove("-translate-x-full")
      sidebar.classList.add("translate-x-0")
      this.createOverlay()
      document.body.classList.add("overflow-hidden")
    } else {
      // 닫힌 상태: 왼쪽으로 슬라이드 아웃
      sidebar.classList.remove("translate-x-0")
      sidebar.classList.add("-translate-x-full")
      this.removeOverlay()
      document.body.classList.remove("overflow-hidden")
    }
  }

  updateDesktopUI(sidebar) {
    // 데스크톱에서는 항상 표시 - 모바일 관련 클래스 제거
    sidebar.classList.remove(
      "hidden", "fixed", "inset-y-0", "left-0", "z-50",
      "-translate-x-full", "translate-x-0",
      "transition-transform", "duration-300", "ease-in-out"
    )
    sidebar.classList.add("md:flex", "md:flex-col", "flex")
    this.removeOverlay()
    document.body.classList.remove("overflow-hidden")

    if (this.collapsedValue) {
      // 접힌 상태: w-16 (64px) - 아이콘만 표시
      sidebar.classList.remove("w-64")
      sidebar.classList.add("w-16")

      // 텍스트 콘텐츠 숨기기
      this.expandedContentTargets.forEach(el => el.classList.add("hidden"))
      this.collapsedContentTargets.forEach(el => el.classList.remove("hidden"))

      // 토글 아이콘 회전 (화살표 방향 반전)
      if (this.hasToggleIconTarget) {
        this.toggleIconTarget.classList.add("rotate-180")
      }
    } else {
      // 펼친 상태: w-64 (256px)
      sidebar.classList.remove("w-16")
      sidebar.classList.add("w-64")

      // 텍스트 콘텐츠 표시
      this.expandedContentTargets.forEach(el => el.classList.remove("hidden"))
      this.collapsedContentTargets.forEach(el => el.classList.add("hidden"))

      // 토글 아이콘 원위치
      if (this.hasToggleIconTarget) {
        this.toggleIconTarget.classList.remove("rotate-180")
      }
    }
  }

  createOverlay() {
    if (this.overlayElement) return

    this.overlayElement = document.createElement("div")
    this.overlayElement.className = "fixed inset-0 bg-black/0 z-40 transition-colors duration-300"
    this.overlayElement.addEventListener("click", () => this.closeFromOverlay())
    document.body.appendChild(this.overlayElement)

    // 다음 프레임에서 배경색 적용 (페이드 인 트리거)
    requestAnimationFrame(() => {
      if (this.overlayElement) {
        this.overlayElement.classList.remove("bg-black/0")
        this.overlayElement.classList.add("bg-black/50")
      }
    })
  }

  removeOverlay() {
    if (this.overlayElement) {
      // 먼저 페이드 아웃
      this.overlayElement.classList.remove("bg-black/50")
      this.overlayElement.classList.add("bg-black/0")

      // 애니메이션 완료 후 제거
      const overlay = this.overlayElement
      this.overlayElement = null
      setTimeout(() => {
        overlay.remove()
      }, 300)
    }
  }
}
