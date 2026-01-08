---
paths: app/views/**/*.erb
---

# 접근성 (A11y) 규칙

## 필수 속성

### 아이콘 버튼
```erb
<%# ❌ 스크린 리더가 내용 인식 못함 %>
<button>
  <svg>...</svg>
</button>

<%# ✅ aria-label 필수 %>
<button type="button" aria-label="메뉴 열기">
  <svg aria-hidden="true">...</svg>
</button>
```

### 폼 요소
```erb
<%# ❌ label과 input 연결 안됨 %>
<label>이메일</label>
<input type="email">

<%# ✅ for/id로 연결 %>
<label for="email">이메일</label>
<input id="email" type="email" aria-describedby="email-hint">
<p id="email-hint" class="text-sm text-gray-500">업무용 이메일을 입력하세요</p>
```

### 모달
```erb
<div role="dialog"
     aria-modal="true"
     aria-labelledby="modal-title">
  <h2 id="modal-title">제목</h2>
  <%# 콘텐츠 %>
</div>
```

### 알림 메시지
```erb
<%# 동적 알림은 aria-live 필수 %>
<div role="alert" aria-live="polite">
  저장되었습니다.
</div>

<%# 긴급 알림 %>
<div role="alert" aria-live="assertive">
  오류가 발생했습니다!
</div>
```

## 이미지

```erb
<%# ❌ alt 누락 %>
<img src="profile.jpg">

<%# ✅ alt 필수 (내용 설명) %>
<img src="profile.jpg" alt="김철수 프로필 사진">

<%# 장식용 이미지는 빈 alt %>
<img src="decoration.svg" alt="">
```

## 키보드 네비게이션

### Tab 순서
```erb
<%# 자연스러운 Tab 순서 유지 %>
<%# tabindex="0" - 기본 순서에 포함 %>
<%# tabindex="-1" - 프로그래밍으로만 포커스 %>
<%# tabindex="1+" - 사용 금지! (순서 혼란) %>
```

### 모달 Tab Trap
```javascript
// 모달 내에서만 Tab 순환
handleTab(e) {
  const focusable = this.element.querySelectorAll(
    'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
  )
  const first = focusable[0]
  const last = focusable[focusable.length - 1]

  if (e.shiftKey && document.activeElement === first) {
    e.preventDefault()
    last.focus()
  } else if (!e.shiftKey && document.activeElement === last) {
    e.preventDefault()
    first.focus()
  }
}
```

### Escape 키 닫기
```javascript
document.addEventListener("keydown", (e) => {
  if (e.key === "Escape") {
    this.close()
  }
})
```

## 색상 대비

```
텍스트-배경 대비 비율:
- 일반 텍스트: 최소 4.5:1
- 큰 텍스트 (18px+): 최소 3:1

❌ text-gray-300 on bg-gray-100 (대비 부족)
✅ text-gray-700 on bg-gray-100 (충분한 대비)
```

## 포커스 표시

```erb
<%# ❌ 포커스 링 제거 금지 %>
<button class="focus:outline-none">

<%# ✅ 커스텀 포커스 스타일 %>
<button class="focus:ring-2 focus:ring-blue-500 focus:ring-offset-2">
```
