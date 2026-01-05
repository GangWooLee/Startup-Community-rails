import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

/**
 * Creator's Canvas Modal Controller
 *
 * Notion/Medium 스타일의 몰입형 글쓰기 경험을 제공하는
 * Full-screen Modal Overlay 컨트롤러
 *
 * Features:
 * - Split layout: 70% 글쓰기 캔버스 + 30% 설정 패널
 * - 타입 전환: 커뮤니티 ↔ 외주 동적 설정 패널
 * - 미저장 변경사항 보호
 * - GPU 가속 애니메이션
 * - 모바일 반응형 (세로 스택)
 */
export default class extends Controller {
  static targets = [
    "backdrop",
    "panel",
    "form",
    "titleInput",
    "contentInput",
    "categoryField",
    "submitButton",
    "typeButton",
    "communitySettings",
    "outsourcingSettings",
    "serviceType",
    "validationHint"
  ]

  static values = {
    open: { type: Boolean, default: false },
    dirty: { type: Boolean, default: false },
    currentType: { type: String, default: "community" }
  }

  connect() {
    this.boundHandleKeydown = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this.boundHandleKeydown)

    // 전역 이벤트 리스너 등록 (FAB 버튼에서 호출)
    this.boundOpenFromEvent = this.openFromEvent.bind(this)
    window.addEventListener("canvas-modal:open", this.boundOpenFromEvent)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundHandleKeydown)
    window.removeEventListener("canvas-modal:open", this.boundOpenFromEvent)
  }

  // 전역 이벤트로 모달 열기 (FAB 버튼에서 dispatch)
  openFromEvent(event) {
    const type = event.detail?.type || "community"
    this.currentTypeValue = type
    this.openValue = true
    this.element.classList.remove("hidden")

    requestAnimationFrame(() => {
      this.backdropTarget.classList.remove("opacity-0")
      this.backdropTarget.classList.add("opacity-100")
      this.panelTarget.classList.remove("opacity-0", "scale-95")
      this.panelTarget.classList.add("opacity-100", "scale-100")
    })

    document.body.style.overflow = "hidden"

    setTimeout(() => {
      if (this.hasTitleInputTarget) {
        this.titleInputTarget.focus()
      }
    }, 300)

    this.updateTypeUI()
  }

  // ============================================================
  // Modal Open/Close
  // ============================================================

  open(event) {
    // FAB 버튼의 data-type 속성에서 타입 결정
    const type = event?.currentTarget?.dataset?.type || "community"
    this.currentTypeValue = type

    this.openValue = true
    this.element.classList.remove("hidden")

    // 입장 애니메이션 트리거
    requestAnimationFrame(() => {
      this.backdropTarget.classList.remove("opacity-0")
      this.backdropTarget.classList.add("opacity-100")
      this.panelTarget.classList.remove("opacity-0", "scale-95")
      this.panelTarget.classList.add("opacity-100", "scale-100")
    })

    // 바디 스크롤 잠금
    document.body.style.overflow = "hidden"

    // 애니메이션 후 제목 입력창에 포커스
    setTimeout(() => {
      if (this.hasTitleInputTarget) {
        this.titleInputTarget.focus()
      }
    }, 300)

    // 선택된 타입에 맞게 UI 업데이트
    this.updateTypeUI()
  }

  close() {
    // 미저장 변경사항 확인
    if (this.dirtyValue && !this.confirmClose()) {
      return
    }

    this.openValue = false

    // 퇴장 애니메이션
    this.backdropTarget.classList.remove("opacity-100")
    this.backdropTarget.classList.add("opacity-0")
    this.panelTarget.classList.remove("opacity-100", "scale-100")
    this.panelTarget.classList.add("opacity-0", "scale-95")

    // 애니메이션 완료 후 숨김
    setTimeout(() => {
      this.element.classList.add("hidden")
      this.resetForm()
    }, 300)

    // 바디 스크롤 복원
    document.body.style.overflow = ""
  }

  closeIfDirty(event) {
    // backdrop 직접 클릭시에만 닫기
    if (event.target === this.backdropTarget) {
      this.close()
    }
  }

  confirmClose() {
    return confirm("작성 중인 내용이 있습니다. 정말 닫으시겠습니까?")
  }

  handleKeydown(event) {
    if (event.key === "Escape" && this.openValue) {
      event.preventDefault()
      this.close()
    }
  }

  // ============================================================
  // Type Switching (Community vs Outsourcing)
  // ============================================================

  switchType(event) {
    const newType = event.currentTarget.dataset.type
    if (newType === this.currentTypeValue) return

    this.currentTypeValue = newType
    this.updateTypeUI()
  }

  updateTypeUI() {
    const isCommunity = this.currentTypeValue === "community"

    // Segmented Control 상태 업데이트
    this.typeButtonTargets.forEach(btn => {
      const isActive = btn.dataset.type === this.currentTypeValue
      btn.dataset.active = isActive.toString()
    })

    // 설정 패널 토글 (슬라이드 애니메이션)
    if (this.hasCommunitySettingsTarget && this.hasOutsourcingSettingsTarget) {
      if (isCommunity) {
        this.communitySettingsTarget.classList.remove("hidden")
        this.outsourcingSettingsTarget.classList.add("hidden")
      } else {
        this.communitySettingsTarget.classList.add("hidden")
        this.outsourcingSettingsTarget.classList.remove("hidden")
      }
    }

    // 히든 카테고리 필드 업데이트
    if (this.hasCategoryFieldTarget) {
      this.categoryFieldTarget.value = isCommunity ? "free" : "hiring"
    }

    // 라디오 버튼 기본값 설정 (같은 name을 공유하므로 전환 시 명시적 설정 필요)
    const defaultCategory = isCommunity ? "free" : "hiring"
    const targetRadio = document.querySelector(`input[name="post[category]"][value="${defaultCategory}"]`)
    if (targetRadio) {
      targetRadio.checked = true
    }

    // 폼 재검증
    this.validateForm()
  }

  updateCategory(event) {
    if (this.hasCategoryFieldTarget) {
      this.categoryFieldTarget.value = event.target.value
    }
    this.validateForm()
  }

  // ============================================================
  // Form Validation
  // ============================================================

  validateForm() {
    if (!this.hasTitleInputTarget || !this.hasContentInputTarget) return

    const title = this.titleInputTarget.value.trim()
    const content = this.contentInputTarget.value.trim()

    let isValid = title.length > 0 && content.length > 0
    let missingFields = []

    // 기본 필드 체크
    if (title.length === 0) missingFields.push("제목")
    if (content.length === 0) missingFields.push("본문")

    // 외주 글일 경우 서비스 타입 필수
    if (this.currentTypeValue === "outsourcing" && this.hasServiceTypeTarget) {
      const serviceType = this.serviceTypeTarget.value
      if (serviceType === "") {
        missingFields.push("서비스 분야")
        isValid = false
      }
    }

    // 제출 버튼 상태 업데이트
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = !isValid
      this.submitButtonTarget.dataset.valid = isValid.toString()
    }

    // Validation 힌트 업데이트
    if (this.hasValidationHintTarget) {
      if (!isValid && missingFields.length > 0) {
        this.validationHintTarget.textContent = `${missingFields.join(", ")}을(를) 입력해주세요`
        this.validationHintTarget.classList.remove("hidden")
      } else {
        this.validationHintTarget.classList.add("hidden")
      }
    }

    // dirty 상태 추적
    if (title.length > 0 || content.length > 0) {
      this.dirtyValue = true
    }
  }

  // ============================================================
  // Form Submission
  // ============================================================

  async handleSubmit(event) {
    event.preventDefault()

    if (!this.hasSubmitButtonTarget || this.submitButtonTarget.disabled) return

    // 로딩 상태 표시
    const originalText = this.submitButtonTarget.textContent
    this.submitButtonTarget.textContent = "등록 중..."
    this.submitButtonTarget.disabled = true

    // 에러 힌트 숨김
    this.hideValidationHint()

    try {
      // FormData 수집 - form 속성으로 연결된 외부 요소도 명시적으로 수집
      const formData = this.collectFormData()

      // 디버깅: FormData 내용 확인
      console.log("📤 Submitting FormData:")
      for (const [key, value] of formData.entries()) {
        console.log(`  ${key}:`, value)
      }

      const response = await fetch("/posts", {
        method: "POST",
        body: formData,
        headers: {
          "Accept": "text/vnd.turbo-stream.html, text/html, application/xhtml+xml",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        }
      })

      if (response.redirected) {
        // 성공 - dirty 플래그 초기화 후 리다이렉트
        this.dirtyValue = false
        this.close()
        Turbo.visit(response.url)
      } else if (response.ok) {
        // 성공 but not redirected (Turbo Stream 응답 등)
        this.dirtyValue = false
        this.close()
        window.location.reload()
      } else {
        // 유효성 검사 에러 처리
        const html = await response.text()
        console.error("Form submission failed:", html)

        // 에러 메시지 추출 및 표시
        this.showServerError(html)

        this.submitButtonTarget.textContent = originalText
        this.submitButtonTarget.disabled = false
      }
    } catch (error) {
      console.error("Submit error:", error)
      this.showValidationHint("네트워크 오류가 발생했습니다. 다시 시도해주세요.")
      this.submitButtonTarget.textContent = originalText
      this.submitButtonTarget.disabled = false
    }
  }

  // FormData 수집 - form 속성으로 연결된 외부 요소도 포함
  collectFormData() {
    const formData = new FormData()
    const formId = "canvas-form"

    // form 속성으로 canvas-form에 연결된 모든 요소 선택
    const allElements = document.querySelectorAll(`[form="${formId}"], #${formId} input, #${formId} textarea, #${formId} select`)

    allElements.forEach(element => {
      const name = element.name
      if (!name) return

      // 체크박스/라디오: 선택된 것만
      if (element.type === "checkbox" || element.type === "radio") {
        if (element.checked) {
          formData.append(name, element.value)
        }
      }
      // 파일 입력
      else if (element.type === "file") {
        for (const file of element.files) {
          formData.append(name, file)
        }
      }
      // 일반 입력 (hidden, text, select 등)
      else {
        formData.append(name, element.value)
      }
    })

    return formData
  }

  // 서버 에러 메시지 파싱 및 표시
  showServerError(html) {
    // Rails 에러 메시지 패턴 찾기
    const errorPatterns = [
      /<li>([^<]+)<\/li>/g,                    // <li>에러메시지</li>
      /class="[^"]*error[^"]*"[^>]*>([^<]+)/g, // error 클래스 내 텍스트
      /data-error[^>]*>([^<]+)/g               // data-error 속성
    ]

    let errorMessages = []

    // HTML에서 에러 메시지 추출
    for (const pattern of errorPatterns) {
      const matches = html.matchAll(pattern)
      for (const match of matches) {
        if (match[1] && match[1].trim()) {
          errorMessages.push(match[1].trim())
        }
      }
    }

    if (errorMessages.length > 0) {
      this.showValidationHint(errorMessages.join(", "))
    } else {
      // 기본 에러 메시지
      this.showValidationHint("필수 항목을 확인해주세요.")
    }
  }

  // Validation 힌트 표시
  showValidationHint(message) {
    if (this.hasValidationHintTarget) {
      this.validationHintTarget.textContent = message
      this.validationHintTarget.classList.remove("hidden")
    }
  }

  // Validation 힌트 숨김
  hideValidationHint() {
    if (this.hasValidationHintTarget) {
      this.validationHintTarget.classList.add("hidden")
    }
  }

  // ============================================================
  // Utilities
  // ============================================================

  autoResize(event) {
    const textarea = event.target
    textarea.style.height = "auto"
    textarea.style.height = textarea.scrollHeight + "px"
  }

  resetForm() {
    if (this.hasFormTarget) {
      this.formTarget.reset()
    }
    this.dirtyValue = false
    this.currentTypeValue = "community"
    this.updateTypeUI()

    // textarea 높이 리셋
    if (this.hasContentInputTarget) {
      this.contentInputTarget.style.height = "auto"
    }
  }
}
