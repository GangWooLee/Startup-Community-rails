import { Controller } from "@hotwired/stimulus"
import { getCsrfToken, handleUnauthorized, animateIcon } from "controllers/mixins/toggle_button_mixin"

export default class extends Controller {
  static values = { url: String, liked: Boolean, commentId: Number }
  static targets = ["icon"]

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
        this.updateIconUI()
        this.updateMetadataUI(data.likes_count)
        animateIcon(this.iconTarget, 150)
      }
    } catch (error) {
      console.error("Comment like toggle failed:", error)
    }
  }

  // 우측 아이콘 업데이트
  updateIconUI() {
    if (!this.hasIconTarget) return

    // Static SVG - no XSS risk (hardcoded content, not user input)
    this.iconTarget.innerHTML = this.likedValue ? this.filledHeartSVG : this.outlineHeartSVG
    this.iconTarget.classList.toggle("text-red-500", this.likedValue)
    this.iconTarget.classList.toggle("text-muted-foreground", !this.likedValue)
    this.iconTarget.classList.toggle("hover:text-red-500", !this.likedValue)
  }

  // 메타데이터 영역 좋아요 개수 업데이트
  updateMetadataUI(count) {
    const commentId = this.commentIdValue
    const metadataContainer = document.getElementById(`comment-likes-count-${commentId}`)
    const metadataRow = this.element.closest('[data-controller="reply-toggle"]')?.querySelector('.flex.items-center.gap-3.mt-1')

    if (count > 0) {
      if (metadataContainer) {
        const countSpan = metadataContainer.querySelector('[data-comment-likes-count]')
        if (countSpan) {
          // Using textContent for count - safe from XSS
          countSpan.textContent = `${count}개`
        }
      } else if (metadataRow) {
        const timeSpan = metadataRow.querySelector('span.text-xs.text-muted-foreground')
        if (timeSpan) {
          // Static HTML template with dynamic count inserted via textContent
          const newLikesSpan = document.createElement('span')
          newLikesSpan.id = `comment-likes-count-${commentId}`
          newLikesSpan.className = 'inline-flex items-center gap-1 text-xs font-medium text-muted-foreground'

          // Build DOM structure safely
          const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg')
          svg.setAttribute('class', 'h-3 w-3')
          svg.setAttribute('fill', 'currentColor')
          svg.setAttribute('viewBox', '0 0 24 24')
          const path = document.createElementNS('http://www.w3.org/2000/svg', 'path')
          path.setAttribute('d', 'M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.126-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.765 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12z')
          svg.appendChild(path)

          const countSpan = document.createElement('span')
          countSpan.setAttribute('data-comment-likes-count', '')
          countSpan.textContent = `${count}개`

          newLikesSpan.appendChild(svg)
          newLikesSpan.appendChild(countSpan)
          timeSpan.insertAdjacentElement('afterend', newLikesSpan)
        }
      }
    } else if (metadataContainer) {
      metadataContainer.remove()
    }
  }

  get filledHeartSVG() {
    return `<svg class="h-3 w-3" fill="currentColor" viewBox="0 0 24 24">
      <path d="M11.645 20.91l-.007-.003-.022-.012a15.247 15.247 0 01-.383-.218 25.18 25.18 0 01-4.244-3.17C4.688 15.36 2.25 12.174 2.25 8.25 2.25 5.322 4.714 3 7.688 3A5.5 5.5 0 0112 5.052 5.5 5.5 0 0116.313 3c2.973 0 5.437 2.322 5.437 5.25 0 3.925-2.438 7.111-4.739 9.256a25.175 25.175 0 01-4.244 3.17 15.247 15.247 0 01-.383.219l-.022.012-.007.004-.003.001a.752.752 0 01-.704 0l-.003-.001z"/>
    </svg>`
  }

  get outlineHeartSVG() {
    return `<svg class="h-3 w-3" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" d="M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.126-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.765 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12z"/>
    </svg>`
  }
}
