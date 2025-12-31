import { Controller } from "@hotwired/stimulus"

// 공유 기능 컨트롤러
// Web Share API, 클립보드 복사, 카카오 공유 지원
export default class extends Controller {
  static targets = ["overlay", "sheet", "toast"]
  static values = {
    url: String,
    title: String,
    description: String,
    imageUrl: String  // 카카오 공유용 이미지 URL
  }

  connect() {
    // ESC 키로 닫기
    this.boundHandleKeydown = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this.boundHandleKeydown)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundHandleKeydown)
  }

  // 바텀시트 열기
  open() {
    // 하단 네비게이션 바 숨기기
    this.hideBottomNav()

    this.overlayTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"

    requestAnimationFrame(() => {
      this.overlayTarget.classList.remove("opacity-0")
      this.overlayTarget.classList.add("opacity-100")
      this.sheetTarget.classList.remove("translate-y-full")
      this.sheetTarget.classList.add("translate-y-0")
    })
  }

  // 바텀시트 닫기
  close() {
    this.overlayTarget.classList.remove("opacity-100")
    this.overlayTarget.classList.add("opacity-0")
    this.sheetTarget.classList.remove("translate-y-0")
    this.sheetTarget.classList.add("translate-y-full")

    setTimeout(() => {
      this.overlayTarget.classList.add("hidden")
      document.body.style.overflow = ""
      // 하단 네비게이션 바 다시 표시
      this.showBottomNav()
    }, 300)
  }

  // 하단 네비게이션 바 숨기기
  hideBottomNav() {
    const bottomNav = document.querySelector("nav.fixed.bottom-0")
    if (bottomNav) {
      bottomNav.style.transform = "translateY(100%)"
      bottomNav.style.transition = "transform 0.3s ease-out"
    }
  }

  // 하단 네비게이션 바 표시
  showBottomNav() {
    const bottomNav = document.querySelector("nav.fixed.bottom-0")
    if (bottomNav) {
      bottomNav.style.transform = "translateY(0)"
    }
  }

  handleKeydown(event) {
    if (event.key === "Escape" && !this.overlayTarget.classList.contains("hidden")) {
      this.close()
    }
  }

  // 이벤트 버블링 중지 (바텀시트 클릭 시 닫히지 않도록)
  stopPropagation(event) {
    event.stopPropagation()
  }

  // 네이티브 공유 (Web Share API)
  async nativeShare() {
    if (navigator.share) {
      try {
        await navigator.share({
          title: this.titleValue,
          text: this.descriptionValue,
          url: this.urlValue
        })
        this.close()
      } catch (err) {
        // 사용자가 취소한 경우 무시
        if (err.name !== "AbortError") {
          console.error("공유 실패:", err)
        }
      }
    } else {
      // Web Share API 미지원 시 URL 복사
      this.copyUrl()
    }
  }

  // URL 클립보드 복사
  async copyUrl() {
    try {
      await navigator.clipboard.writeText(this.urlValue)
      this.showToast("링크가 복사되었습니다")
      this.close()
    } catch (err) {
      // 폴백: 임시 텍스트 영역 사용
      const textArea = document.createElement("textarea")
      textArea.value = this.urlValue
      textArea.style.position = "fixed"
      textArea.style.left = "-9999px"
      document.body.appendChild(textArea)
      textArea.select()
      try {
        document.execCommand("copy")
        this.showToast("링크가 복사되었습니다")
        this.close()
      } catch (e) {
        this.showToast("복사에 실패했습니다")
      }
      document.body.removeChild(textArea)
    }
  }

  // 카카오톡 공유
  shareKakao() {
    // 카카오 SDK가 로드되어 있는지 확인
    if (typeof Kakao === "undefined") {
      console.warn("Kakao SDK not loaded")
      this.showToast("카카오톡 공유를 사용할 수 없습니다")
      return
    }

    // SDK 초기화 확인
    if (!Kakao.isInitialized()) {
      console.warn("Kakao SDK not initialized")
      this.showToast("카카오톡 공유를 사용할 수 없습니다")
      return
    }

    // 공유 URL 확인
    const shareUrl = this.urlValue
    if (!shareUrl) {
      console.error("Share URL is required")
      this.showToast("공유할 URL이 없습니다")
      return
    }

    // 이미지 URL 설정 (없으면 기본 이미지 사용)
    const imageUrl = this.hasImageUrlValue && this.imageUrlValue
      ? this.imageUrlValue
      : this.getDefaultImageUrl()

    // 설명 텍스트 (200자 제한)
    const description = this.descriptionValue
      ? this.descriptionValue.substring(0, 200)
      : ""

    try {
      Kakao.Share.sendDefault({
        objectType: "feed",
        content: {
          title: this.titleValue || "Undrew",
          description: description,
          imageUrl: imageUrl,
          link: {
            mobileWebUrl: shareUrl,
            webUrl: shareUrl
          }
        },
        buttons: [
          {
            title: "자세히 보기",
            link: {
              mobileWebUrl: shareUrl,
              webUrl: shareUrl
            }
          }
        ]
      })
      this.close()
    } catch (err) {
      console.error("카카오 공유 실패:", err)
      this.showToast("카카오톡 공유에 실패했습니다")
    }
  }

  // 기본 이미지 URL (OG 이미지 또는 사이트 아이콘)
  getDefaultImageUrl() {
    // 1. 페이지의 og:image 태그에서 가져오기
    const ogImage = document.querySelector('meta[property="og:image"]')
    if (ogImage && ogImage.content) {
      return ogImage.content
    }

    // 2. 기본 사이트 아이콘 사용
    const baseUrl = window.location.origin
    return `${baseUrl}/icon.png`
  }

  // 트위터(X) 공유
  shareTwitter() {
    const text = encodeURIComponent(this.titleValue)
    const url = encodeURIComponent(this.urlValue)
    window.open(`https://twitter.com/intent/tweet?text=${text}&url=${url}`, "_blank", "width=550,height=420")
    this.close()
  }

  // 페이스북 공유
  shareFacebook() {
    const url = encodeURIComponent(this.urlValue)
    window.open(`https://www.facebook.com/sharer/sharer.php?u=${url}`, "_blank", "width=550,height=420")
    this.close()
  }

  // Threads 공유 (Meta Web Intents API)
  shareThreads() {
    const text = encodeURIComponent(this.titleValue)
    const url = encodeURIComponent(this.urlValue)
    window.open(`https://www.threads.net/intent/post?text=${text}&url=${url}`, "_blank", "width=550,height=620")
    this.close()
  }

  // 토스트 메시지 표시
  showToast(message) {
    if (!this.hasToastTarget) {
      // 토스트 요소가 없으면 임시 생성
      const toast = document.createElement("div")
      toast.className = "fixed bottom-32 left-1/2 -translate-x-1/2 bg-primary text-primary-foreground px-4 py-2 rounded-lg shadow-lg text-sm font-medium z-[110] animate-fade-in"
      toast.textContent = message
      document.body.appendChild(toast)

      setTimeout(() => {
        toast.classList.add("opacity-0", "transition-opacity")
        setTimeout(() => toast.remove(), 300)
      }, 2000)
      return
    }

    this.toastTarget.textContent = message
    this.toastTarget.classList.remove("hidden", "opacity-0")
    this.toastTarget.classList.add("opacity-100")

    setTimeout(() => {
      this.toastTarget.classList.remove("opacity-100")
      this.toastTarget.classList.add("opacity-0")
      setTimeout(() => {
        this.toastTarget.classList.add("hidden")
      }, 300)
    }, 2000)
  }
}
