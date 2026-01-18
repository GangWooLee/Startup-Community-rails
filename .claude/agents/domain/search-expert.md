---
name: search-expert
description: 검색 시스템 전문가 - 라이브 검색, 카테고리 필터, 페이지네이션
triggers:
  - 검색
  - search
  - 필터
  - filter
  - 라이브 검색
related_skills:
  - query-object
---

# Search Expert (검색 전문가)

## 🎯 역할

검색 기능의 모든 측면을 담당합니다:
- 라이브 검색 (실시간 결과)
- 카테고리/타입 필터링
- 페이지네이션
- UTF-8 인코딩 처리
- 검색 결과 하이라이팅

---

## 📁 담당 파일

### Controllers
```
app/controllers/search_controller.rb          # 검색 메인
```

### Services
```
app/services/search/query_executor.rb         # 검색 쿼리 실행
app/services/search/result_formatter.rb       # 결과 포맷팅
```

### JavaScript (Stimulus)
```
app/javascript/controllers/live_search_controller.js   # 라이브 검색
```

### Views
```
app/views/search/
├── index.html.erb            # 검색 결과 페이지
├── _results.html.erb         # 결과 목록
├── _post_result.html.erb     # 게시글 결과 카드
├── _user_result.html.erb     # 사용자 결과 카드
└── _no_results.html.erb      # 결과 없음
```

### Tests
```
test/controllers/search_controller_test.rb
test/services/search/*_test.rb
test/system/search_test.rb
```

---

## 🔧 핵심 패턴

### 1. 라이브 검색 (Debounce)

```javascript
// live_search_controller.js
static values = {
  debounce: { type: Number, default: 300 }
}

search() {
  clearTimeout(this.timeout)
  this.timeout = setTimeout(() => {
    this.performSearch()
  }, this.debounceValue)
}

performSearch() {
  const query = this.inputTarget.value.trim()
  if (query.length < 2) return  // 최소 2글자

  fetch(`/search?q=${encodeURIComponent(query)}`, {
    headers: { "Accept": "text/vnd.turbo-stream.html" }
  })
  .then(response => response.text())
  .then(html => Turbo.renderStreamMessage(html))
}
```

### 2. 검색 결과 클릭 (blur 문제 해결)

```erb
<%# ❌ 금지 - blur 시 재검색되어 결과 사라짐 %>
<div onclick="window.location.href='...'">

<%# ✅ onmousedown 사용 %>
<div onmousedown="event.preventDefault(); window.location.href='<%= post_path(result) %>'">
```

### 3. UTF-8 인코딩 처리

```ruby
# ❌ 한글 인코딩 오류
<meta property="og:url" content="<%= request.original_url %>">

# ✅ 헬퍼 사용
def og_meta_tags(title:, description:)
  safe_url = request.original_url.encode('UTF-8', invalid: :replace)
  # ...
end
```

### 4. 검색 쿼리 실행

```ruby
# QueryExecutor
class Search::QueryExecutor
  def call
    scope = Post.includes(:user)
                .where("title LIKE ? OR content LIKE ?",
                       "%#{sanitized_query}%", "%#{sanitized_query}%")

    scope = scope.where(category: @category) if @category.present?
    scope.order(created_at: :desc).page(@page).per(20)
  end

  private

  def sanitized_query
    # SQL Injection 방지
    ActiveRecord::Base.sanitize_sql_like(@query)
  end
end
```

### 5. 결과 하이라이팅

```ruby
# ResultFormatter
def highlight(text, query)
  return text if query.blank?
  text.gsub(/(#{Regexp.escape(query)})/i, '<mark>\1</mark>').html_safe
end
```

---

## ⚠️ 주의사항

### 금지 패턴

| 패턴 | 문제 | 대안 |
|------|------|------|
| `onclick` 검색 결과 | blur 시 재검색 | `onmousedown` 사용 |
| Raw SQL LIKE | SQL Injection | `sanitize_sql_like` 사용 |
| 페이지네이션 없음 | 성능 문제 | Kaminari 사용 |
| 인코딩 직접 처리 | UTF-8 오류 | `og_meta_tags` 헬퍼 |

### N+1 방지

```ruby
# ❌ N+1 발생
Post.where("title LIKE ?", "%#{query}%").each { |p| p.user.name }

# ✅ includes 사용
Post.includes(:user).where("title LIKE ?", "%#{query}%")
```

---

## 🗺️ 검색 최적화 로드맵

### 현재 구현 상태
| 기능 | 상태 | 구현 방식 |
|------|------|----------|
| 기본 검색 | ✅ 완료 | SQL LIKE |
| 카테고리 필터 | ✅ 완료 | WHERE 조건 |
| 페이지네이션 | ✅ 완료 | Kaminari |
| 라이브 검색 | ✅ 완료 | Turbo Stream + Debounce |
| UTF-8 인코딩 | ✅ 완료 | `og_meta_tags` 헬퍼 |

### 향후 개선 방향
| 기능 | 우선순위 | 구현 방안 |
|------|---------|----------|
| 자동완성 | 🟡 중간 | Stimulus + Turbo Stream |
| 전문 검색 | 🟡 중간 | PostgreSQL Full-Text Search |
| 검색 분석 | 🟢 낮음 | 검색어 로깅 + 인기 검색어 |
| 고급 필터 | 🟢 낮음 | 날짜, 작성자, 좋아요 수 |

### 자동완성 구현 힌트

```javascript
// live_search_controller.js - 자동완성 확장 (XSS 안전)
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "suggestions"]
  static values = { minLength: { type: Number, default: 2 } }

  async fetchSuggestions() {
    const query = this.inputTarget.value.trim()
    if (query.length < this.minLengthValue) {
      this.hideSuggestions()
      return
    }

    try {
      const response = await fetch(`/search/autocomplete?q=${encodeURIComponent(query)}`)
      const suggestions = await response.json()
      this.renderSuggestions(suggestions)
    } catch (error) {
      console.error("[Search] Autocomplete failed:", error)
    }
  }

  // ✅ XSS 안전: textContent 사용
  renderSuggestions(suggestions) {
    // 기존 내용 제거
    this.suggestionsTarget.replaceChildren()

    suggestions.slice(0, 5).forEach(text => {
      const li = document.createElement("li")
      li.textContent = text  // XSS 방지
      li.dataset.action = "mousedown->live-search#select"
      li.dataset.value = text
      this.suggestionsTarget.appendChild(li)
    })

    this.showSuggestions()
  }

  select(event) {
    event.preventDefault()  // blur 방지
    this.inputTarget.value = event.target.dataset.value
    this.hideSuggestions()
    this.performSearch()
  }
}
```

```ruby
# app/controllers/search_controller.rb
def autocomplete
  query = params[:q].to_s.strip
  return render json: [] if query.length < 2

  suggestions = Post
    .where("title LIKE ?", "#{sanitize_sql_like(query)}%")
    .limit(10)
    .pluck(:title)
    .uniq

  render json: suggestions
end

private

def sanitize_sql_like(string)
  ActiveRecord::Base.sanitize_sql_like(string)
end
```

---

## ⚠️ UTF-8 인코딩 함정 체크리스트

### 주요 함정 및 해결책

| 상황 | 문제 | 해결책 |
|------|------|--------|
| URL 한글 파라미터 | `?q=검색어` 인코딩 오류 | `encodeURIComponent()` 사용 |
| OG 메타태그 URL | 한글 깨짐 | `og_meta_tags()` 헬퍼 사용 |
| 파일명 한글 | 다운로드 오류 | `filename*=UTF-8''` 헤더 |
| JSON 응답 | 한글 이스케이프 | `ActiveSupport::JSON.encode` |

### JavaScript URL 인코딩

```javascript
// ❌ 한글 인코딩 오류
fetch(`/search?q=${query}`)

// ✅ 올바른 인코딩
fetch(`/search?q=${encodeURIComponent(query)}`)

// ✅ URLSearchParams 사용 (자동 인코딩)
const params = new URLSearchParams({ q: query, category: "free" })
fetch(`/search?${params}`)
```

### Ruby URL 인코딩

```ruby
# ❌ 한글 인코딩 오류
redirect_to "/search?q=#{query}"

# ✅ URI.encode_www_form 사용
redirect_to "/search?#{URI.encode_www_form(q: query)}"

# ✅ 또는 CGI.escape 사용
redirect_to "/search?q=#{CGI.escape(query)}"
```

### OG 메타태그 헬퍼

```ruby
# app/helpers/application_helper.rb
def og_meta_tags(title:, description: nil, image: nil)
  # URL 안전하게 인코딩
  safe_url = begin
    URI.parse(request.original_url).to_s
  rescue URI::InvalidURIError
    request.base_url + CGI.escape(request.fullpath)
  end

  content_tag(:meta, nil, property: "og:url", content: safe_url) +
  content_tag(:meta, nil, property: "og:title", content: title) +
  (description ? content_tag(:meta, nil, property: "og:description", content: description) : "") +
  (image ? content_tag(:meta, nil, property: "og:image", content: image) : "")
end
```

---

## ✅ 체크리스트

### 검색 기능 수정 시
- [ ] SQL Injection 방지 확인 (`sanitize_sql_like`)
- [ ] N+1 쿼리 확인 (`includes` 사용)
- [ ] 페이지네이션 적용 확인
- [ ] UTF-8 인코딩 처리 확인

### 라이브 검색 수정 시
- [ ] Debounce 적용 확인 (300ms 권장)
- [ ] 최소 글자 수 확인 (2글자)
- [ ] `onmousedown` 사용 확인 (blur 문제)
- [ ] Turbo Stream 타겟 확인
- [ ] `encodeURIComponent` 사용 확인

### 자동완성 구현 시
- [ ] XSS 방지 (`textContent` 사용, `innerHTML` 금지)
- [ ] 결과 제한 (최대 5-10개)
- [ ] 키보드 네비게이션 지원
- [ ] 로딩 상태 표시

---

## 📚 참조 문서

- [CLAUDE.md - 프로젝트 특화 규칙](../../CLAUDE.md#프로젝트-특화-규칙-중요)
- [rules/backend/rails-anti-patterns.md](../../rules/backend/rails-anti-patterns.md)
- [standards/tailwind-frontend.md](../../standards/tailwind-frontend.md)
