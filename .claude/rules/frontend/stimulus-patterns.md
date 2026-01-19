---
paths: app/javascript/controllers/**/*.js
---

# Stimulus 컨트롤러 패턴

## 기본 구조

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // 1. Targets (DOM 요소 참조)
  static targets = ["content", "icon"]

  // 2. Values (상태 관리)
  static values = {
    open: { type: Boolean, default: false },
    url: String,
    debounce: { type: Number, default: 300 }
  }

  // 3. Classes (CSS 클래스)
  static classes = ["hidden", "active"]

  // 4. Lifecycle
  connect() {
    // 초기화 로직
  }

  disconnect() {
    // 정리 로직 (이벤트 리스너 제거 등)
  }

  // 5. Value 변경 콜백
  openValueChanged() {
    this.render()
  }

  // 6. Actions
  toggle() {
    this.openValue = !this.openValue
  }

  // 7. Private Methods
  render() {
    this.contentTarget.classList.toggle(this.hiddenClass, !this.openValue)
  }
}
```

## Turbo 통합

```javascript
// Turbo 이벤트 리스닝
connect() {
  this.element.addEventListener("turbo:submit-start", this.disable.bind(this))
  this.element.addEventListener("turbo:submit-end", this.enable.bind(this))
}

disconnect() {
  this.element.removeEventListener("turbo:submit-start", this.disable.bind(this))
  this.element.removeEventListener("turbo:submit-end", this.enable.bind(this))
}

disable() {
  this.submitTarget.disabled = true
  this.submitTarget.textContent = "처리 중..."
}

enable() {
  this.submitTarget.disabled = false
  this.submitTarget.textContent = "저장"
}
```

## Debounce 패턴 (검색 등)

```javascript
static values = {
  debounce: { type: Number, default: 300 }
}

connect() {
  this.timeout = null
}

search() {
  clearTimeout(this.timeout)
  this.timeout = setTimeout(() => {
    this.performSearch()
  }, this.debounceValue)
}
```

## 파일 업로드 패턴

```javascript
static values = {
  maxSize: { type: Number, default: 2097152 }  // 2MB
}

preview() {
  const file = this.inputTarget.files[0]
  if (!file) return

  // 파일 크기 검증
  if (file.size > this.maxSizeValue) {
    alert("파일 크기는 2MB 이하만 허용됩니다.")
    this.inputTarget.value = ""
    return
  }

  // 미리보기
  const reader = new FileReader()
  reader.onload = (e) => {
    this.previewTarget.src = e.target.result
  }
  reader.readAsDataURL(file)
}
```

## 보안 규칙

### DOM 조작 시 안전한 방법만 사용
```javascript
// ✅ textContent로 텍스트 삽입 (자동 이스케이핑)
element.textContent = userInput

// ✅ DOM API로 요소 생성
const div = document.createElement('div')
div.textContent = userInput
parent.appendChild(div)

// ✅ Turbo Stream (서버 렌더링된 HTML)
Turbo.renderStreamMessage(serverResponse)
```

### 전역 변수 사용 금지
```javascript
// ❌ 전역 오염
window.myData = data

// ✅ Stimulus values 사용
static values = { data: Object }
```

### CSRF 토큰 안전하게 접근하기
```javascript
// ✅ 방법 1: Stimulus value 사용 (권장)
static values = { csrfToken: String }

async submit() {
  const response = await fetch(url, {
    headers: { "X-CSRF-Token": this.csrfTokenValue }
  })
}

// View에서 전달:
// data-controller-csrf-token-value="<%= form_authenticity_token %>"

// ✅ 방법 2: Optional chaining (csrfToken value 미정의 시)
const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content || ''

// ❌ 금지: null 체크 없이 직접 접근
document.querySelector('meta[name="csrf-token"]').content  // TypeError 위험!
```

## HTML 연결

```erb
<div data-controller="toggle"
     data-toggle-open-value="false"
     data-toggle-hidden-class="hidden">

  <button data-action="click->toggle#toggle">
    토글
  </button>

  <div data-toggle-target="content" class="hidden">
    콘텐츠
  </div>
</div>
```
