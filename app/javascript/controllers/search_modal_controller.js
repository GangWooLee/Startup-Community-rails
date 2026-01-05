import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

/**
 * Crystal Lens Command Palette Controller
 *
 * Linear/Raycast/Notion 스타일의 몰입형 검색 모달을 제어합니다.
 * Phase 18: Premium Command Palette 리디자인
 *
 * 주요 기능:
 * - Cmd+K / Ctrl+K 단축키로 열기
 * - ESC로 닫기
 * - 200ms 디바운스 검색
 * - Turbo Frame으로 결과 업데이트 (XSS 방지)
 * - 화살표 키 네비게이션 (ArrowUp/ArrowDown)
 * - Enter로 선택
 * - 쫀득한 등장/퇴장 애니메이션
 */
export default class extends Controller {
  static targets = ["overlay", "modal", "input", "resultsFrame", "loading", "recentSearches", "recentSearchList", "searchIcon", "resultItem"]
  static values = {
    open: Boolean,
    selectedIndex: { type: Number, default: -1 },
    previousQuery: String,        // Drill-down 복귀용
    isDrilldown: Boolean          // Drill-down 상태 추적
  }

  connect() {
    // Cmd+K / Ctrl+K 단축키 등록
    this.boundHandleKeydown = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this.boundHandleKeydown)

    // 디바운스 타이머
    this.debounceTimer = null
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundHandleKeydown)
    if (this.debounceTimer) clearTimeout(this.debounceTimer)
  }

  // Cmd+K / Ctrl+K 단축키
  handleKeydown(event) {
    // Cmd+K (Mac) 또는 Ctrl+K (Windows/Linux)
    if ((event.metaKey || event.ctrlKey) && event.key === "k") {
      event.preventDefault()
      this.toggle()
      return
    }

    // ESC로 닫기
    if (event.key === "Escape" && this.openValue) {
      event.preventDefault()
      this.close()
    }
  }

  // 모달 열기 - Crystal Lens 애니메이션
  open() {
    this.openValue = true
    this.selectedIndexValue = -1  // 선택 초기화

    // 오버레이 표시
    this.overlayTarget.classList.remove("hidden")

    // 쫀득한 등장 애니메이션
    requestAnimationFrame(() => {
      this.overlayTarget.classList.remove("opacity-0")
      this.modalTarget.classList.remove("opacity-0", "animate-modal-dismiss")
      this.modalTarget.classList.add("animate-modal-emerge")
    })

    // 입력창 포커스 (애니메이션 완료 후)
    setTimeout(() => this.inputTarget.focus(), 150)

    // 스크롤 방지
    document.body.style.overflow = "hidden"

    // 최근 검색어 동적 렌더링 (쿠키 기반)
    this.renderRecentSearches()

    // 최근 검색 표시
    this.showRecentSearches()
  }

  // 모달 닫기 - Crystal Lens 퇴장 애니메이션
  close() {
    this.openValue = false
    this.selectedIndexValue = -1  // 선택 초기화
    this.isDrilldownValue = false // Drill-down 상태 초기화
    this.previousQueryValue = ""  // 이전 쿼리 초기화

    // 쫀득한 퇴장 애니메이션
    this.overlayTarget.classList.add("opacity-0")
    this.modalTarget.classList.remove("animate-modal-emerge")
    this.modalTarget.classList.add("animate-modal-dismiss")

    // 애니메이션 완료 후 숨기기 (150ms)
    setTimeout(() => {
      this.overlayTarget.classList.add("hidden")
      this.modalTarget.classList.remove("animate-modal-dismiss")
      this.modalTarget.classList.add("opacity-0")
    }, 150)

    // 입력 초기화
    this.inputTarget.value = ""

    // Turbo Frame 초기화 (src 제거)
    if (this.hasResultsFrameTarget) {
      this.resultsFrameTarget.src = ""
    }

    // 스크롤 복원
    document.body.style.overflow = ""
  }

  // 토글
  toggle() {
    this.openValue ? this.close() : this.open()
  }

  // 오버레이 클릭 시 닫기 (Task 91)
  closeOnOverlay(event) {
    // 모달 내부 클릭은 무시 - 모달 요소 또는 그 자식인지 확인
    // 오버레이 내부의 flex 컨테이너를 클릭해도 닫히도록 개선
    if (this.hasModalTarget && !this.modalTarget.contains(event.target)) {
      this.close()
    }
  }

  // 검색 입력 (디바운스 200ms)
  search(event) {
    const query = event.target.value.trim()

    // 빈 쿼리면 최근 검색 표시
    if (!query) {
      this.showRecentSearches()
      this.hideLoading()
      // Turbo Frame 비우기 - src와 innerHTML 모두 초기화
      if (this.hasResultsFrameTarget) {
        this.resultsFrameTarget.src = ""
        this.resultsFrameTarget.innerHTML = ""
      }
      return
    }

    // 디바운스
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer)
    }

    this.debounceTimer = setTimeout(() => {
      this.performSearch(query)
    }, 200)
  }

  // 실제 검색 수행 - Turbo Frame 사용
  performSearch(query) {
    this.showLoading()
    this.hideRecentSearches()

    // Turbo Frame의 src를 변경하여 서버에서 렌더링된 HTML을 안전하게 로드
    if (this.hasResultsFrameTarget) {
      const searchUrl = `/search?q=${encodeURIComponent(query)}&modal=true`
      this.resultsFrameTarget.src = searchUrl
    }
  }

  // Turbo Frame 로드 완료 시 로딩 숨기기
  frameLoaded() {
    this.hideLoading()
  }

  // Turbo Frame 로드 에러 시
  frameError() {
    this.hideLoading()
  }

  // 최근 검색 표시
  showRecentSearches() {
    if (this.hasRecentSearchesTarget) {
      this.recentSearchesTarget.classList.remove("hidden")
    }
  }

  // 최근 검색 숨기기
  hideRecentSearches() {
    if (this.hasRecentSearchesTarget) {
      this.recentSearchesTarget.classList.add("hidden")
    }
  }

  // 로딩 표시
  showLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.remove("hidden")
    }
  }

  // 로딩 숨기기
  hideLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.add("hidden")
    }
  }

  // 최근 검색어 선택
  selectRecent(event) {
    const term = event.currentTarget.dataset.term
    if (term) {
      this.inputTarget.value = term
      this.performSearch(term)
    }
  }

  // 결과 클릭 시 모달 닫고 해당 페이지로 이동
  resultClick(event) {
    event.preventDefault()
    const href = event.currentTarget.getAttribute("href")
    this.close()

    // 모달 닫힌 후 페이지 이동
    if (href) {
      setTimeout(() => Turbo.visit(href), 100)
    }
  }

  // ============================================================
  // Task 56-59: Drill-down 기능 (모달 내 계층 전환)
  // ============================================================

  // Drill-down 진입 - "모두 보기" 클릭 시
  drillDown(event) {
    // ⭐ Task 85: pending search를 취소하여 drilldown을 방해하지 않도록 함
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer)
      this.debounceTimer = null
    }

    // 현재 검색어 저장 (뒤로가기용)
    this.previousQueryValue = this.inputTarget.value
    this.isDrilldownValue = true

    // Turbo Frame이 자동으로 내용 교체
    // 슬라이드 애니메이션은 CSS로 처리
  }

  // Drill-down에서 복귀 - 뒤로가기 클릭 시
  goBack(event) {
    event.preventDefault()
    this.isDrilldownValue = false

    // 이전 검색 결과로 복귀
    if (this.previousQueryValue) {
      this.performSearch(this.previousQueryValue)
    }
  }

  // ============================================================
  // Task 52: 쿠키 기반 최근 검색 기능
  // ============================================================

  // 쿠키에서 최근 검색어 로드
  loadRecentSearches() {
    try {
      const cookieValue = this.getCookie("recent_searches")
      if (cookieValue) {
        return JSON.parse(decodeURIComponent(cookieValue))
      }
    } catch (e) {
      console.error("Failed to parse recent searches:", e)
    }
    return []
  }

  // 쿠키 값 가져오기 헬퍼
  getCookie(name) {
    const value = `; ${document.cookie}`
    const parts = value.split(`; ${name}=`)
    if (parts.length === 2) return parts.pop().split(";").shift()
    return null
  }

  // 최근 검색어 동적 렌더링
  renderRecentSearches() {
    if (!this.hasRecentSearchListTarget) return

    const searches = this.loadRecentSearches()
    const container = this.recentSearchListTarget

    // 기존 콘텐츠 제거
    container.innerHTML = ""

    if (searches.length === 0) {
      container.innerHTML = '<p class="px-3 py-2 text-sm text-stone-400">최근 검색 내역이 없습니다</p>'
      return
    }

    // 동적으로 버튼 생성 (최대 5개) - Crystal Lens 스타일
    searches.slice(0, 5).forEach(term => {
      const button = document.createElement("button")
      button.type = "button"
      button.dataset.action = "click->search-modal#selectRecent"
      button.dataset.searchModalTarget = "resultItem"
      button.dataset.term = term
      button.tabIndex = 0
      button.className = "w-full flex items-center gap-3 px-3 py-2.5 text-left rounded-xl hover:bg-orange-50/50 focus:bg-orange-50/50 hover:ring-1 focus:ring-1 hover:ring-orange-200/50 focus:ring-orange-200/50 transition-all duration-150 group outline-none"

      // XSS 방지: textContent 사용
      const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg")
      svg.setAttribute("class", "w-4 h-4 text-stone-300 group-hover:text-orange-400")
      svg.setAttribute("fill", "none")
      svg.setAttribute("stroke", "currentColor")
      svg.setAttribute("viewBox", "0 0 24 24")
      const path = document.createElementNS("http://www.w3.org/2000/svg", "path")
      path.setAttribute("stroke-linecap", "round")
      path.setAttribute("stroke-linejoin", "round")
      path.setAttribute("stroke-width", "2")
      path.setAttribute("d", "M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z")
      svg.appendChild(path)

      const span = document.createElement("span")
      span.className = "text-sm text-stone-600 group-hover:text-stone-900"
      span.textContent = term  // XSS 방지

      button.appendChild(svg)
      button.appendChild(span)
      container.appendChild(button)
    })
  }

  // ============================================================
  // Phase 18: Crystal Lens - Keyboard Navigation
  // ============================================================

  // 아래 화살표 키 - 다음 아이템 선택
  navigateDown(event) {
    event.preventDefault()
    const items = this.resultItemTargets
    if (!items.length) return

    this.selectedIndexValue = Math.min(this.selectedIndexValue + 1, items.length - 1)
  }

  // 위 화살표 키 - 이전 아이템 선택
  navigateUp(event) {
    event.preventDefault()
    const items = this.resultItemTargets
    if (!items.length) return

    if (this.selectedIndexValue <= 0) {
      this.selectedIndexValue = -1
      this.inputTarget.focus()
    } else {
      this.selectedIndexValue = this.selectedIndexValue - 1
    }
  }

  // Enter 키 - 현재 선택 아이템 클릭
  selectCurrent(event) {
    const items = this.resultItemTargets
    if (this.selectedIndexValue >= 0 && items[this.selectedIndexValue]) {
      event.preventDefault()
      items[this.selectedIndexValue].click()
    }
  }

  // 선택 인덱스 변경 시 UI 업데이트 (Stimulus Value Changed Callback)
  selectedIndexValueChanged() {
    const items = this.resultItemTargets
    items.forEach((item, index) => {
      const isSelected = index === this.selectedIndexValue

      // 선택된 아이템 하이라이트
      item.classList.toggle("bg-orange-50/50", isSelected)
      item.classList.toggle("ring-1", isSelected)
      item.classList.toggle("ring-orange-200/50", isSelected)

      // 선택된 아이템으로 스크롤
      if (isSelected) {
        item.scrollIntoView({ block: "nearest", behavior: "smooth" })
      }
    })
  }
}
