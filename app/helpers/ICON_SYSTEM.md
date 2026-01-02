# Icon System - Lucide Icons Style

**프로덕션급 아이콘 시스템** - Phase 7.2

## 디자인 철학

### Lucide Icons 스타일
- **stroke-width: 1.5** - 섬세하고 세련된 라인
- **currentColor** - 부모 요소 색상 자동 상속
- **일관된 viewBox** - 모든 아이콘 24x24 기준
- **Outline & Solid** - 두 가지 variant 지원

---

## 사용법

### 기본 사용

```erb
<%# 기본 아이콘 (outline, md) %>
<%= icon "check" %>

<%# 크기 지정 %>
<%= icon "heart", size: "lg" %>

<%# 색상 지정 (Tailwind 클래스) %>
<%= icon "trash", class: "text-red-500" %>

<%# Solid variant %>
<%= icon "heart", variant: :solid, class: "text-red-500" %>

<%# 접근성 레이블 %>
<%= icon "search", aria_label: "검색" %>
```

### 버튼과 함께 사용

```erb
<button class="flex items-center gap-2 px-4 py-2 bg-primary text-primary-foreground rounded-lg">
  <%= icon "plus", size: "sm" %>
  <span>새 글 작성</span>
</button>
```

### 상태 표시

```erb
<%# Success %>
<div class="flex items-center gap-2 text-green-500">
  <%= icon "check-circle", variant: :solid %>
  <span>저장되었습니다</span>
</div>

<%# Error %>
<div class="flex items-center gap-2 text-red-500">
  <%= icon "x-circle", variant: :solid %>
  <span>오류가 발생했습니다</span>
</div>

<%# Warning %>
<div class="flex items-center gap-2 text-yellow-600">
  <%= icon "exclamation-triangle", variant: :solid %>
  <span>주의가 필요합니다</span>
</div>
```

---

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `name` | String/Symbol | required | 아이콘 이름 (kebab-case) |
| `variant` | Symbol | `:outline` | `:outline` 또는 `:solid` |
| `size` | String | `"md"` | `"xs"`, `"sm"`, `"md"`, `"lg"`, `"xl"`, `"2xl"` |
| `class` | String | `""` | 추가 CSS 클래스 |
| `aria_label` | String | `nil` | 접근성 레이블 (선택) |

---

## Size Reference

| Size | Tailwind Class | Pixels | Use Case |
|------|----------------|--------|----------|
| `xs` | `w-3 h-3` | 12px | 인라인 텍스트, 작은 뱃지 |
| `sm` | `w-4 h-4` | 16px | 버튼 아이콘, 드롭다운 |
| `md` | `w-5 h-5` | 20px | 기본 크기 (대부분의 UI) |
| `lg` | `w-6 h-6` | 24px | 헤더, 큰 버튼 |
| `xl` | `w-8 h-8` | 32px | 히어로 섹션, 빈 상태 |
| `2xl` | `w-10 h-10` | 40px | 로고, 대형 UI 요소 |

---

## Available Icons (40+)

### Navigation (6개)
- `chevron-down`, `chevron-up`, `chevron-left`, `chevron-right`
- `arrow-left`, `arrow-right`

### Actions (8개)
- `x-mark`, `check`, `check-circle`, `x-circle`
- `plus`, `plus-circle`, `minus`
- `pencil`, `trash`

### Social & Engagement (4개)
- `heart` (outline, solid)
- `bookmark` (outline, solid)
- `share`, `message` (outline, solid)

### UI Elements (6개)
- `search`, `filter`, `cog` (outline, solid)
- `user` (outline, solid), `users`
- `menu`, `dots-vertical`, `dots-horizontal`

### Status & Alerts (3개)
- `information-circle` (outline, solid)
- `exclamation-triangle` (outline, solid)
- `bell` (outline, solid)

### File & Document (3개)
- `document`, `folder` (outline, solid), `photo`

### Media (2개)
- `play` (outline, solid), `pause` (outline, solid)

### Commerce (2개)
- `shopping-cart`, `credit-card`

### Communication (2개)
- `paper-airplane` (outline, solid), `at-symbol`

---

## currentColor 활용

아이콘은 **currentColor**를 사용하여 부모 요소의 색상을 자동으로 상속합니다:

```erb
<%# 부모의 text-primary 색상을 상속 %>
<div class="text-primary">
  <%= icon "heart" %>
</div>

<%# 호버 시 색상 변경 %>
<button class="text-muted-foreground hover:text-foreground">
  <%= icon "cog" %>
</button>
```

---

## Design Tokens 통합

undrew-design 토큰과 완벽하게 통합됩니다:

```erb
<%# 디자인 토큰 색상 사용 %>
<%= icon "check", class: "text-primary" %>
<%= icon "x-mark", class: "text-destructive" %>
<%= icon "user", class: "text-muted-foreground" %>
<%= icon "bell", class: "text-foreground" %>
```

---

## Variant 선택 가이드

### Outline (기본)
- **사용처**: 대부분의 UI 요소, 버튼, 네비게이션
- **특징**: 가볍고 섬세한 느낌
- **예시**: 메뉴 아이콘, 폼 아이콘

### Solid
- **사용처**: 강조가 필요한 상태 표시
- **특징**: 무게감 있고 눈에 띄는 느낌
- **예시**: 좋아요 활성화, 알림 뱃지, 상태 아이콘

---

## Real-world Examples

### 1. Like Button with Heart Icon

```erb
<%# 좋아요 버튼 - 상태에 따라 variant 변경 %>
<button class="<%= post.liked_by?(current_user) ? 'text-red-500' : 'text-muted-foreground' %>
               hover:text-red-500 transition-colors">
  <%= icon "heart",
           variant: post.liked_by?(current_user) ? :solid : :outline,
           size: "md" %>
  <span><%= post.likes_count %></span>
</button>
```

### 2. Search Input

```erb
<div class="relative">
  <div class="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground">
    <%= icon "search", size: "sm" %>
  </div>
  <input type="text"
         class="pl-10 pr-4 py-2 border border-border rounded-lg"
         placeholder="검색...">
</div>
```

### 3. Dropdown Trigger

```erb
<button class="flex items-center gap-2 text-muted-foreground hover:text-foreground">
  <span>정렬</span>
  <%= icon "chevron-down", size: "sm", class: "transition-transform" %>
</button>
```

### 4. User Avatar with Fallback

```erb
<div class="w-10 h-10 bg-muted rounded-full flex items-center justify-center text-muted-foreground">
  <%= icon "user", size: "md" %>
</div>
```

### 5. Action Menu

```erb
<div class="flex items-center gap-2">
  <button class="p-2 hover:bg-muted rounded-lg">
    <%= icon "pencil", size: "sm", class: "text-muted-foreground" %>
  </button>
  <button class="p-2 hover:bg-destructive/10 rounded-lg">
    <%= icon "trash", size: "sm", class: "text-destructive" %>
  </button>
</div>
```

---

## Migration Guide

### Before (Hardcoded SVG)

```erb
<svg class="w-5 h-5 text-green-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
</svg>
```

### After (Icon Helper)

```erb
<%= icon "check", size: "md", class: "text-green-500" %>
```

**Benefits**:
- ✅ **80% 코드 감소** - 한 줄로 간결하게
- ✅ **일관성** - 모든 아이콘이 같은 스타일
- ✅ **유지보수성** - 중앙 집중식 관리
- ✅ **접근성** - ARIA 지원 내장
- ✅ **타입 안정성** - 존재하지 않는 아이콘 시 경고

---

## Adding New Icons

새 아이콘을 추가하려면 `app/helpers/icon_helper.rb`의 `ICONS` Hash에 추가:

```ruby
ICONS = {
  # ... existing icons ...

  "new-icon": {
    outline: "M... path data ...",
    solid: "M... path data ..." # optional
  }
}.freeze
```

**Path Data 출처**:
- [Heroicons](https://heroicons.com/) - Tailwind Labs 공식
- [Lucide Icons](https://lucide.dev/) - 추천 (stroke-width 1.5)

---

## Performance

### Memory Efficient
- **Lazy Rendering**: 필요할 때만 SVG 생성
- **Constant Hash**: `ICONS.freeze`로 불변 객체
- **No External Dependencies**: 외부 라이브러리 없음

### Fast Lookup
- **Hash O(1)**: 아이콘 이름으로 즉시 조회
- **Cached Strings**: `content_tag`가 Rails에서 캐싱됨

---

## Accessibility

### 자동 ARIA 속성
```erb
<%# aria-hidden="true" (기본) %>
<%= icon "heart" %>

<%# role="img" + aria-label %>
<%= icon "heart", aria_label: "좋아요" %>
```

### 스크린 리더 고려사항
- **Decorative Icons**: aria_label 없음 → aria-hidden="true"
- **Meaningful Icons**: aria_label 제공 → role="img"

---

## Browser Support

- **Modern Browsers**: Chrome, Firefox, Safari, Edge (최신 2버전)
- **SVG Support**: IE9+ (하지만 IE11도 미지원 - Rails 8 요구사항)
- **currentColor**: 모든 모던 브라우저

---

## Testing

```ruby
# test/helpers/icon_helper_test.rb
require "test_helper"

class IconHelperTest < ActionView::TestCase
  test "renders icon with default parameters" do
    result = icon("check")
    assert_includes result, "w-5 h-5"
    assert_includes result, "M5 13l4 4L19 7"
  end

  test "renders icon with custom size" do
    result = icon("check", size: "lg")
    assert_includes result, "w-6 h-6"
  end

  test "renders solid variant" do
    result = icon("heart", variant: :solid)
    assert_includes result, 'fill="currentColor"'
  end

  test "warns for unknown icon" do
    assert_includes icon("unknown"), "[unknown]"
  end
end
```

---

**Version**: 1.0.0
**Created**: 2026-01-02
**Style**: Lucide Icons (stroke-width: 1.5)
**Total Icons**: 40+
