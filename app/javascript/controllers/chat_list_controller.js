import { Controller } from "@hotwired/stimulus"

// 채팅 목록에서 활성 채팅방 표시 관리
// - 서버 렌더링 시 current_chat_room이 전달되면 이미 활성 스타일이 적용됨
// - 이 컨트롤러는 Turbo Frame으로 우측만 업데이트될 때 좌측 패널의 활성 상태를 동기화
export default class extends Controller {
  static targets = ["item"]

  connect() {
    // Turbo Frame 로드 완료 시 활성 상태 업데이트 (우측 패널만 업데이트될 때)
    this.boundHandleFrameLoad = this.handleFrameLoad.bind(this)
    document.addEventListener("turbo:frame-load", this.boundHandleFrameLoad)
  }

  disconnect() {
    document.removeEventListener("turbo:frame-load", this.boundHandleFrameLoad)
  }

  handleFrameLoad(event) {
    // chat_room_content 프레임이 로드되면 활성 상태 업데이트
    if (event.target.id === "chat_room_content") {
      this.syncActiveState()
    }
  }

  // 채팅방 아이템 클릭 시 즉시 활성 상태 적용 (Turbo Frame 로드 전)
  select(event) {
    const clickedItem = event.currentTarget
    const roomId = clickedItem.dataset.chatListRoomId

    if (roomId) {
      // 모든 아이템 비활성화
      this.itemTargets.forEach(item => {
        item.classList.remove("bg-primary/10")
        item.classList.add("hover:bg-gray-50")
      })

      // 클릭한 아이템 활성화
      clickedItem.classList.add("bg-primary/10")
      clickedItem.classList.remove("hover:bg-gray-50")
    }
  }

  // 우측 패널의 채팅방 ID를 기준으로 좌측 패널 활성 상태 동기화
  syncActiveState() {
    const contentFrame = document.getElementById("chat_room_content")
    if (!contentFrame) return

    const chatRoomElement = contentFrame.querySelector("[data-chat-room-id]")
    const activeChatRoomId = chatRoomElement?.dataset.chatRoomId

    this.itemTargets.forEach(item => {
      const roomId = item.dataset.chatListRoomId
      const isActive = roomId === activeChatRoomId

      if (isActive) {
        item.classList.add("bg-primary/10")
        item.classList.remove("hover:bg-gray-50")
      } else {
        item.classList.remove("bg-primary/10")
        item.classList.add("hover:bg-gray-50")
      }
    })
  }
}
