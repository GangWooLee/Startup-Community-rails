import { Controller } from "@hotwired/stimulus"

/**
 * Bridge Share Controller - 네이티브 공유 시트
 *
 * Hotwire Native 앱에서 네이티브 공유 시트를 표시합니다.
 * 웹에서는 Web Share API 또는 폴백 UI를 사용합니다.
 *
 * 사용법:
 *   <button data-controller="bridge--share"
 *           data-bridge--share-title-value="게시글 공유"
 *           data-bridge--share-text-value="이 게시글을 확인해보세요!"
 *           data-bridge--share-url-value="https://undrewai.com/posts/1"
 *           data-action="click->bridge--share#share">
 *     공유하기
 *   </button>
 */
export default class extends Controller {
  static values = {
    title: String,
    text: String,
    url: String,
    imageUrl: String  // 공유할 이미지 URL (선택)
  }

  get isNativeApp() {
    return navigator.userAgent.includes("Turbo Native")
  }

  // 현재 페이지 URL (기본값)
  get shareUrl() {
    return this.urlValue || window.location.href
  }

  /**
   * 공유 시트 표시
   */
  async share(event) {
    event?.preventDefault()

    if (this.isNativeApp) {
      this.shareNative()
    } else {
      await this.shareWeb()
    }
  }

  // ==========================================================================
  // Native App 처리
  // ==========================================================================

  shareNative() {
    const message = {
      title: this.titleValue,
      text: this.textValue,
      url: this.shareUrl,
      imageUrl: this.imageUrlValue
    }

    if (window.webkit?.messageHandlers?.nativeApp) {
      window.webkit.messageHandlers.nativeApp.postMessage({
        component: "share",
        action: "show",
        data: message
      })
    } else if (window.NativeApp?.postMessage) {
      window.NativeApp.postMessage(JSON.stringify({
        component: "share",
        action: "show",
        data: message
      }))
    } else {
      this.shareWeb()
    }
  }

  // ==========================================================================
  // Web 처리 (Web Share API)
  // ==========================================================================

  async shareWeb() {
    const shareData = {
      title: this.titleValue,
      text: this.textValue,
      url: this.shareUrl
    }

    // Web Share API 지원 확인
    if (navigator.share && navigator.canShare?.(shareData)) {
      try {
        await navigator.share(shareData)
        this.onShareSuccess()
      } catch (err) {
        if (err.name !== "AbortError") {
          console.error("Share failed:", err)
          this.showFallbackShare()
        }
      }
    } else {
      this.showFallbackShare()
    }
  }

  /**
   * 폴백 공유 UI (Web Share API 미지원 시)
   */
  showFallbackShare() {
    // 클립보드에 URL 복사
    this.copyToClipboard(this.shareUrl)
  }

  async copyToClipboard(text) {
    try {
      await navigator.clipboard.writeText(text)
      this.showCopySuccess()
    } catch (err) {
      // 폴백: 구형 브라우저
      const textarea = document.createElement("textarea")
      textarea.value = text
      textarea.style.position = "fixed"
      textarea.style.opacity = "0"
      document.body.appendChild(textarea)
      textarea.select()
      document.execCommand("copy")
      document.body.removeChild(textarea)
      this.showCopySuccess()
    }
  }

  showCopySuccess() {
    // Toast 메시지 표시
    this.element.dispatchEvent(new CustomEvent("bridge:share:copied", {
      bubbles: true,
      detail: { url: this.shareUrl }
    }))

    // 간단한 알림 (toast 컨트롤러가 없는 경우)
    const toast = document.getElementById("share-toast")
    if (toast) {
      toast.textContent = "링크가 복사되었습니다"
      toast.classList.remove("hidden")
      setTimeout(() => toast.classList.add("hidden"), 2000)
    }
  }

  onShareSuccess() {
    this.element.dispatchEvent(new CustomEvent("bridge:share:success", {
      bubbles: true
    }))
  }
}
