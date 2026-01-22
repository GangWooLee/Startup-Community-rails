import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }
  static targets = ["input", "submit", "counter"]

  connect() {
    this.isSubmitting = false
    this.updateCounter()
    this.updateSubmitState()

    // 모바일 터치 이벤트: 스와이프로 폼 초기화
    this.touchStartX = 0
    this.touchStartY = 0
    this.boundTouchStart = this.handleTouchStart.bind(this)
    this.boundTouchEnd = this.handleTouchEnd.bind(this)

    this.element.addEventListener("touchstart", this.boundTouchStart, { passive: true })
    this.element.addEventListener("touchend", this.boundTouchEnd)
  }

  disconnect() {
    this.element.removeEventListener("touchstart", this.boundTouchStart)
    this.element.removeEventListener("touchend", this.boundTouchEnd)
  }

  // 터치 시작 위치 기록
  handleTouchStart(event) {
    this.touchStartX = event.touches[0].clientX
    this.touchStartY = event.touches[0].clientY
  }

  // 터치 종료: 오른쪽 스와이프로 폼 초기화 (대댓글 폼 닫기)
  handleTouchEnd(event) {
    const deltaX = event.changedTouches[0].clientX - this.touchStartX
    const deltaY = event.changedTouches[0].clientY - this.touchStartY

    // 가로 스와이프가 세로보다 크고, 오른쪽으로 80px 이상 스와이프
    if (Math.abs(deltaX) > Math.abs(deltaY) && deltaX > 80) {
      // 대댓글 폼이면 닫기
      const formContainer = this.element.closest('[data-reply-toggle-target="form"]')
      if (formContainer) {
        formContainer.classList.add("hidden")
        // Haptic 피드백
        if (navigator.vibrate) {
          navigator.vibrate(10)
        }
      }
    }
  }

  input() {
    this.updateCounter()
    this.updateSubmitState()
  }

  // Enter로 제출, Shift+Enter로 줄바꿈
  submitOnEnter(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      if (this.hasSubmitTarget && !this.submitTarget.disabled) {
        this.submit(event)
      }
    }
  }

  updateCounter() {
    if (this.hasCounterTarget && this.hasInputTarget) {
      const length = this.inputTarget.value.length
      this.counterTarget.textContent = `${length}/1000`

      if (length > 900) {
        this.counterTarget.classList.add("text-destructive")
        this.counterTarget.classList.remove("text-muted-foreground")
      } else {
        this.counterTarget.classList.remove("text-destructive")
        this.counterTarget.classList.add("text-muted-foreground")
      }
    }
  }

  updateSubmitState() {
    if (this.hasSubmitTarget && this.hasInputTarget) {
      const hasContent = this.inputTarget.value.trim().length > 0
      this.submitTarget.disabled = !hasContent

      if (hasContent) {
        this.submitTarget.classList.remove("opacity-50", "cursor-not-allowed")
      } else {
        this.submitTarget.classList.add("opacity-50", "cursor-not-allowed")
      }
    }
  }

  async submit(event) {
    event.preventDefault()

    // 중복 제출 방지
    if (this.isSubmitting) {
      console.warn("[CommentForm] Submit already in progress, ignoring")
      return
    }

    if (!this.hasInputTarget || !this.inputTarget.value.trim()) {
      return
    }

    this.isSubmitting = true

    // parent_id 한 번만 읽어서 재사용
    const parentId = this.element.dataset.parentId
    const isReply = Boolean(parentId)

    const formData = new FormData()
    formData.append("comment[content]", this.inputTarget.value.trim())

    if (isReply) {
      formData.append("comment[parent_id]", parentId)
    }

    try {
      this.submitTarget.disabled = true
      this.submitTarget.textContent = isReply ? "답글 중..." : "작성 중..."

      const response = await fetch(this.urlValue, {
        method: "POST",
        headers: {
          "X-CSRF-Token": this.csrfToken,
          "Accept": "text/vnd.turbo-stream.html, application/json"
        },
        body: formData
      })

      if (response.ok) {
        // Turbo Stream 응답 처리
        const contentType = response.headers.get("content-type")
        if (contentType && contentType.includes("text/vnd.turbo-stream.html")) {
          const html = await response.text()
          Turbo.renderStreamMessage(html)
        }

        // 입력 필드 초기화
        this.inputTarget.value = ""
        this.updateCounter()
        this.updateSubmitState()

        // 대댓글 폼이면 폼 컨테이너 숨기기
        if (isReply) {
          // reply-toggle-target="form" 인 부모 요소를 찾아서 숨김
          const formContainer = this.element.closest('[data-reply-toggle-target="form"]')
          if (formContainer) {
            formContainer.classList.add("hidden")
          }

          // 답글 목록이 숨겨져 있으면 보이게 함
          const repliesContainer = document.getElementById(`replies-${parentId}`)
          if (repliesContainer && repliesContainer.classList.contains("hidden")) {
            repliesContainer.classList.remove("hidden")
          }
        }
      } else if (response.status === 401) {
        window.location.href = "/login"
      } else {
        const data = await response.json()
        alert(data.errors?.join(", ") || "댓글 작성에 실패했습니다.")
      }
    } catch (error) {
      console.error("Comment submit failed:", error)
      alert("댓글 작성에 실패했습니다.")
    } finally {
      this.isSubmitting = false
      this.submitTarget.disabled = false
      // 대댓글이면 "답글", 일반 댓글이면 "작성"
      this.submitTarget.textContent = isReply ? "답글" : "작성"
      this.updateSubmitState()
    }
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content || ""
  }
}
