import { Controller } from "@hotwired/stimulus"

// Accordion 컨트롤러 - undrew-design 스타일
// data-controller="accordion" 로 사용
//
// 기본 사용법:
//   data-accordion-target="item" - 각 아이템 래퍼
//   data-accordion-target="content" - 접히는 콘텐츠
//   data-accordion-target="icon" - 회전할 아이콘
//   data-action="click->accordion#toggle" - 트리거 버튼
//
// 옵션:
//   data-accordion-multiple-value="true" - 다중 열기 허용
//   data-item-id="unique-id" - 아이템별 고유 ID (선택사항)
//
export default class extends Controller {
  static targets = ["item", "trigger", "content", "icon", "label"]
  static values = {
    multiple: { type: Boolean, default: false }
  }

  connect() {
    this.openItems = new Set()

    // 초기 열린 항목 추적
    this.contentTargets.forEach(content => {
      if (!content.classList.contains("hidden")) {
        const itemId = content.dataset.itemId || this.contentTargets.indexOf(content).toString()
        this.openItems.add(itemId)
      }
    })
  }

  toggle(event) {
    const trigger = event.currentTarget
    const itemId = trigger.dataset.itemId
    const item = trigger.closest("[data-accordion-target='item']")
    const content = itemId
      ? this.contentTargets.find(c => c.dataset.itemId === itemId)
      : item?.querySelector("[data-accordion-target='content']")
    const icon = itemId
      ? this.iconTargets.find(i => i.dataset.itemId === itemId)
      : item?.querySelector("[data-accordion-target='icon']")

    if (!content) return

    const isHidden = content.classList.contains("hidden")

    if (isHidden) {
      // 다중 열기가 아닌 경우, 다른 항목 닫기
      if (!this.multipleValue) {
        this.closeAllExcept(itemId || this.contentTargets.indexOf(content).toString())
      }
      this.openItem(content, icon, trigger)
    } else {
      this.closeItem(content, icon, trigger)
    }
  }

  openItem(content, icon, trigger) {
    content.classList.remove("hidden")
    content.style.maxHeight = "0"
    content.style.overflow = "hidden"
    content.style.opacity = "0"
    content.style.transition = "max-height 0.3s ease-out, opacity 0.2s ease-out"

    requestAnimationFrame(() => {
      content.style.maxHeight = content.scrollHeight + "px"
      content.style.opacity = "1"

      // 애니메이션 완료 후 스타일 정리
      setTimeout(() => {
        content.style.maxHeight = ""
        content.style.overflow = ""
      }, 300)
    })

    if (icon) {
      icon.classList.add("rotate-180")
    }

    // 라벨 텍스트 변경: 열기 → 닫기
    const item = content.closest("[data-accordion-target='item']")
    const label = item?.querySelector("[data-accordion-target='label']")
    if (label) {
      label.textContent = "닫기"
    }

    if (trigger) {
      trigger.setAttribute("aria-expanded", "true")
    }

    const itemId = content.dataset.itemId || this.contentTargets.indexOf(content).toString()
    this.openItems.add(itemId)
  }

  closeItem(content, icon, trigger) {
    content.style.maxHeight = content.scrollHeight + "px"
    content.style.overflow = "hidden"

    requestAnimationFrame(() => {
      content.style.maxHeight = "0"
      content.style.opacity = "0"

      setTimeout(() => {
        content.classList.add("hidden")
        content.style.maxHeight = ""
        content.style.overflow = ""
        content.style.opacity = ""
        content.style.transition = ""
      }, 300)
    })

    if (icon) {
      icon.classList.remove("rotate-180")
    }

    // 라벨 텍스트 변경: 닫기 → 열기
    const item = content.closest("[data-accordion-target='item']")
    const label = item?.querySelector("[data-accordion-target='label']")
    if (label) {
      label.textContent = "열기"
    }

    if (trigger) {
      trigger.setAttribute("aria-expanded", "false")
    }

    const itemId = content.dataset.itemId || this.contentTargets.indexOf(content).toString()
    this.openItems.delete(itemId)
  }

  closeAllExcept(exceptId) {
    this.contentTargets.forEach((content, index) => {
      const itemId = content.dataset.itemId || index.toString()
      if (itemId !== exceptId && !content.classList.contains("hidden")) {
        const icon = content.dataset.itemId
          ? this.iconTargets.find(i => i.dataset.itemId === itemId)
          : this.itemTargets[index]?.querySelector("[data-accordion-target='icon']")
        this.closeItem(content, icon, null)
      }
    })
  }

  // 모든 항목 열기
  openAll() {
    this.itemTargets.forEach((item, index) => {
      const content = item.querySelector("[data-accordion-target='content']")
      const icon = item.querySelector("[data-accordion-target='icon']")
      if (content && content.classList.contains("hidden")) {
        this.openItem(content, icon, null)
      }
    })
  }

  // 모든 항목 닫기
  closeAll() {
    this.itemTargets.forEach((item, index) => {
      const content = item.querySelector("[data-accordion-target='content']")
      const icon = item.querySelector("[data-accordion-target='icon']")
      if (content && !content.classList.contains("hidden")) {
        this.closeItem(content, icon, null)
      }
    })
  }
}
