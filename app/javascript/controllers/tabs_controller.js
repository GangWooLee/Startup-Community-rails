import { Controller } from "@hotwired/stimulus"

// Tabs 컨트롤러 - undrew-design 스타일
// data-controller="tabs" 로 사용
// 모바일: 좌우 스와이프로 탭 전환 지원
export default class extends Controller {
  static targets = ["list", "trigger", "panel", "panelContainer"]
  static values = {
    default: String,
    swipeEnabled: { type: Boolean, default: true }  // 스와이프 탭 전환 활성화
  }

  connect() {
    this.activeTab = this.defaultValue || this.triggerTargets[0]?.dataset.tabId
    this.updateUI()

    // 모바일 터치: 스와이프로 탭 전환
    this.touchStartX = 0
    this.touchStartY = 0
    this.boundTouchStart = this.handleTouchStart.bind(this)
    this.boundTouchEnd = this.handleTouchEnd.bind(this)

    // 패널 컨테이너에 터치 이벤트 등록
    if (this.hasPanelContainerTarget) {
      this.panelContainerTarget.addEventListener("touchstart", this.boundTouchStart, { passive: true })
      this.panelContainerTarget.addEventListener("touchend", this.boundTouchEnd)
    }
  }

  disconnect() {
    if (this.hasPanelContainerTarget) {
      this.panelContainerTarget.removeEventListener("touchstart", this.boundTouchStart)
      this.panelContainerTarget.removeEventListener("touchend", this.boundTouchEnd)
    }
  }

  // 터치 시작 위치 기록
  handleTouchStart(event) {
    if (!this.swipeEnabledValue) return
    this.touchStartX = event.touches[0].clientX
    this.touchStartY = event.touches[0].clientY
  }

  // 터치 종료: 좌우 스와이프로 탭 전환
  handleTouchEnd(event) {
    if (!this.swipeEnabledValue) return

    const deltaX = event.changedTouches[0].clientX - this.touchStartX
    const deltaY = event.changedTouches[0].clientY - this.touchStartY

    // 가로 스와이프가 세로보다 크고, 50px 이상 스와이프
    if (Math.abs(deltaX) > Math.abs(deltaY) && Math.abs(deltaX) > 50) {
      const triggers = this.triggerTargets
      const currentIndex = triggers.findIndex(t => t.dataset.tabId === this.activeTab)

      if (deltaX < 0 && currentIndex < triggers.length - 1) {
        // 왼쪽 스와이프: 다음 탭
        this.switchToTab(currentIndex + 1)
      } else if (deltaX > 0 && currentIndex > 0) {
        // 오른쪽 스와이프: 이전 탭
        this.switchToTab(currentIndex - 1)
      }
    }
  }

  // 인덱스로 탭 전환
  switchToTab(index) {
    const triggers = this.triggerTargets
    if (index >= 0 && index < triggers.length) {
      const tabId = triggers[index].dataset.tabId
      if (tabId !== this.activeTab) {
        this.activeTab = tabId
        this.updateUI()

        // Haptic 피드백
        if (navigator.vibrate) {
          navigator.vibrate(10)
        }

        // 커스텀 이벤트 발생
        this.element.dispatchEvent(new CustomEvent("tabs:change", {
          detail: { tabId },
          bubbles: true
        }))
      }
    }
  }

  select(event) {
    const tabId = event.currentTarget.dataset.tabId
    if (tabId === this.activeTab) return

    this.activeTab = tabId
    this.updateUI()

    // 커스텀 이벤트 발생
    this.element.dispatchEvent(new CustomEvent("tabs:change", {
      detail: { tabId },
      bubbles: true
    }))
  }

  updateUI() {
    // 트리거 업데이트
    this.triggerTargets.forEach(trigger => {
      const isActive = trigger.dataset.tabId === this.activeTab
      trigger.setAttribute("aria-selected", isActive.toString())

      // 기존 active 클래스 처리는 서버 렌더링에 의존
      // 여기서는 aria-selected만 업데이트
      if (isActive) {
        trigger.classList.add("is-active")
      } else {
        trigger.classList.remove("is-active")
      }
    })

    // 패널 업데이트
    this.panelTargets.forEach(panel => {
      const isActive = panel.dataset.tabId === this.activeTab

      if (isActive) {
        panel.classList.remove("hidden")
        // 페이드인 효과
        panel.style.opacity = "0"
        panel.style.transform = "translateY(4px)"
        requestAnimationFrame(() => {
          panel.style.transition = "opacity 0.2s ease-out, transform 0.2s ease-out"
          panel.style.opacity = "1"
          panel.style.transform = "translateY(0)"
        })
      } else {
        panel.classList.add("hidden")
        panel.style.opacity = ""
        panel.style.transform = ""
        panel.style.transition = ""
      }
    })
  }

  // 키보드 네비게이션
  keydown(event) {
    const triggers = this.triggerTargets
    const currentIndex = triggers.indexOf(event.target)

    switch (event.key) {
      case "ArrowLeft":
        event.preventDefault()
        const prevIndex = (currentIndex - 1 + triggers.length) % triggers.length
        triggers[prevIndex]?.focus()
        triggers[prevIndex]?.click()
        break
      case "ArrowRight":
        event.preventDefault()
        const nextIndex = (currentIndex + 1) % triggers.length
        triggers[nextIndex]?.focus()
        triggers[nextIndex]?.click()
        break
      case "Home":
        event.preventDefault()
        triggers[0]?.focus()
        triggers[0]?.click()
        break
      case "End":
        event.preventDefault()
        triggers[triggers.length - 1]?.focus()
        triggers[triggers.length - 1]?.click()
        break
    }
  }
}
