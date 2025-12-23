import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messages", "messageInput", "form"]
  static values = { roomId: Number }

  connect() {
    this.scrollToBottom()
    this.observeNewMessages()
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

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }
}
