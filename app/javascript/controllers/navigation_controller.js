import { Controller } from "@hotwired/stimulus"

/**
 * Smart Hybrid Navigation Controller
 *
 * 진입 경로에 따라 적응적으로 동작하는 스마트 뒤로가기:
 * - 내부 네비게이션: 스택 기반 + 스크롤 위치 복원
 * - 외부 진입 + referrer: history.back() (Chronological)
 * - 외부 진입 + referrer 없음: hierarchicalFallback (Hierarchical)
 *
 * 사용법:
 * 1. 뒤로가기 버튼: data-controller="navigation" data-action="click->navigation#goBack"
 * 2. fallback 지정: data-navigation-fallback-value="/settings"
 * 3. 계층적 fallback: data-navigation-hierarchical-fallback-value="/community"
 * 4. 스택 리셋 (메인 진입점): data-navigation-reset-on-connect-value="true"
 */
export default class extends Controller {
  // 스택 크기 제한 (sessionStorage 용량 관리)
  static MAX_STACK_SIZE = 50

  static values = {
    fallback: { type: String, default: "/" },
    hierarchicalFallback: { type: String, default: null },  // 계층적 상위 페이지
    resetOnConnect: { type: Boolean, default: false }
  }

  connect() {
    // 메인 진입점에서는 스택 리셋
    if (this.resetOnConnectValue) {
      this.resetStack()
    }

    // 스크롤 복원 중복 방지 플래그
    this.pendingScrollRestore = false

    // 이벤트 리스너 등록
    this.boundTrackNavigation = this.trackNavigation.bind(this)
    this.boundSaveScroll = this.saveScrollPosition.bind(this)

    document.addEventListener("turbo:visit", this.boundTrackNavigation)
    document.addEventListener("turbo:before-visit", this.boundSaveScroll)

    // 내부 네비게이션 플래그 설정 (앱 내 탐색 중임을 표시)
    sessionStorage.setItem('internalNav', 'true')

    // 초기 페이지 기록
    this.pushCurrentPage()
  }

  disconnect() {
    document.removeEventListener("turbo:visit", this.boundTrackNavigation)
    document.removeEventListener("turbo:before-visit", this.boundSaveScroll)
  }

  // ==========================================================================
  // Smart Back: 핵심 메서드
  // ==========================================================================

  /**
   * 스마트 뒤로가기
   * 진입 경로에 따라 다르게 동작
   */
  goBack(event) {
    event.preventDefault()

    if (this.isInternalNavigation()) {
      this.goBackInternal()
    } else {
      this.goBackExternal()
    }
  }

  /**
   * 내부 네비게이션 여부 판단
   * - 조건 1: navStack에 2개 이상 항목 (확실한 내부 네비게이션)
   * - 조건 2: referrer가 같은 도메인
   * - 조건 3: internalNav 플래그 + 스택 1개 이상
   */
  isInternalNavigation() {
    const stack = this.getStack()

    // 조건 1: 스택에 2개 이상 (현재 + 이전)
    if (stack.length >= 2) return true

    // 조건 2: 같은 도메인 referrer
    if (document.referrer) {
      try {
        const referrerUrl = new URL(document.referrer)
        if (referrerUrl.host === window.location.host) return true
      } catch {
        // URL 파싱 실패 시 무시
      }
    }

    // 조건 3: 내부 네비게이션 플래그 + 스택 1개 이상
    if (sessionStorage.getItem('internalNav') === 'true' && stack.length >= 1) {
      return true
    }

    return false
  }

  /**
   * 내부 네비게이션 뒤로가기
   * 스택 기반 이동 + 스크롤 위치 복원
   */
  goBackInternal() {
    const stack = this.getStack()
    stack.pop()  // 현재 페이지 제거

    if (stack.length > 0) {
      const previousPage = stack[stack.length - 1]
      this.saveStack(stack)
      this.restoreScrollPosition(previousPage)
      Turbo.visit(previousPage)
    } else {
      // 스택이 비면 계층적 상위 또는 fallback으로 이동
      this.saveStack([])
      const target = this.hierarchicalFallbackValue || this.fallbackValue
      Turbo.visit(target)
    }
  }

  /**
   * 외부 진입 뒤로가기
   * history.back() 또는 계층적 상위 페이지로 이동
   */
  goBackExternal() {
    // history.length > 1 && referrer 있음: 이전 사이트로 돌아감 (Chronological)
    if (window.history.length > 1 && document.referrer) {
      window.history.back()
    } else {
      // 히스토리 없음: 계층적 상위 페이지로 이동 (Hierarchical)
      const target = this.hierarchicalFallbackValue || this.fallbackValue
      Turbo.visit(target)
    }
  }

  // ==========================================================================
  // 스크롤 위치 관리
  // ==========================================================================

  /**
   * 스크롤 위치 저장
   * turbo:before-visit 이벤트에서 호출
   */
  saveScrollPosition() {
    try {
      const positions = JSON.parse(sessionStorage.getItem('scrollPositions') || '{}')
      positions[window.location.pathname] = window.scrollY
      sessionStorage.setItem('scrollPositions', JSON.stringify(positions))
    } catch {
      // sessionStorage 오류 시 무시
    }
  }

  /**
   * 스크롤 위치 복원
   * 뒤로가기 시 turbo:render 후 실행
   * 연속 호출 시 리스너 누적 방지
   */
  restoreScrollPosition(path) {
    // 이미 대기 중인 복원이 있으면 스킵 (리스너 누적 방지)
    if (this.pendingScrollRestore) return

    try {
      const positions = JSON.parse(sessionStorage.getItem('scrollPositions') || '{}')
      const savedPosition = positions[path]

      if (savedPosition !== undefined) {
        this.pendingScrollRestore = true

        // Turbo 렌더링 완료 후 스크롤 복원
        document.addEventListener('turbo:render', () => {
          requestAnimationFrame(() => {
            window.scrollTo({ top: savedPosition, behavior: 'instant' })
            this.pendingScrollRestore = false
          })
        }, { once: true })
      }
    } catch {
      // JSON 파싱 오류 시 무시
    }
  }

  // ==========================================================================
  // 네비게이션 스택 관리
  // ==========================================================================

  /**
   * Turbo 네비게이션 추적
   * turbo:visit 이벤트 발생 시 현재 페이지를 스택에 추가
   */
  trackNavigation(event) {
    const url = new URL(event.detail.url)
    const path = url.pathname
    const stack = this.getStack()

    // 중복 방지: 마지막 페이지와 같으면 추가 안 함
    if (stack[stack.length - 1] !== path) {
      stack.push(path)
      this.saveStack(stack)
    }
  }

  /**
   * 현재 페이지를 스택에 추가
   */
  pushCurrentPage() {
    const stack = this.getStack()
    const currentPath = window.location.pathname

    // 중복 방지: 마지막 페이지와 같으면 추가 안 함
    if (stack[stack.length - 1] !== currentPath) {
      stack.push(currentPath)
      this.saveStack(stack)
    }
  }

  /**
   * 스택 가져오기
   */
  getStack() {
    try {
      return JSON.parse(sessionStorage.getItem('navStack')) || []
    } catch {
      return []
    }
  }

  /**
   * 스택 저장
   * MAX_STACK_SIZE 초과 시 오래된 항목 제거
   */
  saveStack(stack) {
    try {
      // 스택 크기 제한 (sessionStorage 용량 관리)
      while (stack.length > this.constructor.MAX_STACK_SIZE) {
        stack.shift()  // 가장 오래된 항목 제거
      }
      sessionStorage.setItem('navStack', JSON.stringify(stack))

      // 스크롤 위치도 정리
      this.cleanupScrollPositions(stack)
    } catch {
      // sessionStorage 오류 시 무시
    }
  }

  /**
   * 스크롤 위치 정리
   * 스택에 없는 페이지의 스크롤 위치 제거 (메모리 관리)
   */
  cleanupScrollPositions(stack) {
    try {
      const positions = JSON.parse(sessionStorage.getItem('scrollPositions') || '{}')
      const cleanedPositions = {}

      // 현재 스택에 있는 페이지만 유지
      for (const path of stack) {
        if (positions[path] !== undefined) {
          cleanedPositions[path] = positions[path]
        }
      }

      sessionStorage.setItem('scrollPositions', JSON.stringify(cleanedPositions))
    } catch {
      // 오류 시 무시
    }
  }

  /**
   * 스택 초기화 (메인 진입점에서 호출)
   * Bottom Nav 페이지(커뮤니티, 외주, 채팅, 마이페이지)에서 호출하여 스택 리셋
   */
  resetStack() {
    sessionStorage.removeItem('navStack')
  }
}
