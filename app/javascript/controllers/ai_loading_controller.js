import { Controller } from "@hotwired/stimulus"

/**
 * AI 분석 로딩 컨트롤러
 *
 * 비동기 AI 분석 중 로딩 오버레이를 표시하고,
 * Turbo Stream으로 결과가 도착하면 부드럽게 콘텐츠를 공개합니다.
 *
 * 사용법:
 * <div data-controller="ai-loading" data-ai-loading-status-value="analyzing">
 *   <div data-ai-loading-target="overlay">로딩 오버레이</div>
 *   <div data-ai-loading-target="content">콘텐츠</div>
 * </div>
 */
export default class extends Controller {
  static targets = ["overlay", "content"]
  static values = { status: String }

  connect() {
    // Turbo Stream 렌더링 전 이벤트 리스너
    this.handleStreamRender = this.handleStreamRender.bind(this)
    document.addEventListener("turbo:before-stream-render", this.handleStreamRender)

    // MutationObserver로 콘텐츠 변경 감지 (백업)
    this.setupContentObserver()
  }

  disconnect() {
    document.removeEventListener("turbo:before-stream-render", this.handleStreamRender)
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  /**
   * Turbo Stream 렌더링 이벤트 핸들러
   * - ai_loading_progress: 단계별 프로그레스 바 업데이트
   * - ai_result_content: 분석 완료 시 reveal 애니메이션 실행
   */
  handleStreamRender(event) {
    const stream = event.target

    // 프로그레스 바 업데이트 (단계 진행 시)
    if (stream.target === "ai_loading_progress") {
      this.handleProgressUpdate()
      return
    }

    // ai_result_content 타겟이 교체되는 경우 (분석 완료)
    if (stream.target === "ai_result_content") {
      // 렌더링 후 애니메이션 실행을 위해 약간의 지연
      requestAnimationFrame(() => {
        setTimeout(() => this.revealContent(), 50)
      })
    }
  }

  /**
   * 프로그레스 업데이트 핸들러
   * 단계가 변경될 때마다 호출됨 (Turbo Stream broadcast)
   */
  handleProgressUpdate() {
    // CSS transition이 자동으로 프로그레스 바 애니메이션 처리
    // 추가 효과가 필요하면 여기에 구현
    const progressContainer = document.querySelector('[data-ai-loading-target="progressContainer"]')
    if (progressContainer) {
      // 숫자 변경 시 살짝 확대 효과
      progressContainer.classList.add("scale-105")
      setTimeout(() => {
        progressContainer.classList.remove("scale-105")
      }, 200)
    }
  }

  /**
   * MutationObserver 설정 (Turbo Stream 이벤트 미스 대비)
   */
  setupContentObserver() {
    const contentElement = document.getElementById("ai_result_content")
    if (!contentElement) return

    this.observer = new MutationObserver((mutations) => {
      // 콘텐츠가 변경되고 blur 클래스가 없으면 이미 처리된 것
      if (!contentElement.classList.contains("blur-sm")) {
        return
      }

      // 자식 노드가 변경되었으면 분석 완료로 간주
      for (const mutation of mutations) {
        if (mutation.type === "childList" && mutation.addedNodes.length > 0) {
          this.revealContent()
          break
        }
      }
    })

    this.observer.observe(contentElement, {
      childList: true,
      subtree: false
    })
  }

  /**
   * 콘텐츠 공개 애니메이션
   * 1. 오버레이 페이드아웃
   * 2. 콘텐츠 언블러 + 페이드인
   */
  revealContent() {
    // 1. 오버레이 페이드아웃
    if (this.hasOverlayTarget) {
      const overlay = this.overlayTarget
      overlay.classList.add("transition-opacity", "duration-500", "ease-out")
      overlay.classList.add("opacity-0")

      // 페이드아웃 완료 후 DOM에서 제거
      setTimeout(() => {
        overlay.remove()
      }, 500)
    }

    // 2. 콘텐츠 언블러 및 활성화
    if (this.hasContentTarget) {
      const content = this.contentTarget

      // 블러 및 비활성화 클래스 제거
      content.classList.remove("blur-sm", "pointer-events-none", "select-none")

      // 페이드인 애니메이션 추가
      content.classList.add("animate-fade-in-up")

      // 애니메이션 완료 후 클래스 정리
      setTimeout(() => {
        content.classList.remove("animate-fade-in-up")
      }, 500)
    }

    // 상태 값 업데이트
    this.statusValue = "completed"
  }

  /**
   * status 값 변경 콜백
   * 외부에서 상태가 변경될 때 호출됨
   */
  statusValueChanged(newStatus, oldStatus) {
    if (oldStatus === "analyzing" && newStatus === "completed") {
      this.revealContent()
    }
  }
}
