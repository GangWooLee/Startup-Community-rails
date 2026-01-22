import { Controller } from "@hotwired/stimulus"

// 채팅 목록에서 활성 채팅방 표시 관리 및 자동 정렬
// - 서버 렌더링 시 current_chat_room이 전달되면 이미 활성 스타일이 적용됨
// - 이 컨트롤러는 Turbo Frame으로 우측만 업데이트될 때 좌측 패널의 활성 상태를 동기화
// - Turbo Stream으로 채팅방 아이템이 업데이트되면 자동으로 정렬
// - 모바일에서는 Turbo Frame을 비활성화하여 전체 페이지 네비게이션 사용
export default class extends Controller {
  static targets = ["item", "room"]

  // Tailwind md 브레이크포인트 (768px)
  static MOBILE_BREAKPOINT = 768

  connect() {
    // 모바일에서 Turbo Frame 비활성화 (전체 페이지 네비게이션)
    this.handleMobileLinks()

    // MutationObserver: Turbo Stream으로 새 아이템이 추가될 때도 처리
    this.observer = new MutationObserver(() => {
      this.handleMobileLinks()
    })
    this.observer.observe(this.element, { childList: true, subtree: true })

    // 리사이즈 이벤트 핸들러 (뷰포트 변경 대응)
    this.boundHandleResize = this.handleResize.bind(this)
    window.addEventListener("resize", this.boundHandleResize)

    // Turbo Frame 로드 완료 시 활성 상태 업데이트 (우측 패널만 업데이트될 때)
    this.boundHandleFrameLoad = this.handleFrameLoad.bind(this)
    document.addEventListener("turbo:frame-load", this.boundHandleFrameLoad)

    // Turbo Stream으로 DOM 변경 시 자동 정렬
    this.boundHandleBeforeStreamRender = this.handleBeforeStreamRender.bind(this)
    document.addEventListener("turbo:before-stream-render", this.boundHandleBeforeStreamRender)
  }

  disconnect() {
    this.observer?.disconnect()
    window.removeEventListener("resize", this.boundHandleResize)
    document.removeEventListener("turbo:frame-load", this.boundHandleFrameLoad)
    document.removeEventListener("turbo:before-stream-render", this.boundHandleBeforeStreamRender)
  }

  // 모바일 여부 확인
  isMobile() {
    return window.innerWidth < this.constructor.MOBILE_BREAKPOINT
  }

  // 모바일에서 Turbo Frame 제거하여 전체 페이지 네비게이션 활성화
  // ✅ querySelectorAll 사용: itemTargets는 connect() 시점에 비어있을 수 있음
  //    (Turbo 캐시 복원, Turbo Stream 동적 추가 등의 시나리오)
  handleMobileLinks() {
    if (!this.isMobile()) return

    this.element.querySelectorAll('a[data-turbo-frame="chat_room_content"]').forEach(link => {
      link.setAttribute("data-turbo-frame", "_top")
    })
  }

  // 리사이즈 시 재평가 (뷰포트 변경 대응)
  handleResize() {
    // 디바운스 적용 (과도한 DOM 조작 방지)
    clearTimeout(this.resizeTimeout)
    this.resizeTimeout = setTimeout(() => {
      if (this.isMobile()) {
        // 모바일로 전환: _top으로 변경하여 전체 페이지 이동
        this.element.querySelectorAll('a[data-turbo-frame="chat_room_content"]').forEach(link => {
          link.setAttribute("data-turbo-frame", "_top")
        })
      } else {
        // PC로 전환: Turbo Frame 복원
        // 모바일에서 _top으로 변경된 링크를 chat_room_content로 복원
        this.element.querySelectorAll('a[data-turbo-frame="_top"]').forEach(link => {
          link.setAttribute("data-turbo-frame", "chat_room_content")
        })
      }
    }, 100)
  }

  // Turbo Stream 렌더링 전에 처리
  handleBeforeStreamRender(event) {
    const stream = event.target
    // replace 액션이고 chat_room_ 타겟인 경우에만 처리
    if (stream.action === "replace" && stream.target?.startsWith("chat_room_")) {
      // 렌더링 후 정렬 수행
      setTimeout(() => this.sortRooms(), 10)
    }
  }

  // 채팅방 목록을 last_message_at 기준으로 정렬 (최신이 위로)
  sortRooms() {
    const container = this.element.querySelector(".divide-y")
    if (!container) return

    const rooms = Array.from(container.querySelectorAll(".chat-room-item"))
    if (rooms.length <= 1) return

    // last_message_at 기준으로 내림차순 정렬
    rooms.sort((a, b) => {
      const timeA = parseInt(a.dataset.lastMessageAt) || 0
      const timeB = parseInt(b.dataset.lastMessageAt) || 0
      return timeB - timeA
    })

    // 이미 정렬되어 있는지 확인
    const currentOrder = Array.from(container.children).map(el => el.id)
    const newOrder = rooms.map(el => el.id)
    if (JSON.stringify(currentOrder) === JSON.stringify(newOrder)) {
      return // 이미 정렬됨
    }

    // DOM 재배치 (부드러운 애니메이션 없이 즉시)
    rooms.forEach(room => container.appendChild(room))
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
