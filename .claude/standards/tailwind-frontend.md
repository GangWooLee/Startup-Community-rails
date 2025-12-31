# Tailwind + Stimulus Frontend Standards

> Agent OS 스타일 표준 규칙 - Tailwind CSS와 Stimulus 개발 시 준수해야 할 규칙들

## 1. Tailwind CSS 설계 원칙

### 디자인 토큰 (Design Tokens)

#### 색상 시스템
```css
/* 프로젝트 색상 팔레트 */
/* Primary: Blue 계열 */
bg-blue-500     /* 주요 액션 버튼 */
bg-blue-600     /* hover 상태 */
text-blue-600   /* 링크, 강조 텍스트 */

/* Secondary: Gray 계열 */
bg-gray-50      /* 배경 */
bg-gray-100     /* 카드 배경 */
bg-gray-200     /* 구분선, 비활성 */
text-gray-500   /* 보조 텍스트 */
text-gray-700   /* 본문 텍스트 */
text-gray-900   /* 제목 */

/* Status Colors */
bg-green-500    /* 성공, 활성 */
bg-red-500      /* 에러, 삭제 */
bg-yellow-500   /* 경고 */
bg-purple-500   /* 특별, 프리미엄 */
bg-pink-500     /* 커스텀 상태 */
```

#### 간격 시스템 (Spacing)
```css
/* 일관된 간격 사용 */
p-2   (8px)   /* 아이콘 패딩 */
p-3   (12px)  /* 작은 버튼 패딩 */
p-4   (16px)  /* 기본 패딩 */
p-6   (24px)  /* 카드 패딩 */
p-8   (32px)  /* 섹션 패딩 */

gap-2 (8px)   /* 아이콘-텍스트 간격 */
gap-4 (16px)  /* 요소 간격 */
gap-6 (24px)  /* 카드 간격 */
gap-8 (32px)  /* 섹션 간격 */

mt-4  (16px)  /* 요소 상단 여백 */
mb-6  (24px)  /* 섹션 하단 여백 */
```

#### 타이포그래피
```css
/* 제목 */
text-2xl font-bold    /* 페이지 제목 (24px) */
text-xl font-semibold /* 섹션 제목 (20px) */
text-lg font-medium   /* 카드 제목 (18px) */

/* 본문 */
text-base            /* 기본 본문 (16px) */
text-sm              /* 보조 텍스트 (14px) */
text-xs              /* 메타 정보 (12px) */

/* 줄 높이 */
leading-tight        /* 제목용 (1.25) */
leading-normal       /* 본문용 (1.5) */
leading-relaxed      /* 긴 텍스트용 (1.625) */
```

### 반응형 디자인
```css
/* Mobile First 접근 */
<div class="
  flex flex-col          /* 모바일: 세로 배치 */
  md:flex-row            /* 태블릿+: 가로 배치 */
  lg:gap-8               /* 데스크톱: 넓은 간격 */
">

/* 브레이크포인트 */
sm:   /* 640px+ */
md:   /* 768px+ */
lg:   /* 1024px+ */
xl:   /* 1280px+ */
2xl:  /* 1536px+ */
```

## 2. 컴포넌트 패턴

### 버튼
```erb
<%# Primary Button %>
<button class="
  px-4 py-2
  bg-blue-500 hover:bg-blue-600
  text-white font-medium
  rounded-lg
  transition-colors duration-200
  disabled:opacity-50 disabled:cursor-not-allowed
">
  저장하기
</button>

<%# Secondary Button %>
<button class="
  px-4 py-2
  bg-gray-100 hover:bg-gray-200
  text-gray-700 font-medium
  rounded-lg
  transition-colors duration-200
">
  취소
</button>

<%# Danger Button %>
<button class="
  px-4 py-2
  bg-red-500 hover:bg-red-600
  text-white font-medium
  rounded-lg
  transition-colors duration-200
">
  삭제하기
</button>
```

### 카드
```erb
<div class="
  bg-white
  rounded-xl
  shadow-sm hover:shadow-md
  border border-gray-100
  p-6
  transition-shadow duration-200
">
  <h3 class="text-lg font-semibold text-gray-900 mb-2">
    카드 제목
  </h3>
  <p class="text-gray-600 text-sm">
    카드 내용
  </p>
</div>
```

### 입력 필드
```erb
<div class="space-y-1">
  <label class="block text-sm font-medium text-gray-700">
    이메일
  </label>
  <input
    type="email"
    class="
      w-full px-4 py-2
      border border-gray-300 rounded-lg
      focus:ring-2 focus:ring-blue-500 focus:border-blue-500
      placeholder-gray-400
      transition-colors duration-200
    "
    placeholder="example@email.com"
  >
  <p class="text-xs text-red-500 mt-1">
    <%= @user.errors[:email].first if @user.errors[:email].any? %>
  </p>
</div>
```

### 뱃지
```erb
<%# Status Badge %>
<span class="
  inline-flex items-center
  px-2.5 py-0.5
  rounded-full
  text-xs font-medium
  bg-green-100 text-green-800
">
  활성
</span>

<%# Category Badge %>
<span class="
  inline-flex items-center
  px-2 py-1
  rounded-md
  text-xs font-medium
  bg-gray-100 text-gray-600
">
  자유
</span>
```

### 아바타
```erb
<%# 프로젝트 전용 헬퍼 사용 %>
<%= render_user_avatar(user, size: "md") %>

<%# 크기 옵션 %>
size: "sm"   /* 32px - 목록, 댓글 */
size: "md"   /* 40px - 카드, 채팅 */
size: "lg"   /* 64px - 프로필 헤더 */
size: "xl"   /* 96px - 프로필 페이지 */

<%# ⚠️ 금지: render_avatar 사용 금지 (shadcn 충돌) %>
```

## 3. Stimulus 컨트롤러 패턴

### 기본 구조
```javascript
// app/javascript/controllers/toggle_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "icon"]
  static values = {
    open: { type: Boolean, default: false }
  }
  static classes = ["hidden", "rotated"]

  connect() {
    // 초기화 로직
    this.render()
  }

  toggle() {
    this.openValue = !this.openValue
  }

  // Value 변경 시 자동 호출
  openValueChanged() {
    this.render()
  }

  render() {
    this.contentTarget.classList.toggle(this.hiddenClass, !this.openValue)
    this.iconTarget.classList.toggle(this.rotatedClass, this.openValue)
  }
}
```

### Turbo와 통합
```javascript
// app/javascript/controllers/form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["submit"]

  connect() {
    // Turbo 폼 제출 이벤트 리스닝
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
}
```

### 실시간 검색 패턴
```javascript
// app/javascript/controllers/live_search_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results"]
  static values = {
    url: String,
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

  async performSearch() {
    const query = this.inputTarget.value.trim()
    if (query.length < 2) {
      this.clearResults()
      return
    }

    const response = await fetch(`${this.urlValue}?q=${encodeURIComponent(query)}`)
    const html = await response.text()

    // ✅ 안전한 DOM 업데이트 (Turbo Stream 권장)
    // Turbo를 통한 서버 사이드 렌더링된 HTML 삽입
    Turbo.renderStreamMessage(html)
  }

  clearResults() {
    // 자식 요소들을 안전하게 제거
    while (this.resultsTarget.firstChild) {
      this.resultsTarget.removeChild(this.resultsTarget.firstChild)
    }
  }

  // ⚠️ 검색 결과 클릭 문제 해결
  // onclick 대신 onmousedown 사용 (blur 시 재검색 방지)
  selectResult(event) {
    event.preventDefault()
    window.location.href = event.currentTarget.dataset.url
  }
}
```

### 이미지 업로드 패턴
```javascript
// app/javascript/controllers/image_upload_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview", "placeholder"]
  static values = {
    maxSize: { type: Number, default: 2097152 } // 2MB
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

    // 미리보기 표시
    const reader = new FileReader()
    reader.onload = (e) => {
      this.previewTarget.src = e.target.result
      this.previewTarget.classList.remove("hidden")
      this.placeholderTarget.classList.add("hidden")
    }
    reader.readAsDataURL(file)
  }

  remove() {
    this.inputTarget.value = ""
    this.previewTarget.classList.add("hidden")
    this.placeholderTarget.classList.remove("hidden")
  }
}
```

## 4. Turbo 패턴

### Turbo Frames
```erb
<%# 부분 업데이트 영역 정의 %>
<turbo-frame id="post_<%= @post.id %>">
  <%= render @post %>
</turbo-frame>

<%# 컨트롤러에서 특정 프레임만 업데이트 %>
<%# app/views/posts/update.turbo_stream.erb %>
<%= turbo_stream.replace "post_#{@post.id}" do %>
  <%= render @post %>
<% end %>
```

### Turbo Streams
```erb
<%# app/views/comments/create.turbo_stream.erb %>

<%# 목록에 추가 %>
<%= turbo_stream.prepend "comments" do %>
  <%= render @comment %>
<% end %>

<%# 카운트 업데이트 %>
<%= turbo_stream.update "comments_count" do %>
  <%= @post.comments.count %>
<% end %>

<%# 폼 초기화 %>
<%= turbo_stream.replace "new_comment_form" do %>
  <%= render "comments/form", post: @post, comment: Comment.new %>
<% end %>
```

### 실시간 업데이트 (Solid Cable)
```ruby
# app/models/message.rb
class Message < ApplicationRecord
  after_create_commit -> {
    broadcast_append_to(
      chat_room,
      target: "messages",
      partial: "messages/message"
    )
  }
end
```

## 5. 레이아웃 패턴

### 페이지 레이아웃
```erb
<%# 기본 페이지 구조 %>
<div class="min-h-screen bg-gray-50">
  <%# 헤더 %>
  <%= render "shared/header" %>

  <%# 메인 콘텐츠 %>
  <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
    <%= yield %>
  </main>

  <%# 푸터 %>
  <%= render "shared/footer" %>
</div>
```

### 2단 레이아웃
```erb
<div class="flex flex-col lg:flex-row gap-8">
  <%# 메인 콘텐츠 %>
  <div class="flex-1 min-w-0">
    <%= yield %>
  </div>

  <%# 사이드바 %>
  <aside class="w-full lg:w-80 shrink-0">
    <%= render "shared/sidebar" %>
  </aside>
</div>
```

### 모달
```erb
<div
  data-controller="modal"
  data-modal-open-value="false"
  class="relative z-50"
  aria-modal="true"
>
  <%# 백드롭 %>
  <div
    data-modal-target="backdrop"
    class="fixed inset-0 bg-black/50 transition-opacity hidden"
    data-action="click->modal#close"
  ></div>

  <%# 모달 패널 %>
  <div
    data-modal-target="panel"
    class="fixed inset-0 flex items-center justify-center p-4 hidden"
  >
    <div class="bg-white rounded-xl shadow-xl max-w-md w-full p-6">
      <h2 class="text-xl font-bold mb-4">모달 제목</h2>
      <p class="text-gray-600 mb-6">모달 내용</p>
      <div class="flex justify-end gap-3">
        <button
          data-action="click->modal#close"
          class="px-4 py-2 text-gray-700 hover:bg-gray-100 rounded-lg"
        >
          취소
        </button>
        <button class="px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600">
          확인
        </button>
      </div>
    </div>
  </div>
</div>
```

## 6. 접근성 (A11y)

### 필수 속성
```erb
<%# 버튼 %>
<button type="button" aria-label="메뉴 열기">
  <svg>...</svg>
</button>

<%# 폼 요소 %>
<label for="email">이메일</label>
<input id="email" type="email" aria-describedby="email-hint">
<p id="email-hint" class="text-sm text-gray-500">업무용 이메일을 입력하세요</p>

<%# 모달 %>
<div role="dialog" aria-modal="true" aria-labelledby="modal-title">
  <h2 id="modal-title">제목</h2>
</div>

<%# 알림 %>
<div role="alert" aria-live="polite">
  저장되었습니다.
</div>
```

### 키보드 네비게이션
```javascript
// Escape 키로 닫기
document.addEventListener("keydown", (e) => {
  if (e.key === "Escape") {
    this.close()
  }
})

// Tab 트랩 (모달 내부에서만 포커스)
handleTab(e) {
  const focusable = this.element.querySelectorAll(
    'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
  )
  // ...
}
```

## 7. 프로젝트 특화 규칙

### 금지 패턴
```erb
<%# ❌ render_avatar 사용 금지 (shadcn 메서드 충돌) %>
<%= render_avatar(user) %>

<%# ✅ 올바른 방법 %>
<%= render_user_avatar(user, size: "md") %>
```

### OG 메타태그
```erb
<%# ❌ 직접 URL 사용 금지 (한글 인코딩 오류) %>
<meta property="og:url" content="<%= request.original_url %>">

<%# ✅ 헬퍼 사용 %>
<%= og_meta_tags(title: "제목", description: "설명") %>
```

### 검색 결과 클릭
```erb
<%# ❌ onclick 사용 금지 (blur 시 재검색) %>
<div onclick="window.location.href='...'">

<%# ✅ onmousedown 사용 %>
<div onmousedown="event.preventDefault(); window.location.href='...'">
```

## 8. 보안: XSS 방지

### DOM 조작 규칙
```javascript
// ❌ 금지: innerHTML에 사용자 입력 직접 삽입
element.innerHTML = userInput  // XSS 취약점!

// ✅ 권장: textContent 사용 (텍스트만)
element.textContent = userInput

// ✅ 권장: Turbo Stream 사용 (서버 렌더링)
Turbo.renderStreamMessage(serverResponse)

// ✅ 권장: DOM API 사용
const div = document.createElement('div')
div.textContent = userInput
parent.appendChild(div)

// ✅ 필요시: DOMPurify 라이브러리 사용
import DOMPurify from 'dompurify'
element.innerHTML = DOMPurify.sanitize(htmlContent)
```

### Rails 뷰에서 XSS 방지
```erb
<%# ✅ 자동 이스케이핑 (기본) %>
<%= user_input %>

<%# ⚠️ raw/html_safe 사용 시 주의 %>
<%# 반드시 sanitize와 함께 사용 %>
<%= sanitize(user_content, tags: %w[p br strong em]) %>

<%# ❌ 금지: 검증 없이 raw 사용 %>
<%= raw user_input %>
```

## 9. 성능 최적화

### 이미지 최적화
```erb
<%# lazy loading %>
<img src="..." loading="lazy" alt="...">

<%# srcset 사용 %>
<img
  srcset="small.jpg 300w, medium.jpg 600w, large.jpg 1200w"
  sizes="(max-width: 640px) 100vw, 50vw"
  src="medium.jpg"
  alt="..."
>
```

### CSS 최적화
```css
/* 불필요한 애니메이션 비활성화 */
@media (prefers-reduced-motion: reduce) {
  * {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

### JavaScript 최적화
```javascript
// Debounce 패턴
let timeout
function debounce(fn, delay) {
  return (...args) => {
    clearTimeout(timeout)
    timeout = setTimeout(() => fn(...args), delay)
  }
}

// Intersection Observer (무한 스크롤)
const observer = new IntersectionObserver((entries) => {
  if (entries[0].isIntersecting) {
    loadMore()
  }
})
observer.observe(document.querySelector("#load-more-trigger"))
```
