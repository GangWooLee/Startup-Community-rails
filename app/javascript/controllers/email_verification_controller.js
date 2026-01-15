import { Controller } from "@hotwired/stimulus"

// 회원가입 이메일 인증 컨트롤러
// - 인증 코드 요청
// - 카운트다운 타이머
// - 인증 코드 확인
export default class extends Controller {
  static targets = [
    "emailInput",
    "sendButton",
    "codeSection",
    "codeInput",
    "timer",
    "verifyButton",
    "verifiedBadge",
    "submitButton"
  ]

  static values = {
    verified: { type: Boolean, default: false },
    sending: { type: Boolean, default: false },
    verifying: { type: Boolean, default: false }
  }

  // 환경 체크 (프로덕션에서는 디버그 로그 비활성화)
  get isDevelopment() {
    return document.documentElement.dataset.environment === "development"
  }

  connect() {
    this.remainingSeconds = 0
    this.timerInterval = null
    this.isSubmitting = false
    if (this.isDevelopment) console.log("[EmailVerification] Controller connected")
  }

  disconnect() {
    if (this.timerInterval) {
      clearInterval(this.timerInterval)
    }
  }

  // CSRF 토큰 가져오기
  getCSRFToken() {
    const metaTag = document.querySelector('meta[name="csrf-token"]')
    if (!metaTag) {
      console.error("[EmailVerification] CSRF meta tag not found!")
      return null
    }
    return metaTag.content
  }

  // 인증 코드 발송
  async sendCode(event) {
    event.preventDefault()
    if (this.isDevelopment) console.log("[EmailVerification] sendCode called")

    const email = this.emailInputTarget.value.trim()
    if (this.isDevelopment) console.log("[EmailVerification] Email:", email)

    if (!email) {
      this.showError("이메일을 입력해주세요.")
      return
    }

    if (this.sendingValue) {
      if (this.isDevelopment) console.log("[EmailVerification] Already sending, ignoring")
      return
    }

    const csrfToken = this.getCSRFToken()
    if (!csrfToken) {
      this.showError("페이지를 새로고침한 후 다시 시도해주세요.")
      return
    }

    this.sendingValue = true
    this.sendButtonTarget.disabled = true
    this.sendButtonTarget.textContent = "발송 중..."

    try {
      if (this.isDevelopment) console.log("[EmailVerification] Sending request to /email_verifications")
      const response = await fetch("/email_verifications", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken
        },
        body: JSON.stringify({ email })
      })

      if (this.isDevelopment) console.log("[EmailVerification] Response status:", response.status)
      const data = await response.json()
      if (this.isDevelopment) console.log("[EmailVerification] Response data:", data)

      if (data.success) {
        this.showCodeSection()
        this.startTimer(data.expires_in)
        this.showSuccess(data.message)
      } else {
        this.showError(data.message)
        this.resetSendButton()
      }
    } catch (error) {
      console.error("[EmailVerification] Error:", error)
      this.showError("오류가 발생했습니다. 다시 시도해주세요.")
      this.resetSendButton()
    } finally {
      this.sendingValue = false
    }
  }

  // 인증 코드 확인
  async verifyCode(event) {
    event?.preventDefault()
    if (this.isDevelopment) console.log("[EmailVerification] verifyCode called")

    const email = this.emailInputTarget.value.trim()
    const code = this.codeInputTarget.value.trim().toUpperCase()

    if (code.length !== 6) {
      return
    }

    if (this.verifyingValue) return

    const csrfToken = this.getCSRFToken()
    if (!csrfToken) {
      this.showError("페이지를 새로고침한 후 다시 시도해주세요.")
      return
    }

    this.verifyingValue = true
    this.verifyButtonTarget.disabled = true
    this.verifyButtonTarget.textContent = "확인 중..."

    try {
      const response = await fetch("/email_verifications/verify", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken
        },
        body: JSON.stringify({ email, code })
      })

      const data = await response.json()

      if (data.success) {
        this.verifiedValue = true
        this.showVerified()
        this.stopTimer()
        this.showSuccess(data.message)
      } else {
        this.showError(data.message)
        this.verifyButtonTarget.disabled = false
        this.verifyButtonTarget.textContent = "인증"
      }
    } catch (error) {
      this.showError("오류가 발생했습니다. 다시 시도해주세요.")
      this.verifyButtonTarget.disabled = false
      this.verifyButtonTarget.textContent = "인증"
    } finally {
      this.verifyingValue = false
    }
  }

  // 코드 입력 시 자동 검증 (6자리 입력 완료 시)
  onCodeInput() {
    const code = this.codeInputTarget.value.trim()
    if (code.length === 6 && !this.verifiedValue) {
      this.verifyCode()
    }
  }

  showCodeSection() {
    this.codeSectionTarget.classList.remove("hidden")

    // 재발송 시 기존 코드 입력 초기화
    this.codeInputTarget.value = ""
    this.codeInputTarget.disabled = false
    this.codeInputTarget.focus()

    // 인증 버튼 상태 리셋
    this.verifyButtonTarget.classList.remove("hidden")
    this.verifyButtonTarget.disabled = false
    this.verifyButtonTarget.textContent = "인증"
    this.verifiedBadgeTarget.classList.add("hidden")

    // 발송 버튼 상태
    this.sendButtonTarget.textContent = "재발송"
    this.sendButtonTarget.disabled = false

    // 타이머 표시 및 색상 리셋
    this.timerTarget.classList.remove("hidden")
    this.timerTarget.classList.remove("text-destructive")

    if (this.isDevelopment) console.log("[EmailVerification] Code section shown, input cleared")
  }

  startTimer(seconds) {
    this.remainingSeconds = seconds

    if (this.timerInterval) {
      clearInterval(this.timerInterval)
    }

    this.updateTimerDisplay()
    this.timerInterval = setInterval(() => {
      this.remainingSeconds--
      this.updateTimerDisplay()

      if (this.remainingSeconds <= 0) {
        this.stopTimer()
        this.showError("인증 시간이 만료되었습니다. 다시 시도해주세요.")
      }
    }, 1000)
  }

  stopTimer() {
    if (this.timerInterval) {
      clearInterval(this.timerInterval)
      this.timerInterval = null
    }
  }

  updateTimerDisplay() {
    const minutes = Math.floor(this.remainingSeconds / 60)
    const seconds = this.remainingSeconds % 60
    this.timerTarget.textContent = `${minutes}:${seconds.toString().padStart(2, "0")}`

    // 1분 미만이면 빨간색
    if (this.remainingSeconds < 60) {
      this.timerTarget.classList.add("text-destructive")
    } else {
      this.timerTarget.classList.remove("text-destructive")
    }
  }

  showVerified() {
    this.codeInputTarget.disabled = true
    this.verifyButtonTarget.classList.add("hidden")
    this.verifiedBadgeTarget.classList.remove("hidden")
    this.sendButtonTarget.disabled = true
    // disabled 대신 readonly 사용 - disabled input은 폼 제출 시 값이 전송되지 않음
    this.emailInputTarget.readOnly = true
    this.emailInputTarget.classList.add("bg-muted", "cursor-not-allowed")
    this.timerTarget.classList.add("hidden")

    // 회원가입 버튼 활성화
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = false
    }
  }

  resetSendButton() {
    this.sendButtonTarget.disabled = false
    this.sendButtonTarget.textContent = "인증 코드 받기"
  }

  showError(message) {
    // 기존 에러 메시지 제거
    const existingError = this.element.querySelector(".verification-error")
    if (existingError) existingError.remove()

    const errorDiv = document.createElement("div")
    errorDiv.className = "verification-error text-sm text-destructive mt-2"
    errorDiv.textContent = message
    this.codeSectionTarget.parentNode.insertBefore(errorDiv, this.codeSectionTarget.nextSibling)

    setTimeout(() => errorDiv.remove(), 5000)
  }

  showSuccess(message) {
    // 기존 메시지 제거
    const existingMsg = this.element.querySelector(".verification-success")
    if (existingMsg) existingMsg.remove()

    const successDiv = document.createElement("div")
    successDiv.className = "verification-success text-sm text-green-600 mt-2"
    successDiv.textContent = message
    this.codeSectionTarget.parentNode.insertBefore(successDiv, this.codeSectionTarget.nextSibling)

    setTimeout(() => successDiv.remove(), 3000)
  }

  // 폼 제출 핸들러 - 중복 제출 방지
  submitForm(event) {
    // 이미 제출 중이면 중복 제출 방지
    if (this.isSubmitting) {
      event.preventDefault()
      return
    }

    this.isSubmitting = true

    // 버튼 비활성화 및 로딩 표시
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = true
      this.submitButtonTarget.textContent = "처리 중..."
    }
  }
}
