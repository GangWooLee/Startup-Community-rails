---
paths: app/views/**/*.erb, app/javascript/**/*.js
---

# Tailwind + Stimulus 패턴

## 아바타 렌더링 (필수!)
- ❌ `render_avatar(user)` → shadcn 충돌
- ✅ `render_user_avatar(user, size: "md")`

## 검색 결과 클릭
- ❌ `onclick="window.location.href='...'"` → blur 시 재검색
- ✅ `onmousedown="event.preventDefault(); window.location.href='...'"`

## OG 메타태그
- ❌ `request.original_url` 직접 사용 → 한글 인코딩 오류
- ✅ `og_meta_tags(title: "제목", description: "설명")`

## CSS 애니메이션
- ❌ app/assets/tailwind/application.css에서 커스텀 애니메이션 정의
- ✅ application.html.erb 레이아웃의 인라인 <style> 태그 사용
- 이유: Tailwind CDN이 커스텀 @keyframes를 모름
