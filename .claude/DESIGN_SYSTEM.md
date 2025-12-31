# Design System - Startup Community Platform

> Design OS 철학 기반 디자인 시스템 문서
> "AI 코딩 전에 명확한 설계 명세(spec)를 작성하라"

## 1. Design Tokens

### 1.1 색상 팔레트 (Color Palette)

#### Primary Colors
| 용도 | Tailwind Class | Hex | 사용 예시 |
|------|---------------|-----|----------|
| Primary Action | `bg-blue-500` | #3B82F6 | 주요 버튼, CTA |
| Primary Hover | `bg-blue-600` | #2563EB | 버튼 호버 상태 |
| Primary Text | `text-blue-600` | #2563EB | 링크, 강조 텍스트 |
| Primary Light | `bg-blue-50` | #EFF6FF | 선택된 상태 배경 |

#### Neutral Colors
| 용도 | Tailwind Class | Hex | 사용 예시 |
|------|---------------|-----|----------|
| Background | `bg-gray-50` | #F9FAFB | 페이지 배경 |
| Card | `bg-white` | #FFFFFF | 카드, 모달 배경 |
| Border | `border-gray-200` | #E5E7EB | 구분선, 테두리 |
| Disabled | `bg-gray-100` | #F3F4F6 | 비활성 상태 |
| Muted Text | `text-gray-500` | #6B7280 | 보조 텍스트, 플레이스홀더 |
| Body Text | `text-gray-700` | #374151 | 본문 텍스트 |
| Heading | `text-gray-900` | #111827 | 제목, 강조 텍스트 |

#### Status Colors
| 상태 | Tailwind Class | Hex | 사용 예시 |
|------|---------------|-----|----------|
| Success | `bg-green-500` | #22C55E | 성공 메시지, 활성 상태 |
| Success Light | `bg-green-100 text-green-800` | - | 성공 뱃지 |
| Error | `bg-red-500` | #EF4444 | 에러, 삭제 버튼 |
| Error Light | `bg-red-100 text-red-800` | - | 에러 뱃지 |
| Warning | `bg-yellow-500` | #EAB308 | 경고 메시지 |
| Warning Light | `bg-yellow-100 text-yellow-800` | - | 경고 뱃지 |
| Info | `bg-blue-500` | #3B82F6 | 정보 메시지 |
| Info Light | `bg-blue-100 text-blue-800` | - | 정보 뱃지 |

#### Category/Status Badges
| 카테고리 | Color | 용도 |
|---------|-------|------|
| 외주 가능 | `bg-green-500 text-white` | 프로필 상태 |
| 팀원 모집 중 | `bg-purple-500 text-white` | 프로필 상태 |
| 커스텀 상태 | `bg-pink-500 text-white` | 사용자 정의 상태 |
| 구인 | `bg-blue-100 text-blue-800` | 외주 카테고리 |
| 구직 | `bg-green-100 text-green-800` | 외주 카테고리 |

### 1.2 타이포그래피 (Typography)

#### Font Family
```css
/* 시스템 폰트 사용 */
font-family: ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont,
             "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
```

#### 제목 (Headings)
| 레벨 | Tailwind Class | Size | 용도 |
|------|---------------|------|------|
| H1 | `text-2xl font-bold` | 24px | 페이지 제목 |
| H2 | `text-xl font-semibold` | 20px | 섹션 제목 |
| H3 | `text-lg font-medium` | 18px | 카드 제목, 서브섹션 |
| H4 | `text-base font-medium` | 16px | 작은 섹션 제목 |

#### 본문 (Body)
| 용도 | Tailwind Class | Size |
|------|---------------|------|
| 기본 본문 | `text-base` | 16px |
| 보조 텍스트 | `text-sm text-gray-500` | 14px |
| 메타 정보 | `text-xs text-gray-400` | 12px |
| 캡션 | `text-xs` | 12px |

#### 줄 높이 (Line Height)
| 용도 | Tailwind Class | 값 |
|------|---------------|---|
| 제목 | `leading-tight` | 1.25 |
| 본문 | `leading-normal` | 1.5 |
| 긴 텍스트 | `leading-relaxed` | 1.625 |

### 1.3 간격 시스템 (Spacing)

#### 기본 단위
| Token | Value | Tailwind | 용도 |
|-------|-------|----------|------|
| xs | 4px | `p-1`, `m-1`, `gap-1` | 최소 간격 |
| sm | 8px | `p-2`, `m-2`, `gap-2` | 아이콘 간격 |
| md | 16px | `p-4`, `m-4`, `gap-4` | 기본 간격 |
| lg | 24px | `p-6`, `m-6`, `gap-6` | 카드 패딩 |
| xl | 32px | `p-8`, `m-8`, `gap-8` | 섹션 간격 |
| 2xl | 48px | `p-12`, `m-12`, `gap-12` | 대형 섹션 간격 |

#### 컴포넌트별 간격
| 컴포넌트 | 내부 패딩 | 외부 여백 |
|---------|----------|----------|
| 버튼 (sm) | `px-3 py-1.5` | - |
| 버튼 (md) | `px-4 py-2` | - |
| 버튼 (lg) | `px-6 py-3` | - |
| 카드 | `p-6` | `mb-4` |
| 입력 필드 | `px-4 py-2` | `mb-4` |
| 모달 | `p-6` | - |
| 섹션 | `py-8` | - |

### 1.4 그림자 (Shadows)

| 레벨 | Tailwind Class | 용도 |
|------|---------------|------|
| None | `shadow-none` | 플랫 요소 |
| SM | `shadow-sm` | 카드, 기본 상태 |
| MD | `shadow-md` | 호버 상태, 드롭다운 |
| LG | `shadow-lg` | 모달, 팝오버 |
| XL | `shadow-xl` | 모달 오버레이 |

### 1.5 둥근 모서리 (Border Radius)

| 레벨 | Tailwind Class | 용도 |
|------|---------------|------|
| SM | `rounded` | 작은 뱃지 |
| MD | `rounded-md` | 버튼 |
| LG | `rounded-lg` | 입력 필드, 작은 카드 |
| XL | `rounded-xl` | 카드, 모달 |
| Full | `rounded-full` | 아바타, 원형 버튼 |

## 2. 컴포넌트 라이브러리

### 2.1 버튼 (Buttons)

```erb
<%# Primary Button %>
<button class="px-4 py-2 bg-blue-500 hover:bg-blue-600 text-white font-medium rounded-lg transition-colors duration-200 disabled:opacity-50 disabled:cursor-not-allowed">
  저장하기
</button>

<%# Secondary Button %>
<button class="px-4 py-2 bg-gray-100 hover:bg-gray-200 text-gray-700 font-medium rounded-lg transition-colors duration-200">
  취소
</button>

<%# Outline Button %>
<button class="px-4 py-2 border border-gray-300 hover:bg-gray-50 text-gray-700 font-medium rounded-lg transition-colors duration-200">
  더 보기
</button>

<%# Danger Button %>
<button class="px-4 py-2 bg-red-500 hover:bg-red-600 text-white font-medium rounded-lg transition-colors duration-200">
  삭제하기
</button>

<%# Ghost Button %>
<button class="px-4 py-2 hover:bg-gray-100 text-gray-700 font-medium rounded-lg transition-colors duration-200">
  취소
</button>

<%# Icon Button %>
<button class="p-2 hover:bg-gray-100 rounded-full transition-colors duration-200" aria-label="메뉴">
  <svg class="w-5 h-5">...</svg>
</button>
```

### 2.2 입력 필드 (Input Fields)

```erb
<%# Text Input %>
<div class="space-y-1">
  <label for="email" class="block text-sm font-medium text-gray-700">
    이메일
  </label>
  <input
    type="email"
    id="email"
    class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 placeholder-gray-400 transition-colors duration-200"
    placeholder="example@email.com"
  >
</div>

<%# Textarea %>
<div class="space-y-1">
  <label for="content" class="block text-sm font-medium text-gray-700">
    내용
  </label>
  <textarea
    id="content"
    rows="4"
    class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 placeholder-gray-400 resize-none"
    placeholder="내용을 입력하세요"
  ></textarea>
</div>

<%# Select %>
<div class="space-y-1">
  <label for="category" class="block text-sm font-medium text-gray-700">
    카테고리
  </label>
  <select
    id="category"
    class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 bg-white"
  >
    <option value="">선택하세요</option>
    <option value="free">자유</option>
    <option value="question">질문</option>
  </select>
</div>

<%# Checkbox %>
<label class="flex items-center gap-2 cursor-pointer">
  <input type="checkbox" class="w-4 h-4 text-blue-500 border-gray-300 rounded focus:ring-blue-500">
  <span class="text-sm text-gray-700">로그인 상태 유지</span>
</label>

<%# Error State %>
<div class="space-y-1">
  <label class="block text-sm font-medium text-gray-700">이메일</label>
  <input
    type="email"
    class="w-full px-4 py-2 border border-red-500 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-red-500"
  >
  <p class="text-xs text-red-500">올바른 이메일 형식을 입력해주세요.</p>
</div>
```

### 2.3 카드 (Cards)

```erb
<%# Basic Card %>
<div class="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
  <h3 class="text-lg font-semibold text-gray-900 mb-2">카드 제목</h3>
  <p class="text-gray-600 text-sm">카드 내용</p>
</div>

<%# Post Card %>
<article class="bg-white rounded-xl shadow-sm border border-gray-100 p-6 hover:shadow-md transition-shadow duration-200">
  <header class="flex items-center gap-3 mb-4">
    <%= render_user_avatar(post.user, size: "md") %>
    <div>
      <p class="font-medium text-gray-900"><%= post.user.name %></p>
      <p class="text-xs text-gray-400"><%= time_ago_in_words(post.created_at) %> 전</p>
    </div>
  </header>
  <h2 class="text-lg font-semibold text-gray-900 mb-2"><%= post.title %></h2>
  <p class="text-gray-600 text-sm line-clamp-3"><%= post.content %></p>
  <footer class="flex items-center gap-4 mt-4 pt-4 border-t border-gray-100">
    <span class="text-sm text-gray-500">
      <svg class="w-4 h-4 inline mr-1">...</svg>
      <%= post.likes_count %>
    </span>
    <span class="text-sm text-gray-500">
      <svg class="w-4 h-4 inline mr-1">...</svg>
      <%= post.comments_count %>
    </span>
  </footer>
</article>

<%# Interactive Card (Link) %>
<%= link_to post_path(post), class: "block bg-white rounded-xl shadow-sm border border-gray-100 p-6 hover:shadow-md hover:border-blue-200 transition-all duration-200" do %>
  ...
<% end %>
```

### 2.4 뱃지 (Badges)

```erb
<%# Status Badge %>
<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
  활성
</span>

<%# Category Badge %>
<span class="inline-flex items-center px-2 py-1 rounded-md text-xs font-medium bg-gray-100 text-gray-600">
  자유
</span>

<%# Profile Status Badge %>
<span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-green-500 text-white">
  외주 가능
</span>

<%# Count Badge %>
<span class="inline-flex items-center justify-center w-5 h-5 rounded-full text-xs font-medium bg-red-500 text-white">
  3
</span>
```

### 2.5 아바타 (Avatar)

```erb
<%# 반드시 render_user_avatar 헬퍼 사용 %>
<%= render_user_avatar(user, size: "sm") %>  <%# 32px %>
<%= render_user_avatar(user, size: "md") %>  <%# 40px %>
<%= render_user_avatar(user, size: "lg") %>  <%# 64px %>
<%= render_user_avatar(user, size: "xl") %>  <%# 96px %>

<%# ⚠️ 금지: render_avatar 사용 금지 (shadcn 메서드 충돌) %>
```

### 2.6 알림 (Alerts / Flash Messages)

```erb
<%# Success %>
<div class="p-4 bg-green-50 border border-green-200 rounded-lg" role="alert">
  <div class="flex items-center gap-3">
    <svg class="w-5 h-5 text-green-500">...</svg>
    <p class="text-green-800">저장되었습니다.</p>
  </div>
</div>

<%# Error %>
<div class="p-4 bg-red-50 border border-red-200 rounded-lg" role="alert">
  <div class="flex items-center gap-3">
    <svg class="w-5 h-5 text-red-500">...</svg>
    <p class="text-red-800">오류가 발생했습니다.</p>
  </div>
</div>

<%# Warning %>
<div class="p-4 bg-yellow-50 border border-yellow-200 rounded-lg" role="alert">
  <div class="flex items-center gap-3">
    <svg class="w-5 h-5 text-yellow-500">...</svg>
    <p class="text-yellow-800">주의가 필요합니다.</p>
  </div>
</div>

<%# Info %>
<div class="p-4 bg-blue-50 border border-blue-200 rounded-lg" role="alert">
  <div class="flex items-center gap-3">
    <svg class="w-5 h-5 text-blue-500">...</svg>
    <p class="text-blue-800">참고 정보입니다.</p>
  </div>
</div>
```

### 2.7 모달 (Modal)

```erb
<div class="fixed inset-0 z-50 overflow-y-auto" aria-modal="true" role="dialog">
  <%# Backdrop %>
  <div class="fixed inset-0 bg-black/50 transition-opacity"></div>

  <%# Panel %>
  <div class="flex min-h-full items-center justify-center p-4">
    <div class="relative bg-white rounded-xl shadow-xl max-w-md w-full p-6">
      <%# Header %>
      <div class="flex items-center justify-between mb-4">
        <h2 class="text-xl font-bold text-gray-900">모달 제목</h2>
        <button class="p-1 hover:bg-gray-100 rounded-full" aria-label="닫기">
          <svg class="w-5 h-5">...</svg>
        </button>
      </div>

      <%# Content %>
      <div class="mb-6">
        <p class="text-gray-600">모달 내용</p>
      </div>

      <%# Footer %>
      <div class="flex justify-end gap-3">
        <button class="px-4 py-2 text-gray-700 hover:bg-gray-100 rounded-lg">
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

## 3. 레이아웃 패턴

### 3.1 페이지 레이아웃

```erb
<%# 기본 페이지 %>
<div class="min-h-screen bg-gray-50">
  <%= render "shared/header" %>

  <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
    <%= yield %>
  </main>

  <%= render "shared/footer" %>
</div>

<%# 2단 레이아웃 (사이드바) %>
<div class="flex flex-col lg:flex-row gap-8">
  <div class="flex-1 min-w-0">
    <%= yield %>
  </div>
  <aside class="w-full lg:w-80 shrink-0">
    <%= render "shared/sidebar" %>
  </aside>
</div>

<%# 전체 너비 (채팅 등) %>
<div class="min-h-screen bg-gray-50">
  <%= render "shared/header" %>
  <main class="h-[calc(100vh-64px)]">
    <%= yield %>
  </main>
</div>
```

### 3.2 반응형 그리드

```erb
<%# 카드 그리드 %>
<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
  <% @posts.each do |post| %>
    <%= render post %>
  <% end %>
</div>

<%# 리스트 레이아웃 %>
<div class="space-y-4">
  <% @posts.each do |post| %>
    <%= render post %>
  <% end %>
</div>
```

## 4. 상태 (States)

### 4.1 상호작용 상태

| 상태 | 스타일 변화 |
|------|-----------|
| Default | 기본 스타일 |
| Hover | 배경색 약간 어둡게, 그림자 추가 |
| Focus | ring-2 + ring-offset-2 |
| Active | 배경색 더 어둡게, 약간 축소 |
| Disabled | opacity-50 + cursor-not-allowed |
| Loading | 스피너 표시 + 비활성화 |

### 4.2 폼 상태

| 상태 | 스타일 |
|------|-------|
| Default | `border-gray-300` |
| Focus | `border-blue-500 ring-2 ring-blue-500` |
| Error | `border-red-500` + 에러 메시지 |
| Success | `border-green-500` |
| Disabled | `bg-gray-100 cursor-not-allowed` |

## 5. 애니메이션

### 5.1 기본 트랜지션

```css
/* 기본 */
transition-colors duration-200

/* 그림자 */
transition-shadow duration-200

/* 전체 (색상 + 그림자 + 변환) */
transition-all duration-200

/* 느린 애니메이션 */
transition-all duration-300
```

### 5.2 접근성 고려

```css
/* 모션 감소 선호 사용자를 위한 설정 */
@media (prefers-reduced-motion: reduce) {
  * {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

## 6. 접근성 (A11y) 가이드라인

### 필수 사항

1. **색상 대비**: WCAG AA 기준 (4.5:1) 이상
2. **포커스 표시**: 모든 상호작용 요소에 명확한 포커스 스타일
3. **키보드 네비게이션**: Tab으로 모든 요소 접근 가능
4. **스크린 리더**: 적절한 aria-* 속성 사용
5. **대체 텍스트**: 모든 이미지에 alt 속성

### aria 속성 가이드

```erb
<%# 버튼 %>
<button aria-label="메뉴 열기">...</button>

<%# 모달 %>
<div role="dialog" aria-modal="true" aria-labelledby="modal-title">
  <h2 id="modal-title">제목</h2>
</div>

<%# 알림 %>
<div role="alert" aria-live="polite">메시지</div>

<%# 탭 %>
<div role="tablist">
  <button role="tab" aria-selected="true">탭 1</button>
</div>
```

## 7. 프로젝트 특화 규칙

### 금지 패턴

| 패턴 | 문제 | 대안 |
|------|------|------|
| `render_avatar(user)` | shadcn 메서드 충돌 | `render_user_avatar(user)` |
| `request.original_url` 직접 사용 | 한글 인코딩 오류 | `og_meta_tags()` 헬퍼 |
| `onclick` 검색 결과 | blur 시 재검색 | `onmousedown` 사용 |

### 색상 사용 규칙

- **Blue**: 주요 액션, 링크
- **Gray**: 중립적 요소, 배경
- **Green**: 성공, 외주 가능 상태
- **Red**: 에러, 삭제
- **Purple**: 팀원 모집 상태
- **Pink**: 커스텀 상태
