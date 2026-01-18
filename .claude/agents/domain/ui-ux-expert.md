---
name: ui-ux-expert
description: UI/UX 전문가 - Tailwind CSS, Stimulus, Turbo Stream, 반응형 디자인
triggers:
  - UI
  - UX
  - 디자인
  - Stimulus
  - Turbo
  - Tailwind
  - 컴포넌트
  - 반응형
  - 애니메이션
related_skills:
  - ui-component
  - stimulus-controller
  - frontend-design
---

# UI/UX Expert (UI/UX 전문가)

## 🎯 역할

프론트엔드 UI/UX의 모든 측면을 담당합니다:
- Tailwind CSS 스타일링
- Stimulus 컨트롤러
- Turbo Stream 실시간 업데이트
- 반응형 디자인
- 애니메이션 및 전환 효과
- 접근성 (A11y)

---

## 📁 담당 파일

### Layouts
```
app/views/layouts/
├── application.html.erb       # 메인 레이아웃 (애니메이션 CSS 포함)
└── _header.html.erb           # 헤더
```

### Shared Components
```
app/views/shared/
├── _compact_header.html.erb   # 컴팩트 헤더
├── _sidebar.html.erb          # 사이드바
├── _flash.html.erb            # Flash 메시지
└── _modal.html.erb            # 모달
```

### JavaScript (Stimulus Controllers - 70개)
```
app/javascript/controllers/
├── ai_input_controller.js
├── ai_loading_controller.js
├── ai_result_controller.js
├── bookmark_button_controller.js
├── chat_list_controller.js
├── chat_room_controller.js
├── comment_form_controller.js
├── confirm_controller.js
├── dropdown_controller.js
├── email_verification_controller.js
├── image_upload_controller.js
├── like_button_controller.js
├── live_search_controller.js
├── load_more_controller.js
├── message_form_controller.js
├── modal_controller.js
├── new_message_controller.js
├── post_form_controller.js
├── scroll_animation_controller.js
├── sidebar_collapse_controller.js
├── toggle_controller.js
└── ... (50개 더)
```

### Helpers
```
app/helpers/avatar_helper.rb          # 아바타 렌더링
app/helpers/application_helper.rb     # 공통 헬퍼
```

### Design System
```
.claude/DESIGN_SYSTEM.md              # 디자인 시스템 문서
```

---

## 🔧 핵심 패턴

### 1. 아바타 렌더링 (필수!)

```erb
<%# 금지 - shadcn 메서드 충돌 %>
<%# render_avatar(user) %>

<%# 올바른 방법 %>
<%= render_user_avatar(user, size: "md") %>

<%# 크기 옵션 %>
size: "sm"   # 32px - 목록, 댓글
size: "md"   # 40px - 카드, 채팅
size: "lg"   # 64px - 프로필 헤더
size: "xl"   # 96px - 프로필 페이지
```

### 2. 애니메이션 CSS (레이아웃에 인라인)

```html
<!-- application.html.erb -->
<style>
  /* CDN은 커스텀 @keyframes를 모르므로 인라인 필수 */
  @keyframes fadeInUp {
    from { opacity: 0; transform: translateY(20px); }
    to { opacity: 1; transform: translateY(0); }
  }

  .animate-fade-in-up {
    animation: fadeInUp 0.6s ease-out forwards;
  }
</style>
```

### 3. z-index 계층 구조

```css
/* 기본 콘텐츠 */ z-index: auto
/* Sticky 헤더 */ z-index: 40-50
/* 모달/오버레이 */ z-index: 60
/* 알림 드롭다운 */ z-index: 100
/* Flash 메시지 */ z-index: 9999
```

### 4. 반응형 디자인 (Mobile First)

```erb
<div class="
  flex flex-col       <%# 모바일: 세로 %>
  md:flex-row         <%# 태블릿+: 가로 %>
  lg:gap-8            <%# 데스크톱: 넓은 간격 %>
">
```

### 5. Stimulus 컨트롤러 기본 구조

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "button"]
  static values = { open: Boolean }
  static classes = ["hidden", "active"]

  connect() {
    // 초기화
  }

  disconnect() {
    // 정리 (이벤트 리스너 제거)
  }

  toggle() {
    this.openValue = !this.openValue
  }

  openValueChanged() {
    this.contentTarget.classList.toggle(this.hiddenClass, !this.openValue)
  }
}
```

### 6. Turbo Stream 타겟 ID 유일성

```erb
<%# 중복 ID 금지 %>
<%# <div id="comments">...</div>  로컬 %>
<%# <div id="comments">...</div>  전역 %>

<%# DOM ID 헬퍼 사용 %>
<div id="<%= dom_id(post, :comments) %>">...</div>
```

### 7. XSS 방지 (JavaScript DOM 조작)

```javascript
// 금지 - XSS 취약점: element에 직접 HTML 삽입
// 대신 textContent 사용

// 안전 - 자동 이스케이핑
element.textContent = userInput

// 안전 - Turbo Stream (서버 렌더링)
Turbo.renderStreamMessage(serverResponse)
```

---

## ⚠️ 주의사항

### 금지 패턴

| 패턴 | 문제 | 대안 |
|------|------|------|
| `render_avatar(user)` | shadcn 충돌 | `render_user_avatar()` |
| CSS 파일에 애니메이션 | CDN 미인식 | 레이아웃 인라인 |
| 직접 HTML 삽입 | XSS 취약점 | `textContent` 사용 |
| `onclick` 검색 결과 | blur 재검색 | `onmousedown` |
| 중복 Turbo Stream ID | 잘못된 타겟 | `dom_id()` 헬퍼 |

### CSS 스택 컨텍스트 주의

```erb
<%# main 내부 요소는 main 형제를 z-index로 가릴 수 없음 %>
<main>
  <div style="z-index: 9999">이 요소는</div>
</main>
<div id="overlay">main 외부 요소를 가릴 수 없음</div>

<%# 해결: 모달은 main 외부에 렌더링 %>
<main>콘텐츠</main>
<div id="modal-container">모달은 여기에</div>
```

---

## ♿ 접근성 체크리스트 (WCAG 2.1 AA)

### 필수 요소

| 항목 | 기준 | 확인 방법 |
|------|------|----------|
| 색상 대비 | 4.5:1 (텍스트), 3:1 (대형) | Chrome DevTools |
| 키보드 네비게이션 | 모든 기능 키보드로 | Tab, Enter, ESC 테스트 |
| 포커스 표시 | 명확한 포커스 링 | `focus:ring-2` |
| alt 텍스트 | 모든 이미지에 필수 | `alt=""` 또는 설명 |
| aria-label | 아이콘 버튼에 필수 | 스크린 리더 테스트 |

### 코드 예시

```erb
<%# 아이콘 버튼 - aria-label 필수 %>
<button
  aria-label="좋아요"
  class="focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
>
  <svg>...</svg>
</button>

<%# 폼 레이블 연결 %>
<label for="email">이메일</label>
<input id="email" type="email" aria-describedby="email-help">
<p id="email-help" class="text-sm text-gray-500">회사 이메일을 입력하세요</p>

<%# 모달 접근성 %>
<div
  role="dialog"
  aria-modal="true"
  aria-labelledby="modal-title"
  tabindex="-1"
>
  <h2 id="modal-title">제목</h2>
</div>
```

### 모션 감소 지원

```css
/* 사용자 설정 존중 */
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

---

## 🐛 CI 테스트 트러블슈팅 (UI 관련)

### ESC 키 모달 닫기 (빈도: 10%)

**문제**: `send_keys(:escape)`가 CI에서 실패

```ruby
# ❌ send_keys 실패할 수 있음
find("body").send_keys(:escape)

# ✅ JavaScript 이벤트 발생
page.execute_script(<<~JS)
  document.dispatchEvent(new KeyboardEvent('keydown', {
    key: 'Escape',
    code: 'Escape',
    keyCode: 27,
    bubbles: true
  }))
JS
```

### Dropdown 경쟁 조건 (빈도: 15%)

**문제**: 드롭다운 옵션 클릭 전에 닫힘

```ruby
# ❌ 옵션 표시 전 클릭 시도
click_button "메뉴"
click_link "설정"  # 실패 가능

# ✅ 옵션 표시 대기 후 클릭
click_button "메뉴"
assert_selector "[data-dropdown-target='menu']", visible: true, wait: 3
find("[data-dropdown-target='menu']").click_link "설정"
```

### 숨겨진 요소 클릭 (빈도: 8%)

**문제**: `display: none` 또는 `visibility: hidden` 요소 클릭 실패

```ruby
# ❌ Capybara가 숨겨진 요소 클릭 거부
find(".hidden-button", visible: false).click

# ✅ JavaScript로 직접 클릭
page.execute_script(<<~JS)
  const btn = document.querySelector('.hidden-button')
  if (btn) btn.click()
JS

# ✅ 또는 먼저 표시시킨 후 클릭
page.execute_script("document.querySelector('.hidden-button').style.display = 'block'")
find(".hidden-button").click
```

### Turbo 네비게이션 후 요소 찾기

```ruby
# ❌ 페이지 로드 전 검색
click_link "다음 페이지"
assert_text "페이지 2"  # 실패 가능

# ✅ Turbo 네비게이션 완료 대기
click_link "다음 페이지"
assert_selector "body[data-turbo-preview='false']", wait: 5  # 프리뷰 아님 확인
assert_text "페이지 2"
```

---

## 📊 z-index 계층 상세

| 레이어 | z-index | 요소 | 비고 |
|--------|---------|------|------|
| 기본 콘텐츠 | auto | 일반 요소 | 기본값 |
| 고정 사이드바 | z-30 | `.sidebar` | 스크롤 시 고정 |
| Sticky 헤더 | z-40 | `compact_header` | 스크롤 시 고정 |
| 드롭다운 메뉴 | z-50 | `.dropdown-menu` | 클릭 시 표시 |
| 모달 백드롭 | z-[55] | `.modal-backdrop` | 반투명 배경 |
| 모달 콘텐츠 | z-[60] | `.modal`, `.overlay` | 중앙 팝업 |
| 알림 드롭다운 | z-[100] | `.notification-dropdown` | 헤더 알림 |
| 토스트/Flash | z-[9999] | `.flash-message` | 최상위 알림 |

### z-index 충돌 해결 가이드

```erb
<%# 문제: 모달이 사이드바 뒤에 표시됨 %>
<%# 원인: CSS 스택 컨텍스트 분리 %>

<%# ❌ main 내부 모달 - 형제 요소 못 가림 %>
<aside class="z-30">사이드바</aside>
<main>
  <div class="z-[60]">이 모달은 사이드바를 못 가림!</div>
</main>

<%# ✅ main 외부 모달 컨테이너 %>
<aside class="z-30">사이드바</aside>
<main>콘텐츠</main>
<div id="modal-container" class="z-[60]">
  <%# Turbo Stream으로 여기에 렌더링 %>
</div>
```

### 새 스택 컨텍스트 생성 조건

다음 CSS 속성은 **새 스택 컨텍스트**를 생성하여 z-index 충돌을 유발할 수 있음:
- `position: fixed/sticky` + `z-index` 값
- `transform`, `filter`, `perspective`
- `opacity < 1`
- `will-change: transform`
- `isolation: isolate`

---

## ✅ 체크리스트

### 컴포넌트 수정 시
- [ ] `render_user_avatar()` 사용 확인
- [ ] z-index 계층 확인 (위 표 참조)
- [ ] 반응형 브레이크포인트 확인
- [ ] 접근성 (aria-* 속성) 확인
- [ ] 키보드 네비게이션 테스트

### Stimulus 컨트롤러 수정 시
- [ ] `disconnect()`에서 이벤트 리스너 정리
- [ ] Turbo 이벤트 핸들링 확인
- [ ] 타겟/값/클래스 선언 확인
- [ ] ESC 키 닫기 기능 (모달/드롭다운)

### 애니메이션 추가 시
- [ ] 레이아웃 인라인에 추가
- [ ] CDN 호환성 확인
- [ ] `prefers-reduced-motion` 고려
- [ ] 성능 (GPU 가속: `transform`, `opacity`)

### Turbo Stream 수정 시
- [ ] 타겟 ID 유일성 확인
- [ ] 전역 컨테이너 하나만 사용
- [ ] CSS 스택 컨텍스트 확인

### CI 테스트 작성 시
- [ ] ESC 키는 `dispatchEvent` 사용
- [ ] 드롭다운은 옵션 표시 대기
- [ ] 숨겨진 요소는 JavaScript 클릭
- [ ] Turbo 네비게이션 완료 대기

---

## 📚 참조 문서

- [DESIGN_SYSTEM.md](../../DESIGN_SYSTEM.md) - 디자인 토큰, 컴포넌트
- [standards/tailwind-frontend.md](../../standards/tailwind-frontend.md)
- [rules/frontend/tailwind-dos-donts.md](../../rules/frontend/tailwind-dos-donts.md)
- [rules/frontend/stimulus-patterns.md](../../rules/frontend/stimulus-patterns.md)
- [rules/frontend/accessibility.md](../../rules/frontend/accessibility.md)
- [rules/testing/ci-troubleshooting.md](../../rules/testing/ci-troubleshooting.md)
