import { Controller } from "@hotwired/stimulus"

// 회원가입 후 익명 프로필 설정 페이지 컨트롤러
// 기능: 아바타 선택, 닉네임 재생성
export default class extends Controller {
  static targets = ["nickname", "avatar", "avatarInput"]
  static values = { selectedAvatar: Number }

  connect() {
    // 초기 아바타 선택 상태 반영
    this.updateAvatarSelection()
  }

  // 아바타 클릭 시 선택 상태 변경
  selectAvatar(event) {
    const avatarIndex = parseInt(event.currentTarget.dataset.avatarIndex)
    this.selectedAvatarValue = avatarIndex
    this.updateAvatarSelection()
  }

  // 모든 아바타의 선택 상태 UI 업데이트
  updateAvatarSelection() {
    this.avatarTargets.forEach((avatar, index) => {
      if (index === this.selectedAvatarValue) {
        // 선택된 아바타
        avatar.classList.add("ring-4", "ring-orange-200", "scale-110")
        avatar.classList.remove("opacity-50", "grayscale")
      } else {
        // 선택되지 않은 아바타
        avatar.classList.remove("ring-4", "ring-orange-200", "scale-110")
        avatar.classList.add("opacity-50", "grayscale")
      }
    })

    // hidden input 업데이트
    if (this.hasAvatarInputTarget) {
      this.avatarInputTarget.value = this.selectedAvatarValue
    }
  }

  // 닉네임 재생성 버튼 클릭
  async regenerateNickname(event) {
    event.preventDefault()

    const button = event.currentTarget
    const originalText = button.textContent

    // 로딩 상태
    button.textContent = "..."
    button.disabled = true

    try {
      const response = await fetch("/welcome/regenerate_nickname", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfToken
        }
      })

      if (response.ok) {
        const data = await response.json()
        this.nicknameTarget.value = data.nickname

        // 입력 필드에 포커스 효과
        this.nicknameTarget.classList.add("ring-2", "ring-orange-300")
        setTimeout(() => {
          this.nicknameTarget.classList.remove("ring-2", "ring-orange-300")
        }, 500)
      }
    } catch (error) {
      console.error("닉네임 재생성 실패:", error)
    } finally {
      button.textContent = originalText
      button.disabled = false
    }
  }

  // CSRF 토큰 가져오기
  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content || ""
  }
}
