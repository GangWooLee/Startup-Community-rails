import { Controller } from "@hotwired/stimulus"
import { getCsrfToken, handleUnauthorized, animateIcon } from "controllers/mixins/toggle_button_mixin"

// 좋아요 버튼 컨트롤러
// 사용법: data-controller="like-button"
//        data-like-button-url-value="/posts/1/like"
//        data-like-button-liked-value="false"
export default class extends Controller {
  static values = {
    url: String,
    liked: Boolean
  }

  static targets = ["icon", "count"]

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
          "X-CSRF-Token": getCsrfToken(),
          "Accept": "application/json"
        }
      })

      if (handleUnauthorized(response)) return

      if (response.ok) {
        const data = await response.json()
        this.likedValue = data.liked
        this.updateCount(data.likes_count)
        this.updateUI()
        animateIcon(this.iconTarget, 150)
      }
    } catch (error) {
      console.error("Like toggle failed:", error)
    }
  }

  updateUI() {
    if (!this.hasIconTarget) return

    if (this.likedValue) {
      // Static SVG - no XSS risk (hardcoded content, not user input)
      this.iconTarget.innerHTML = this.filledHeartSVG
      this.iconTarget.classList.add("text-red-500")
      this.iconTarget.classList.remove("text-muted-foreground")
    } else {
      this.iconTarget.innerHTML = this.outlineHeartSVG
      this.iconTarget.classList.remove("text-red-500")
      this.iconTarget.classList.add("text-muted-foreground")
    }
  }

  updateCount(count) {
    if (this.hasCountTarget) {
      this.countTarget.textContent = count
    }
  }

  get filledHeartSVG() {
    return `<svg class="h-5 w-5 transition-transform" fill="currentColor" viewBox="0 0 24 24">
      <path d="M11.645 20.91l-.007-.003-.022-.012a15.247 15.247 0 01-.383-.218 25.18 25.18 0 01-4.244-3.17C4.688 15.36 2.25 12.174 2.25 8.25 2.25 5.322 4.714 3 7.688 3A5.5 5.5 0 0112 5.052 5.5 5.5 0 0116.313 3c2.973 0 5.437 2.322 5.437 5.25 0 3.925-2.438 7.111-4.739 9.256a25.175 25.175 0 01-4.244 3.17 15.247 15.247 0 01-.383.219l-.022.012-.007.004-.003.001a.752.752 0 01-.704 0l-.003-.001z"/>
    </svg>`
  }

  get outlineHeartSVG() {
    return `<svg class="h-5 w-5 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"/>
    </svg>`
  }
}
