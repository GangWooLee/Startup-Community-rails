import { Controller } from "@hotwired/stimulus"

/**
 * Sidebar Collapse Controller
 *
 * 글로벌 사이드바의 접기/펼치기를 제어합니다.
 * - 펼친 상태: w-64 (256px) - 전체 정보 표시
 * - 접힌 상태: w-16 (64px) - 아이콘만 표시
 *
 * Usage:
 *   <div data-controller="sidebar-collapse">
 *     <aside data-sidebar-collapse-target="sidebar">...</aside>
 *     <button data-action="click->sidebar-collapse#toggle">Toggle</button>
 *   </div>
 */
export default class extends Controller {
  static targets = ["sidebar", "toggleIcon", "expandedContent", "collapsedContent"]
  static values = { collapsed: { type: Boolean, default: false } }

  connect() {
    // 로컬 스토리지에서 상태 복원
    const saved = localStorage.getItem("globalSidebarCollapsed")
    if (saved === "true") {
      this.collapsedValue = true
    }
    this.updateUI()
  }

  toggle() {
    this.collapsedValue = !this.collapsedValue
    this.updateUI()
    localStorage.setItem("globalSidebarCollapsed", this.collapsedValue)
  }

  updateUI() {
    if (!this.hasSidebarTarget) return

    const sidebar = this.sidebarTarget

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
}
