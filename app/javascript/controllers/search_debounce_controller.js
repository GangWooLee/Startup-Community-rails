import { Controller } from "@hotwired/stimulus"

// Debounce된 검색 폼 제출을 위한 컨트롤러
// 채팅 검색에서 영구적 포커스 유지 기능 포함 (Task 84, 89)
// Task 89: sessionStorage 기반 상태 영속화 - Turbo Frame 교체 후에도 포커스 유지
export default class extends Controller {
  static targets = ["input"]

  // sessionStorage 키 상수
  static STORAGE_KEYS = {
    maintainFocus: 'chat_search_maintain_focus',
    savedValue: 'chat_search_saved_value',
    cursorStart: 'chat_search_cursor_start',
    cursorEnd: 'chat_search_cursor_end'
  }

  connect() {
    this.timeout = null

    // ⭐ Task 89: sessionStorage에서 포커스 상태 복원
    // Turbo Frame 교체로 컨트롤러가 재생성되어도 상태 유지
    const keys = this.constructor.STORAGE_KEYS
    this.shouldMaintainFocus = sessionStorage.getItem(keys.maintainFocus) === 'true'
    this.savedValue = sessionStorage.getItem(keys.savedValue)
    this.savedSelectionStart = parseInt(sessionStorage.getItem(keys.cursorStart)) || 0
    this.savedSelectionEnd = parseInt(sessionStorage.getItem(keys.cursorEnd)) || 0

    // Turbo 프레임 로드 후 포커스 복원
    this.boundRestoreFocus = this.restoreFocus.bind(this)
    document.addEventListener("turbo:frame-load", this.boundRestoreFocus)

    // 외부 클릭 감지 (포커스 유지 해제)
    this.boundHandleOutsideClick = this.handleOutsideClick.bind(this)
    document.addEventListener("mousedown", this.boundHandleOutsideClick)

    // ⭐ Task 89: 컨트롤러 재연결 시 즉시 포커스 복원 시도
    // sessionStorage에서 shouldMaintainFocus가 true로 복원된 경우
    if (this.shouldMaintainFocus) {
      requestAnimationFrame(() => this.restoreFocus())
    }
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
    document.removeEventListener("turbo:frame-load", this.boundRestoreFocus)
    document.removeEventListener("mousedown", this.boundHandleOutsideClick)
  }

  // 입력 시작 시 포커스 유지 활성화
  activateFocusMaintenance(event) {
    this.shouldMaintainFocus = true
    // ⭐ Task 89: sessionStorage에도 저장
    sessionStorage.setItem(this.constructor.STORAGE_KEYS.maintainFocus, 'true')
  }

  search(event) {
    const keys = this.constructor.STORAGE_KEYS
    this.shouldMaintainFocus = true  // 검색 중에는 포커스 유지

    // 현재 커서 위치와 값 저장
    this.savedValue = event.target.value
    this.savedSelectionStart = event.target.selectionStart
    this.savedSelectionEnd = event.target.selectionEnd

    // ⭐ Task 89: sessionStorage에 상태 저장 (컨트롤러 재생성 후 복원용)
    sessionStorage.setItem(keys.maintainFocus, 'true')
    sessionStorage.setItem(keys.savedValue, this.savedValue)
    sessionStorage.setItem(keys.cursorStart, this.savedSelectionStart.toString())
    sessionStorage.setItem(keys.cursorEnd, this.savedSelectionEnd.toString())

    // 기존 타임아웃 취소
    if (this.timeout) {
      clearTimeout(this.timeout)
    }

    // 300ms 후 폼 제출
    this.timeout = setTimeout(() => {
      this.element.requestSubmit()
    }, 300)
  }

  // 외부 클릭 시 포커스 유지 해제
  handleOutsideClick(event) {
    // ⭐ Task 87: document 레벨에서 검색 폼 찾기 (this.element가 DOM에서 제거될 수 있음)
    const searchForm = document.querySelector('[data-controller="search-debounce"]')
    const searchInput = document.querySelector('#chat_search_input') ||
                        document.querySelector('input[name="search"]')

    // 검색 폼 외부를 클릭한 경우에만 포커스 유지 해제
    if (searchInput && searchForm && !searchForm.contains(event.target)) {
      this.shouldMaintainFocus = false

      // ⭐ Task 89: sessionStorage도 클리어
      const keys = this.constructor.STORAGE_KEYS
      sessionStorage.removeItem(keys.maintainFocus)
      sessionStorage.removeItem(keys.savedValue)
      sessionStorage.removeItem(keys.cursorStart)
      sessionStorage.removeItem(keys.cursorEnd)
    }
  }

  restoreFocus() {
    // 포커스 유지가 활성화된 경우에만 복원
    if (!this.shouldMaintainFocus) return

    // ⭐ Task 87 핵심 수정: document 레벨 셀렉터로 NEW DOM에서 input 찾기
    // 이전: this.element.querySelector() - Turbo Frame 교체 후 실패
    // 이후: document.querySelector() - 새로 렌더된 DOM에서 찾음
    const searchInput = document.querySelector('#chat_search_input') ||
                        document.querySelector('input[name="search"]') ||
                        document.querySelector('[data-controller="search-debounce"] input[type="text"]')

    if (searchInput) {
      // ⭐ Task 89: sessionStorage에서 폴백 값 가져오기
      const keys = this.constructor.STORAGE_KEYS
      const savedValue = this.savedValue || sessionStorage.getItem(keys.savedValue)
      const cursorStart = this.savedSelectionStart || parseInt(sessionStorage.getItem(keys.cursorStart)) || 0
      const cursorEnd = this.savedSelectionEnd || parseInt(sessionStorage.getItem(keys.cursorEnd)) || 0

      // 약간의 지연 후 포커스 복원 (DOM 업데이트 완료 대기)
      requestAnimationFrame(() => {
        searchInput.focus()

        // 커서 위치 복원 (값이 같은 경우)
        if (savedValue && searchInput.value === savedValue) {
          searchInput.setSelectionRange(cursorStart, cursorEnd)
        } else {
          // 값이 다르면 끝으로 커서 이동
          searchInput.setSelectionRange(searchInput.value.length, searchInput.value.length)
        }
      })
    }
  }
}
