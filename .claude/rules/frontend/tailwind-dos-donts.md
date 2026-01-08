---
paths: app/views/**/*.erb, app/javascript/**/*.js
---

# Tailwind + Stimulus 패턴

## 프로젝트 특화 규칙 (필수!)

### 아바타 렌더링
```erb
<%# ❌ 절대 금지 - shadcn 메서드 충돌 %>
<%= render_avatar(user) %>

<%# ✅ 올바른 방법 %>
<%= render_user_avatar(user, size: "md") %>

<%# 크기 옵션 %>
size: "sm"   # 32px - 목록, 댓글
size: "md"   # 40px - 카드, 채팅
size: "lg"   # 64px - 프로필 헤더
size: "xl"   # 96px - 프로필 페이지
```

### 검색 결과 클릭
```erb
<%# ❌ 금지 - blur 시 재검색 문제 %>
<div onclick="window.location.href='...'">

<%# ✅ 올바른 방법 - mousedown 사용 %>
<div onmousedown="event.preventDefault(); window.location.href='...'">
```

### OG 메타태그
```erb
<%# ❌ 금지 - 한글 인코딩 오류 %>
<meta property="og:url" content="<%= request.original_url %>">

<%# ✅ 헬퍼 사용 %>
<%= og_meta_tags(title: "제목", description: "설명") %>
```

### CSS 애니메이션
```
❌ app/assets/tailwind/application.css에 커스텀 애니메이션 정의
✅ application.html.erb 레이아웃의 인라인 <style> 태그 사용

이유: Tailwind CDN이 커스텀 @keyframes를 인식하지 못함
```

## 컴포넌트 패턴

### 버튼
```erb
<%# Primary %>
<button class="px-4 py-2 bg-blue-500 hover:bg-blue-600 text-white font-medium rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed">

<%# Secondary %>
<button class="px-4 py-2 bg-gray-100 hover:bg-gray-200 text-gray-700 font-medium rounded-lg transition-colors">

<%# Danger %>
<button class="px-4 py-2 bg-red-500 hover:bg-red-600 text-white font-medium rounded-lg transition-colors">
```

### 카드
```erb
<div class="bg-white rounded-xl shadow-sm hover:shadow-md border border-gray-100 p-6 transition-shadow">
  <%# 콘텐츠 %>
</div>
```

### 입력 필드
```erb
<input class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 placeholder-gray-400 transition-colors">
```

## XSS 방지 (JavaScript)

| 금지 패턴 | 안전한 대안 |
|----------|-----------|
| `.innerHTML = 사용자입력` | `.textContent = 사용자입력` |
| 동적 HTML 삽입 | Turbo Stream 사용 (서버 렌더링) |
| DOM 문자열 파싱 | DOM API로 요소 생성 |

```javascript
// ✅ 안전한 방법
element.textContent = userInput
Turbo.renderStreamMessage(serverResponse)

const div = document.createElement('div')
div.textContent = userInput
parent.appendChild(div)
```

## 반응형 디자인

```erb
<%# Mobile First 접근 %>
<div class="
  flex flex-col      <%# 모바일: 세로 %>
  md:flex-row        <%# 태블릿+: 가로 %>
  lg:gap-8           <%# 데스크톱: 넓은 간격 %>
">

<%# 브레이크포인트 %>
sm:   <%# 640px+ %>
md:   <%# 768px+ %>
lg:   <%# 1024px+ %>
xl:   <%# 1280px+ %>
```

## 간격 시스템

```
p-2  (8px)   # 아이콘 패딩
p-4  (16px)  # 기본 패딩
p-6  (24px)  # 카드 패딩

gap-2 (8px)  # 아이콘-텍스트 간격
gap-4 (16px) # 요소 간격
gap-6 (24px) # 카드 간격
```
