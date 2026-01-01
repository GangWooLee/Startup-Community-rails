import { Controller } from "@hotwired/stimulus"

/**
 * Stack 기반 네비게이션 컨트롤러
 *
 * 브라우저 히스토리(history.back()) 대신 애플리케이션 수준의 네비게이션 스택을 관리하여
 * 진입 경로에 따라 논리적으로 뒤로가기 동작
 *
 * 사용법:
 * 1. 뒤로가기 버튼: data-controller="navigation" data-action="click->navigation#goBack"
 * 2. fallback 지정: data-navigation-fallback-value="/settings"
 * 3. 스택 리셋 (메인 진입점): data-controller="navigation" data-action="turbo:load@document->navigation#resetStack"
 */
export default class extends Controller {
  static values = {
    fallback: { type: String, default: "/" },  // 스택 비었을 때 이동할 경로
    resetOnConnect: { type: Boolean, default: false }  // 연결 시 스택 리셋 여부
  }

  connect() {
    // 메인 진입점에서는 스택 리셋
    if (this.resetOnConnectValue) {
      this.resetStack()
    }

    // Turbo 네비게이션 이벤트 리스너 등록
    this.boundTrackNavigation = this.trackNavigation.bind(this)
    document.addEventListener("turbo:visit", this.boundTrackNavigation)

    // 초기 페이지 기록
    this.pushCurrentPage()
  }

  disconnect() {
    document.removeEventListener("turbo:visit", this.boundTrackNavigation)
  }

  /**
   * Turbo 네비게이션 추적
   * turbo:visit 이벤트 발생 시 현재 페이지를 스택에 추가
   */
  trackNavigation(event) {
    // 방문할 URL 추출
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
   * 뒤로가기
   * 스택에서 현재 페이지를 pop하고 이전 페이지로 이동
   */
  goBack(event) {
    event.preventDefault()
    const stack = this.getStack()

    // 현재 페이지 제거
    stack.pop()

    if (stack.length > 0) {
      const previousPage = stack[stack.length - 1]
      this.saveStack(stack)
      Turbo.visit(previousPage)
    } else {
      // 스택이 비면 fallback으로 이동
      this.saveStack([])  // 스택 비우기
      Turbo.visit(this.fallbackValue)
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
   */
  saveStack(stack) {
    sessionStorage.setItem('navStack', JSON.stringify(stack))
  }

  /**
   * 스택 초기화 (메인 진입점에서 호출)
   * Bottom Nav 페이지(커뮤니티, 외주, 채팅, 마이페이지)에서 호출하여 스택 리셋
   */
  resetStack() {
    sessionStorage.removeItem('navStack')
  }
}
