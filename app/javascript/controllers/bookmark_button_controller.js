import { Controller } from "@hotwired/stimulus"
import { getCsrfToken, handleUnauthorized, animateIcon } from "controllers/mixins/toggle_button_mixin"

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

    // 모바일 Haptic 피드백
    this.triggerHapticFeedback()

    try {
      const response = await fetch(this.urlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": getCsrfToken(),
          "Accept": "application/json"
        }
      })

      if (handleUnauthorized(response)) return

      if (response.ok) {
        const data = await response.json()
        this.bookmarkedValue = data.bookmarked
        this.updateUI()
        animateIcon(this.iconTarget, 150)

        // 북마크 추가 시 강한 Haptic 피드백
        if (data.bookmarked) {
          this.triggerHapticFeedback("medium")
        }
      }
    } catch (error) {
      console.error("Bookmark toggle failed:", error)
    }
  }

  // Haptic 피드백 (모바일 진동)
  triggerHapticFeedback(intensity = "light") {
    if (!navigator.vibrate) return

    switch (intensity) {
      case "light":
        navigator.vibrate(10)
        break
      case "medium":
        navigator.vibrate(20)
        break
      case "heavy":
        navigator.vibrate([30, 10, 30])
        break
    }
  }

  updateUI() {
    if (!this.hasIconTarget) return

    if (this.bookmarkedValue) {
      // Static SVG - no XSS risk (hardcoded content, not user input)
      this.iconTarget.innerHTML = this.filledBookmarkSVG
      this.iconTarget.classList.add("text-yellow-500")
      this.iconTarget.classList.remove("text-muted-foreground")
    } else {
      this.iconTarget.innerHTML = this.outlineBookmarkSVG
      this.iconTarget.classList.remove("text-yellow-500")
      this.iconTarget.classList.add("text-muted-foreground")
    }
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
