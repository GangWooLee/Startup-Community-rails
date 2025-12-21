import { Controller } from "@hotwired/stimulus"

// 스크랩 버튼 컨트롤러
// 사용법: data-controller="bookmark-button"
//        data-bookmark-button-url-value="/posts/1/bookmark"
//        data-bookmark-button-bookmarked-value="false"
export default class extends Controller {
  static values = {
    url: String,
    bookmarked: Boolean
  }

  static targets = ["icon"]

  connect() {
    this.updateUI()
  }

  async toggle(event) {
    event.preventDefault()
    event.stopPropagation()

    try {
      const response = await fetch(this.urlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfToken,
          "Accept": "application/json"
        }
      })

      if (response.ok) {
        const data = await response.json()
        this.bookmarkedValue = data.bookmarked
        this.updateUI()
        this.animateBookmark()
      } else if (response.status === 401) {
        // 로그인 필요
        window.location.href = "/login"
      }
    } catch (error) {
      console.error("Bookmark toggle failed:", error)
    }
  }

  updateUI() {
    if (this.hasIconTarget) {
      if (this.bookmarkedValue) {
        // 스크랩된 상태: 채워진 북마크
        this.iconTarget.innerHTML = this.filledBookmarkSVG
        this.iconTarget.classList.add("text-yellow-500")
        this.iconTarget.classList.remove("text-muted-foreground")
      } else {
        // 스크랩 안된 상태: 빈 북마크
        this.iconTarget.innerHTML = this.outlineBookmarkSVG
        this.iconTarget.classList.remove("text-yellow-500")
        this.iconTarget.classList.add("text-muted-foreground")
      }
    }
  }

  animateBookmark() {
    if (this.hasIconTarget) {
      this.iconTarget.classList.add("scale-125")
      setTimeout(() => {
        this.iconTarget.classList.remove("scale-125")
      }, 150)
    }
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content || ""
  }

  get filledBookmarkSVG() {
    return `<svg class="h-5 w-5 transition-transform" fill="currentColor" viewBox="0 0 24 24">
      <path d="M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z"/>
    </svg>`
  }

  get outlineBookmarkSVG() {
    return `<svg class="h-5 w-5 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z"/>
    </svg>`
  }
}
