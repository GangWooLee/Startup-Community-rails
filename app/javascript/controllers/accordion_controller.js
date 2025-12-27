import { Controller } from "@hotwired/stimulus"

// Accordion 컨트롤러 - 접기/펼치기 기능
export default class extends Controller {
  static targets = ["item", "trigger", "content", "icon"]

  connect() {
    // 초기 상태 설정 - 모든 항목 닫힘
  }

  toggle(event) {
    const trigger = event.currentTarget
    const item = trigger.closest("[data-accordion-target='item']")
    const content = item.querySelector("[data-accordion-target='content']")
    const icon = item.querySelector("[data-accordion-target='icon']")

    if (content.classList.contains("hidden")) {
      // 열기
      content.classList.remove("hidden")
      if (icon) {
        icon.classList.add("rotate-180")
      }
      // 부드러운 애니메이션
      content.style.maxHeight = "0"
      content.style.overflow = "hidden"
      content.style.transition = "max-height 0.3s ease-out"
      requestAnimationFrame(() => {
        content.style.maxHeight = content.scrollHeight + "px"
      })
    } else {
      // 닫기
      content.style.maxHeight = "0"
      if (icon) {
        icon.classList.remove("rotate-180")
      }
      setTimeout(() => {
        content.classList.add("hidden")
        content.style.maxHeight = ""
        content.style.overflow = ""
      }, 300)
    }
  }

  // 모든 항목 열기
  openAll() {
    this.itemTargets.forEach(item => {
      const content = item.querySelector("[data-accordion-target='content']")
      const icon = item.querySelector("[data-accordion-target='icon']")
      content.classList.remove("hidden")
      if (icon) {
        icon.classList.add("rotate-180")
      }
    })
  }

  // 모든 항목 닫기
  closeAll() {
    this.itemTargets.forEach(item => {
      const content = item.querySelector("[data-accordion-target='content']")
      const icon = item.querySelector("[data-accordion-target='icon']")
      content.classList.add("hidden")
      if (icon) {
        icon.classList.remove("rotate-180")
      }
    })
  }
}
