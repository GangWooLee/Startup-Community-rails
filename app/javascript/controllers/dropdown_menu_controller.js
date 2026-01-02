import { Controller } from "@hotwired/stimulus"

// Dropdown 메뉴 컨트롤러 - undrew-design 스타일
// data-controller="dropdown-menu" 로 사용
export default class extends Controller {
  static targets = ["trigger", "menu"]

  connect() {
    this.isOpen = false
  }

  toggle(event) {
    event.stopPropagation()

    if (this.isOpen) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    if (this.hasMenuTarget) {
      this.menuTarget.classList.remove("hidden")
      this.isOpen = true

      // 포커스 관리
      const firstItem = this.menuTarget.querySelector("a, button")
      if (firstItem) {
        setTimeout(() => firstItem.focus(), 50)
      }
    }
  }

  close() {
    if (this.hasMenuTarget) {
      this.menuTarget.classList.add("hidden")
      this.isOpen = false
    }
  }

  closeOnClickOutside(event) {
    // 트리거나 메뉴 내부 클릭이 아닌 경우 닫기
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  // 키보드 네비게이션
  keydown(event) {
    if (!this.isOpen) return

    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        this.focusNext()
        break
      case "ArrowUp":
        event.preventDefault()
        this.focusPrevious()
        break
      case "Enter":
      case " ":
        // 선택된 아이템 클릭
        if (document.activeElement) {
          document.activeElement.click()
        }
        break
    }
  }

  focusNext() {
    const items = this.menuTarget.querySelectorAll("a, button")
    const currentIndex = Array.from(items).indexOf(document.activeElement)
    const nextIndex = (currentIndex + 1) % items.length
    items[nextIndex]?.focus()
  }

  focusPrevious() {
    const items = this.menuTarget.querySelectorAll("a, button")
    const currentIndex = Array.from(items).indexOf(document.activeElement)
    const prevIndex = (currentIndex - 1 + items.length) % items.length
    items[prevIndex]?.focus()
  }
}
