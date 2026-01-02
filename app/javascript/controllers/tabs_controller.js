import { Controller } from "@hotwired/stimulus"

// Tabs 컨트롤러 - undrew-design 스타일
// data-controller="tabs" 로 사용
export default class extends Controller {
  static targets = ["list", "trigger", "panel", "panelContainer"]
  static values = {
    default: String
  }

  connect() {
    this.activeTab = this.defaultValue || this.triggerTargets[0]?.dataset.tabId
    this.updateUI()
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
