import { Controller } from "@hotwired/stimulus"

// 토스페이먼츠 결제 위젯 컨트롤러
// TossPayments Payment Widget v2 SDK 연동
export default class extends Controller {
  static values = {
    clientKey: String,
    customerKey: String,
    orderId: String,
    orderName: String,
    amount: Number,
    customerName: String,
    customerEmail: String,
    successUrl: String,
    failUrl: String
  }

  static targets = [
    "paymentMethods",
    "agreement",
    "payButton",
    "loading",
    "error",
    "errorMessage"
  ]

  connect() {
    this.paymentWidget = null
    this.paymentMethodsWidget = null
    this.agreementWidget = null
    this.isReady = false

    this.loadTossPaymentsSDK()
  }

  disconnect() {
    // 위젯 정리
    this.paymentWidget = null
    this.paymentMethodsWidget = null
    this.agreementWidget = null
  }

  // TossPayments SDK 로드
  async loadTossPaymentsSDK() {
    try {
      this.showLoading()

      // SDK가 이미 로드되어 있는지 확인
      if (window.TossPayments) {
        await this.initializeWidget()
        return
      }

      // SDK 스크립트 로드
      const script = document.createElement("script")
      script.src = "https://js.tosspayments.com/v2/standard"
      script.async = true

      script.onload = async () => {
        await this.initializeWidget()
      }

      script.onerror = () => {
        this.showError("결제 모듈을 불러오는데 실패했습니다.")
      }

      document.head.appendChild(script)
    } catch (error) {
      console.error("[PaymentWidget] SDK load error:", error)
      this.showError("결제 모듈 초기화에 실패했습니다.")
    }
  }

  // 결제 위젯 초기화
  async initializeWidget() {
    try {
      // TossPayments 인스턴스 생성
      const tossPayments = TossPayments(this.clientKeyValue)

      // 결제 위젯 생성
      this.paymentWidget = tossPayments.widgets({
        customerKey: this.customerKeyValue
      })

      // 금액 설정
      await this.paymentWidget.setAmount({
        currency: "KRW",
        value: this.amountValue
      })

      // 결제 수단 위젯 렌더링
      await this.renderPaymentMethods()

      // 약관 동의 위젯 렌더링
      await this.renderAgreement()

      this.isReady = true
      this.hideLoading()
      this.enablePayButton()

      console.log("[PaymentWidget] Widget initialized successfully")
    } catch (error) {
      console.error("[PaymentWidget] Widget initialization error:", error)
      this.showError("결제 위젯 초기화에 실패했습니다.")
    }
  }

  // 결제 수단 위젯 렌더링
  async renderPaymentMethods() {
    if (!this.hasPaymentMethodsTarget) return

    this.paymentMethodsWidget = this.paymentWidget.renderPaymentMethods({
      selector: "#" + this.paymentMethodsTarget.id,
      variantKey: "DEFAULT"
    })

    return this.paymentMethodsWidget
  }

  // 약관 동의 위젯 렌더링
  async renderAgreement() {
    if (!this.hasAgreementTarget) return

    this.agreementWidget = this.paymentWidget.renderAgreement({
      selector: "#" + this.agreementTarget.id,
      variantKey: "AGREEMENT"
    })

    return this.agreementWidget
  }

  // 결제 요청
  async requestPayment(event) {
    event.preventDefault()

    if (!this.isReady) {
      this.showError("결제 준비 중입니다. 잠시 후 다시 시도해주세요.")
      return
    }

    try {
      this.disablePayButton()
      this.showLoading()

      await this.paymentWidget.requestPayment({
        orderId: this.orderIdValue,
        orderName: this.orderNameValue,
        customerName: this.customerNameValue,
        customerEmail: this.customerEmailValue,
        successUrl: this.successUrlValue,
        failUrl: this.failUrlValue
      })
    } catch (error) {
      console.error("[PaymentWidget] Payment request error:", error)

      // 사용자가 결제를 취소한 경우
      if (error.code === "USER_CANCEL") {
        this.hideLoading()
        this.enablePayButton()
        return
      }

      this.showError(error.message || "결제 요청 중 오류가 발생했습니다.")
      this.hideLoading()
      this.enablePayButton()
    }
  }

  // 금액 변경 (필요 시)
  async updateAmount(newAmount) {
    if (!this.paymentWidget) return

    try {
      await this.paymentWidget.setAmount({
        currency: "KRW",
        value: newAmount
      })
      this.amountValue = newAmount
    } catch (error) {
      console.error("[PaymentWidget] Amount update error:", error)
    }
  }

  // UI 헬퍼 메서드
  showLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.remove("hidden")
    }
  }

  hideLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.add("hidden")
    }
  }

  showError(message) {
    if (this.hasErrorTarget) {
      if (this.hasErrorMessageTarget) {
        this.errorMessageTarget.textContent = message
      } else {
        // Fallback for old template structure
        this.errorTarget.textContent = message
      }
      this.errorTarget.classList.remove("hidden")

      // 5초 후 자동으로 에러 메시지 숨기기
      this.errorTimeout = setTimeout(() => {
        this.hideError()
      }, 5000)
    }
    this.hideLoading()
  }

  hideError() {
    if (this.hasErrorTarget) {
      this.errorTarget.classList.add("hidden")
    }
    if (this.errorTimeout) {
      clearTimeout(this.errorTimeout)
      this.errorTimeout = null
    }
  }

  dismissError(event) {
    event.preventDefault()
    this.hideError()
  }

  enablePayButton() {
    if (this.hasPayButtonTarget) {
      this.payButtonTarget.disabled = false
      this.payButtonTarget.classList.remove("opacity-50", "cursor-not-allowed")
    }
  }

  disablePayButton() {
    if (this.hasPayButtonTarget) {
      this.payButtonTarget.disabled = true
      this.payButtonTarget.classList.add("opacity-50", "cursor-not-allowed")
    }
  }
}
