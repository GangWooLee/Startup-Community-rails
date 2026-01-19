import { Controller } from "@hotwired/stimulus"

// 채팅방 나가기 확인 모달 컨트롤러
export default class extends Controller {
  static targets = ["modal", "userName"]

  connect() {
    this.currentRoomId = null
    this.currentRoomName = null
  }

  // 모달 표시
  showModal(event) {
    const roomId = event.params.roomId
    const roomName = event.params.roomName

    this.currentRoomId = roomId
    this.currentRoomName = roomName

    // 모달이 없으면 생성
    if (!this.hasModalTarget) {
      this.createModal()
    }

    // 사용자 이름 업데이트
    if (this.hasUserNameTarget) {
      this.userNameTarget.textContent = roomName
    }

    // 모달 표시
    this.modalTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
  }

  // 모달 닫기
  closeModal() {
    if (this.hasModalTarget) {
      this.modalTarget.classList.add("hidden")
      document.body.classList.remove("overflow-hidden")
    }
  }

  // 채팅방 나가기 실행
  async leaveChat() {
    if (!this.currentRoomId) return

    try {
      const response = await fetch(`/chat_rooms/${this.currentRoomId}/leave`, {
        method: 'DELETE',
        headers: {
          'Accept': 'text/vnd.turbo-stream.html',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content || ''
        }
      })

      if (response.ok) {
        // Turbo Stream 응답 처리
        const html = await response.text()
        Turbo.renderStreamMessage(html)
        this.closeModal()
      } else {
        console.error('Failed to leave chat room')
        alert('채팅방 나가기에 실패했습니다. 다시 시도해주세요.')
      }
    } catch (error) {
      console.error('Error leaving chat room:', error)
      alert('오류가 발생했습니다. 다시 시도해주세요.')
    }
  }

  // 모달 동적 생성 (XSS 방지: 사용자 데이터는 textContent로 삽입)
  createModal() {
    const modal = document.createElement('div')
    modal.className = 'fixed inset-0 z-50 flex items-center justify-center hidden'
    modal.dataset.leaveChatTarget = 'modal'

    // 정적 HTML 구조만 사용 (사용자 입력 데이터 미포함)
    // Note: innerHTML is safe here as it contains only static HTML without user data
    const staticHtml = `
      <div class="absolute inset-0 bg-black/50" data-action="click->leave-chat#closeModal"></div>
      <div class="relative bg-white rounded-2xl shadow-xl w-[90%] max-w-sm mx-auto p-6 animate-modal-in">
        <h3 class="text-lg font-semibold text-gray-900 mb-2">채팅방을 나가시겠습니까?</h3>
        <p class="text-sm text-gray-600 mb-6">
          채팅 목록에서 사라지지만, <strong data-leave-chat-target="userName"></strong>님은 계속 대화 내용을 볼 수 있습니다.
          <br><br>
          <span class="text-gray-500">상대방이 다시 메시지를 보내면 채팅방이 다시 나타납니다.</span>
        </p>
        <div class="flex gap-3">
          <button type="button"
                  class="flex-1 py-2.5 px-4 text-sm font-medium text-gray-700 bg-gray-100 rounded-xl hover:bg-gray-200 transition-colors"
                  data-action="click->leave-chat#closeModal">
            취소
          </button>
          <button type="button"
                  class="flex-1 py-2.5 px-4 text-sm font-medium text-white bg-red-500 rounded-xl hover:bg-red-600 transition-colors"
                  data-action="click->leave-chat#leaveChat">
            나가기
          </button>
        </div>
      </div>
    `
    modal.innerHTML = staticHtml

    // 사용자 이름은 textContent로 안전하게 삽입 (XSS 방지)
    const userNameElement = modal.querySelector('[data-leave-chat-target="userName"]')
    if (userNameElement) {
      userNameElement.textContent = this.currentRoomName
    }

    this.element.appendChild(modal)
  }
}
