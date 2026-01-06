import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messages", "messageInput", "form"]
  static values = { roomId: Number }

  connect() {
    this.scrollToBottom()
    this.observeNewMessages()
    this.markAsReadDebounceTimer = null
  }

  // 제안 메시지 삽입
  insertSuggestion(event) {
    const message = event.currentTarget.dataset.message
    if (this.hasMessageInputTarget && message) {
      this.messageInputTarget.value = message
      this.messageInputTarget.focus()
      // 자동 리사이즈 트리거
      this.messageInputTarget.dispatchEvent(new Event('input', { bubbles: true }))
    }
  }

  scrollToBottom() {
    if (this.hasMessagesTarget) {
      this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
    }
  }

  observeNewMessages() {
    if (!this.hasMessagesTarget) return

    // MutationObserver로 새 메시지 추가 감지
    this.observer = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        if (mutation.addedNodes.length > 0) {
          // 부드럽게 스크롤
          this.smoothScrollToBottom()
          // 실시간 메시지 수신 시 읽음 처리 (debounce 적용)
          this.markAsReadDebounced()
        }
      })
    })

    this.observer.observe(this.messagesTarget, { childList: true })
  }

  smoothScrollToBottom() {
    if (this.hasMessagesTarget) {
      this.messagesTarget.scrollTo({
        top: this.messagesTarget.scrollHeight,
        behavior: 'smooth'
      })
    }
  }

  // 읽음 처리 (300ms debounce - 빈번한 요청 방지)
  markAsReadDebounced() {
    if (this.markAsReadDebounceTimer) {
      clearTimeout(this.markAsReadDebounceTimer)
    }

    this.markAsReadDebounceTimer = setTimeout(() => {
      this.markAsRead()
    }, 300)
  }

  // 서버에 읽음 상태 전송
  markAsRead() {
    if (!this.hasRoomIdValue) return

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    fetch(`/chat_rooms/${this.roomIdValue}/mark_as_read`, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': csrfToken,
        'Accept': 'application/json'
      },
      credentials: 'same-origin'
    }).catch(error => {
      // 에러 무시 (UX에 영향 없음)
      console.debug('mark_as_read error:', error)
    })
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
    if (this.markAsReadDebounceTimer) {
      clearTimeout(this.markAsReadDebounceTimer)
    }
  }
}
