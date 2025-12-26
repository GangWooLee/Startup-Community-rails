import { Controller } from "@hotwired/stimulus"

// 거래 제안 모달 컨트롤러
export default class extends Controller {
  static targets = ["modal", "amountInput", "netAmount", "submitButton"]

  // 플랫폼 수수료율 (10%)
  static FEE_RATE = 0.10

  connect() {
    // ESC 키로 모달 닫기
    this.boundHandleKeydown = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this.boundHandleKeydown)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundHandleKeydown)
  }

  handleKeydown(event) {
    if (event.key === "Escape" && this.isOpen) {
      this.close()
    }
  }

  get isOpen() {
    return this.hasModalTarget && !this.modalTarget.classList.contains("hidden")
  }

  open() {
    if (!this.hasModalTarget) return

    this.modalTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"

    // 금액 입력에 포커스
    if (this.hasAmountInputTarget) {
      setTimeout(() => this.amountInputTarget.focus(), 100)
    }
  }

  close() {
    if (!this.hasModalTarget) return

    this.modalTarget.classList.add("hidden")
    document.body.style.overflow = ""
  }

  // 금액 포맷팅 (1000 -> 1,000)
  formatAmount(event) {
    const input = event.target
    let value = input.value.replace(/[^\d]/g, "")

    if (value) {
      value = parseInt(value, 10).toLocaleString("ko-KR")
    }

    input.value = value
  }

  // 정산 금액 계산 (10% 수수료 제외)
  calculateNet() {
    if (!this.hasAmountInputTarget || !this.hasNetAmountTarget) return

    const rawValue = this.amountInputTarget.value.replace(/[^\d]/g, "")
    const amount = parseInt(rawValue, 10) || 0
    const fee = Math.floor(amount * this.constructor.FEE_RATE)
    const net = amount - fee

    this.netAmountTarget.textContent = net.toLocaleString("ko-KR")
  }

  // 폼 제출 후 처리
  handleSubmit(event) {
    // 성공적으로 제출되면 모달 닫기
    if (event.detail.success) {
      this.close()

      // 폼 리셋
      const form = event.target
      if (form && form.reset) {
        form.reset()
      }

      // 정산 금액 초기화
      if (this.hasNetAmountTarget) {
        this.netAmountTarget.textContent = "0"
      }
    }
  }
}
