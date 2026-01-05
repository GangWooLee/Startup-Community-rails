import { Controller } from "@hotwired/stimulus"

/**
 * Load More Controller
 * "더 많은 이야기 보기" 버튼의 로딩 상태를 관리합니다.
 * Turbo Stream으로 새 게시글을 로드하고 append합니다.
 *
 * 사용법:
 * <a data-controller="load-more" data-action="click->load-more#load">더 보기</a>
 */
export default class extends Controller {
  load(event) {
    const button = event.currentTarget
    const textEl = button.querySelector('.load-more-text')
    const spinnerEl = button.querySelector('.load-more-spinner')

    // 로딩 상태 표시
    if (textEl) textEl.textContent = '불러오는 중...'
    if (spinnerEl) spinnerEl.classList.remove('hidden')
    button.classList.add('pointer-events-none', 'opacity-70')
  }
}
