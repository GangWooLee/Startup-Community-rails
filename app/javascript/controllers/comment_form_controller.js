import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }
  static targets = ["input", "submit", "counter"]

  connect() {
    this.updateCounter()
    this.updateSubmitState()
  }

  input() {
    this.updateCounter()
    this.updateSubmitState()
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

    if (!this.hasInputTarget || !this.inputTarget.value.trim()) {
      return
    }

    const formData = new FormData()
    formData.append("comment[content]", this.inputTarget.value.trim())

    // parent_id 처리 (대댓글인 경우)
    const parentId = this.element.dataset.parentId
    if (parentId) {
      formData.append("comment[parent_id]", parentId)
    }

    try {
      this.submitTarget.disabled = true
      this.submitTarget.textContent = "작성 중..."

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

        // 대댓글 폼이면 숨기기
        if (parentId) {
          this.element.classList.add("hidden")
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
      this.submitTarget.disabled = false
      this.submitTarget.textContent = "작성"
      this.updateSubmitState()
    }
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content || ""
  }
}
