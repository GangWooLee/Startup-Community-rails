import { Controller } from "@hotwired/stimulus"

/**
 * Experience Form Controller
 * 프로필 편집 페이지에서 경력/경험 항목을 동적으로 추가/삭제하는 컨트롤러
 *
 * Targets:
 * - list: 경험 목록 컨테이너
 * - item: 개별 경험 항목
 * - template: 새 항목 생성용 템플릿
 * - empty: 빈 상태 표시
 */
export default class extends Controller {
  static targets = ["list", "item", "template", "empty"]

  connect() {
    this.updateEmptyState()
    this.updateSortOrders()
  }

  /**
   * 새 경험 항목 추가
   */
  add() {
    const template = this.templateTarget.content.cloneNode(true)
    const newItem = template.querySelector('[data-experience-form-target="item"]')

    // 새 항목 추가
    this.listTarget.appendChild(newItem)

    // 정렬 순서 업데이트
    this.updateSortOrders()

    // 빈 상태 숨기기
    this.updateEmptyState()

    // 첫 번째 입력 필드에 포커스
    const firstInput = newItem.querySelector('input[type="text"]')
    if (firstInput) {
      firstInput.focus()
    }

    // 부드러운 등장 애니메이션
    newItem.style.opacity = '0'
    newItem.style.transform = 'translateY(-10px)'
    requestAnimationFrame(() => {
      newItem.style.transition = 'opacity 0.2s ease, transform 0.2s ease'
      newItem.style.opacity = '1'
      newItem.style.transform = 'translateY(0)'
    })
  }

  /**
   * 경험 항목 삭제
   * @param {Event} event - 클릭 이벤트
   */
  remove(event) {
    const item = event.target.closest('[data-experience-form-target="item"]')

    if (item) {
      // 삭제 애니메이션
      item.style.transition = 'opacity 0.2s ease, transform 0.2s ease, height 0.2s ease'
      item.style.opacity = '0'
      item.style.transform = 'translateX(10px)'
      item.style.height = item.offsetHeight + 'px'

      setTimeout(() => {
        item.style.height = '0'
        item.style.marginBottom = '0'
        item.style.padding = '0'
        item.style.overflow = 'hidden'

        setTimeout(() => {
          item.remove()
          this.updateSortOrders()
          this.updateEmptyState()
        }, 200)
      }, 100)
    }
  }

  /**
   * 정렬 순서 업데이트
   * 각 항목의 sort_order hidden 필드를 인덱스 순서로 업데이트
   */
  updateSortOrders() {
    this.itemTargets.forEach((item, index) => {
      const sortOrderInput = item.querySelector('input[name*="sort_order"]')
      if (sortOrderInput) {
        sortOrderInput.value = index
      }
    })
  }

  /**
   * 빈 상태 표시 업데이트
   * 항목이 없으면 빈 상태 메시지 표시
   */
  updateEmptyState() {
    if (this.hasEmptyTarget) {
      if (this.itemTargets.length === 0) {
        this.emptyTarget.classList.remove('hidden')
      } else {
        this.emptyTarget.classList.add('hidden')
      }
    }
  }
}
