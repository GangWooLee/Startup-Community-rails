import { Controller } from "@hotwired/stimulus"

/**
 * Anonymous Settings Controller
 * 마이페이지에서 익명 설정을 관리하는 컨트롤러
 *
 * Features:
 * - 익명 모드 토글 시 닉네임/아바타 섹션 표시/숨김
 * - 아바타 선택 시 시각적 피드백
 * - 닉네임 입력 시 미리보기 업데이트
 * - 랜덤 닉네임 생성
 */
export default class extends Controller {
  static targets = ["toggle", "nicknameSection", "privacySection", "nickname", "avatar", "avatarInput", "preview"]

  connect() {
    this.updatePreview()
  }

  /**
   * 익명 모드 토글
   */
  toggleMode() {
    const isAnonymous = this.toggleTarget.checked

    if (isAnonymous) {
      this.nicknameSectionTarget.classList.remove("hidden")
      // 프라이버시 섹션도 표시 (nicknameSection 안에 있으므로 자동으로 표시됨)
      // 닉네임이 없으면 자동 생성
      if (!this.nicknameTarget.value.trim()) {
        this.regenerateNickname()
      }
    } else {
      this.nicknameSectionTarget.classList.add("hidden")
    }

    this.updatePreview()
  }

  /**
   * 아바타 선택
   */
  selectAvatar(event) {
    const button = event.currentTarget
    const index = parseInt(button.dataset.avatarIndex, 10)

    // 모든 아바타 비활성화 스타일
    this.avatarTargets.forEach(avatar => {
      avatar.classList.remove("ring-4", "ring-primary/50", "scale-110")
      avatar.classList.add("opacity-60", "grayscale")
    })

    // 선택된 아바타 활성화 스타일
    button.classList.remove("opacity-60", "grayscale")
    button.classList.add("ring-4", "ring-primary/50", "scale-110")

    // hidden input 값 업데이트
    this.avatarInputTarget.value = index
  }

  /**
   * 미리보기 업데이트
   */
  updatePreview() {
    const isAnonymous = this.toggleTarget.checked
    const nickname = this.nicknameTarget.value.trim()

    if (isAnonymous && nickname) {
      this.previewTarget.textContent = nickname
    } else if (isAnonymous) {
      this.previewTarget.textContent = "닉네임을 입력하세요"
    } else {
      // 실명 모드일 때는 서버에서 받은 이름 유지
      // (이미 페이지에 렌더링된 값이 있으므로 초기값 복원)
      const nameInput = document.getElementById("user_name")
      if (nameInput) {
        this.previewTarget.textContent = nameInput.value
      }
    }
  }

  /**
   * 랜덤 닉네임 생성
   */
  regenerateNickname() {
    const adjectives = [
      "빠른", "조용한", "행복한", "용감한", "지혜로운",
      "재빠른", "신중한", "열정적인", "차분한", "도전적인",
      "창의적인", "긍정적인", "활기찬", "사려깊은", "호기심많은"
    ]

    const nouns = [
      "판다", "여우", "올빼미", "고래", "독수리",
      "호랑이", "사자", "토끼", "거북이", "돌고래",
      "코끼리", "펭귄", "늑대", "곰", "사슴"
    ]

    const randomAdj = adjectives[Math.floor(Math.random() * adjectives.length)]
    const randomNoun = nouns[Math.floor(Math.random() * nouns.length)]
    const randomNum = Math.floor(Math.random() * 1000)

    const nickname = `${randomAdj}${randomNoun}${randomNum}`
    this.nicknameTarget.value = nickname
    this.updatePreview()

    // 애니메이션 효과
    this.nicknameTarget.classList.add("animate-pulse")
    setTimeout(() => {
      this.nicknameTarget.classList.remove("animate-pulse")
    }, 300)
  }
}
