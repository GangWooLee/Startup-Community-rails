import { Controller } from "@hotwired/stimulus"

// 회원가입 후 익명 프로필 설정 페이지 컨트롤러
// 기능: 아바타 선택, 닉네임 재생성, 익명 모드 토글
export default class extends Controller {
  static targets = [
    "nickname", "avatar", "avatarInput", "counter",
    "anonymousCheckbox", "nicknameSection", "avatarSection",
    "regenerateBtn", "disabledHint"
  ]
  static values = { selectedAvatar: Number }

  connect() {
    // 초기 아바타 선택 상태 반영
    this.updateAvatarSelection()
    // 초기 카운터 상태 반영
    this.updateCounter()
    // 초기 익명 모드 상태 반영
    this.updateAnonymousUI()
  }

  // 익명 모드 토글 시 UI 업데이트
  toggleAnonymous() {
    this.updateAnonymousUI()
  }

  // 익명 모드에 따른 UI 상태 업데이트
  updateAnonymousUI() {
    if (!this.hasAnonymousCheckboxTarget) return

    const isAnonymous = this.anonymousCheckboxTarget.checked

    // 닉네임 섹션 활성화/비활성화
    if (this.hasNicknameSectionTarget) {
      if (isAnonymous) {
        this.nicknameSectionTarget.classList.remove("opacity-50", "pointer-events-none")
      } else {
        this.nicknameSectionTarget.classList.add("opacity-50", "pointer-events-none")
      }
    }

    // 아바타 섹션 활성화/비활성화
    if (this.hasAvatarSectionTarget) {
      if (isAnonymous) {
        this.avatarSectionTarget.classList.remove("opacity-50", "pointer-events-none")
      } else {
        this.avatarSectionTarget.classList.add("opacity-50", "pointer-events-none")
      }
    }

    // 비활성화 안내 문구 표시/숨김
    if (this.hasDisabledHintTarget) {
      if (isAnonymous) {
        this.disabledHintTarget.classList.add("hidden")
      } else {
        this.disabledHintTarget.classList.remove("hidden")
      }
    }
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

        // 카운터 업데이트
        this.updateCounter()

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

  // 닉네임 글자 수 카운터 업데이트
  updateCounter() {
    if (!this.hasCounterTarget || !this.hasNicknameTarget) return

    const length = this.nicknameTarget.value.length
    const maxLength = 20
    const minLength = 2

    let colorClass = "text-stone-400"  // 기본 (빈 상태)
    if (length > 0 && length < minLength) {
      colorClass = "text-red-500"  // 최소 미달 (1자)
    } else if (length >= minLength && length <= maxLength) {
      colorClass = "text-green-500"  // 유효 범위 (2-20자)
    }

    // 안전한 DOM API 사용 (XSS 방지)
    this.counterTarget.textContent = ""
    const countSpan = document.createElement("span")
    countSpan.className = colorClass
    countSpan.textContent = length.toString()
    const maxSpan = document.createElement("span")
    maxSpan.className = "text-stone-400"
    maxSpan.textContent = `/${maxLength}`
    this.counterTarget.appendChild(countSpan)
    this.counterTarget.appendChild(maxSpan)
  }
}
