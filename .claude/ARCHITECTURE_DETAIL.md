# Startup Community Platform - 상세 아키텍처

> **이 문서는 분야별 상세 구조와 코딩 패턴을 설명합니다.**

---

## 1. 백엔드 아키텍처

### 1.1 Controllers (19개)

#### 핵심 컨트롤러 상세

**ApplicationController** - 기본 컨트롤러
```ruby
# 주요 메서드
current_user          # 현재 로그인 사용자
logged_in?            # 로그인 여부
require_login         # 인증 필터
set_current_user      # Current 설정
safe_redirect_to(url) # Open Redirect 방지

# 상수
POSTS_PER_PAGE = 50
```

**PostsController** - 게시글 CRUD
```ruby
# 액션: index, show, new, create, edit, update, destroy
# 이미지: Active Storage (최대 5개)
# 카테고리: community(자유/질문/홍보), outsourcing(구인/구직)

# Strong Parameters
def post_params
  params.require(:post).permit(:title, :content, :category, images: [])
end
```

**ChatRoomsController** - 실시간 채팅
```ruby
# 액션: index, show, create, confirm_deal, leave
# 컨텍스트: source_post (게시글에서 시작된 채팅)
# 거래 상태: pending → confirmed / cancelled
```

#### 인증 패턴
```ruby
# 로그인 필수 액션
before_action :require_login, except: [:index, :show]

# 권한 확인
before_action :authorize_owner, only: [:edit, :update, :destroy]

def authorize_owner
  redirect_to root_path unless @post.user == current_user
end
```

### 1.2 Models (15개)

#### 모델 관계도

```
User (사용자)
├─< Post (게시글) ──< Comment (댓글)
│                  ├─< Like (좋아요) [polymorphic]
│                  └─< Bookmark (스크랩) [polymorphic]
│
├─< ChatRoom (채팅방) ──< Message (메시지)
│   └─< ChatRoomParticipant (참여자)
│
├─< Notification (알림) [polymorphic notifiable]
│
├─< OAuthIdentity (OAuth 계정)
│
├─< JobPost (구인 공고) [deprecated → Post로 통합 중]
└─< TalentListing (구직 정보) [deprecated → Post로 통합 중]
```

#### Polymorphic 관계

**Like 모델**
```ruby
class Like < ApplicationRecord
  belongs_to :user
  belongs_to :likeable, polymorphic: true, counter_cache: true
  # likeable_type: "Post", "Comment"
end
```

**Bookmark 모델**
```ruby
class Bookmark < ApplicationRecord
  belongs_to :user
  belongs_to :bookmarkable, polymorphic: true
  # bookmarkable_type: "Post"
end
```

#### Concerns

**Likeable**
```ruby
# app/models/concerns/likeable.rb
module Likeable
  extend ActiveSupport::Concern

  included do
    has_many :likes, as: :likeable, dependent: :destroy
  end

  def liked_by?(user)
    return false unless user
    likes.exists?(user: user)
  end
end
```

#### Counter Cache 사용
```ruby
# Post 모델
has_many :comments, dependent: :destroy, counter_cache: true
has_many :likes, as: :likeable, dependent: :destroy, counter_cache: true

# 뷰에서 즉시 접근
post.comments_count  # DB 쿼리 없이 즉시 반환
post.likes_count
```

### 1.3 Services

#### AI::BaseAgent
```ruby
# app/services/ai/base_agent.rb
class Ai::BaseAgent
  def initialize
    @llm = LangchainConfig.default_llm
  end

  # 에러 핸들링 래퍼
  def with_error_handling
    yield
  rescue => e
    Rails.logger.error("AI Error: #{e.message}")
    { error: e.message }
  end

  # JSON 응답 파싱
  def parse_json_response(text)
    JSON.parse(text.gsub(/```json\n?|```/, ''))
  end
end
```

#### AI::IdeaAnalyzer
```ruby
# 사용법
analyzer = Ai::IdeaAnalyzer.new(idea_text)
result = analyzer.analyze

# 반환 구조
{
  summary: "아이디어 요약",
  target_users: [...],
  market_analysis: {...},
  recommendations: {...},
  score: { innovation: 8, feasibility: 7, market_fit: 8, overall: 7.7 },
  required_expertise: [...],
  analyzed_at: "2025-12-26T...",
  idea: "원본 아이디어"
}
```

---

## 2. 프론트엔드 아키텍처

### 2.1 Views 구조

#### 레이아웃 (layouts/)
```erb
<!-- application.html.erb 구조 -->
<!DOCTYPE html>
<html>
<head>
  <!-- Tailwind CDN, CSS Variables -->
  <%= og_meta_tags %>
  <%= csrf_meta_tags %>
</head>
<body>
  <%= render "shared/flash" %>
  <%= yield %>
  <%= render "shared/toast" %>
  <%= render "shared/floating_write_button" if logged_in? %>
</body>
</html>
```

#### 공유 컴포넌트 (shared/)

| 파일 | 용도 |
|------|------|
| `_avatar.html.erb` | 사용자 아바타 (사이즈 옵션) |
| `_bottom_nav.html.erb` | 하단 네비게이션 (5개 탭) |
| `_main_header.html.erb` | 상단 헤더 |
| `_like_button.html.erb` | 좋아요 버튼 |
| `_bookmark_button.html.erb` | 스크랩 버튼 |
| `_share_button.html.erb` | 공유 버튼 |
| `_floating_write_button.html.erb` | FAB 버튼 |
| `_toast.html.erb` | 토스트 알림 |
| `icons/` | SVG 아이콘 (14개) |

#### shadcn UI (components/ui/)
```
_button.html.erb   - 버튼 (variant: default, secondary, destructive, ghost)
_card.html.erb     - 카드 컨테이너
_avatar.html.erb   - 아바타
_badge.html.erb    - 배지
_input.html.erb    - 입력 필드
_textarea.html.erb - 텍스트 영역
```

### 2.2 Stimulus Controllers (33개)

#### 핵심 컨트롤러 패턴

**like_button_controller.js**
```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String, liked: Boolean }
  static targets = ["icon", "count"]

  async toggle() {
    const response = await fetch(this.urlValue, {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector("[name='csrf-token']").content,
        "Accept": "application/json"
      }
    })

    if (response.ok) {
      const data = await response.json()
      this.likedValue = data.liked
      this.countTarget.textContent = data.count
      this.updateIcon()
    }
  }
}
```

**live_search_controller.js**
```javascript
export default class extends Controller {
  static values = { url: String, debounceMs: { type: Number, default: 150 } }
  static targets = ["input", "results", "loading"]

  search() {
    clearTimeout(this.debounceTimer)
    this.debounceTimer = setTimeout(() => {
      this.performSearch()
    }, this.debounceMsValue)
  }

  async performSearch() {
    const response = await fetch(this.buildUrl())
    if (response.ok) {
      this.resultsTarget.innerHTML = await response.text()
    }
  }
}
```

#### 데이터 바인딩 패턴
```erb
<!-- HTML에서 Stimulus 연결 -->
<div data-controller="like-button"
     data-like-button-url-value="<%= toggle_like_path(@post) %>"
     data-like-button-liked-value="<%= @post.liked_by?(current_user) %>">
  <button data-action="click->like-button#toggle">
    <span data-like-button-target="icon">❤️</span>
    <span data-like-button-target="count"><%= @post.likes_count %></span>
  </button>
</div>
```

### 2.3 Helpers

#### ApplicationHelper 주요 메서드

```ruby
# 아바타 렌더링 (중요: render_avatar 아님!)
render_user_avatar(user, size: "md", ring: nil, class: nil)
# size: xs, sm, md, lg, xl, 2xl

# OG 메타태그 (UTF-8 인코딩 처리됨)
og_meta_tags(options = {})
post_og_meta_tags(post)

# 검색 하이라이팅
highlight_search(text, query)
highlight_snippet(text, query, max_length: 100)

# 페이지네이션
pagination_range(current_page, total_pages)

# 아바타 배경색
avatar_bg_color(name)  # 이름 기반 일관된 색상
```

#### Component Helpers

```ruby
# 버튼 렌더링
render_button("저장", variant: :primary, as: :button)
render_button("취소", variant: :secondary, href: back_path, as: :link)

# 아바타 렌더링 (shadcn 스타일)
render_avatar(src: user.avatar_url, alt: user.name, size: :md)
```

### 2.4 CSS/Tailwind

#### CSS Variables
```css
:root {
  --background: 0 0% 100%;
  --foreground: 0 0% 14.5%;
  --primary: 0 0% 20.5%;
  --primary-foreground: 0 0% 98.5%;
  --secondary: 0 0% 97%;
  --muted: 0 0% 97%;
  --muted-foreground: 0 0% 55.6%;
  --border: 0 0% 92.2%;
  --destructive: 0 84.2% 60.2%;
  --radius: 0.625rem;
}

.dark {
  --background: 0 0% 14.5%;
  --foreground: 0 0% 98.5%;
  /* ... */
}
```

#### 컴포넌트 스타일 패턴
```erb
<!-- 카드 -->
<article class="rounded-xl border bg-card text-card-foreground p-6">

<!-- 버튼 -->
<button class="bg-primary text-primary-foreground hover:bg-primary/90 px-4 py-2 rounded-lg">

<!-- 입력 필드 -->
<input class="w-full px-3 py-2 rounded-lg bg-secondary border-0 focus:ring-2 focus:ring-primary/20">
```

---

## 3. AI 에이전트 구조

### 3.1 LangChain 설정
```ruby
# lib/langchain_config.rb
module LangchainConfig
  def self.default_llm(temperature: 0.7)
    case Rails.application.credentials.dig(:ai, :provider)
    when "openai"
      openai_llm(temperature: temperature)
    else
      gemini_llm(temperature: temperature)
    end
  end

  def self.gemini_llm(model: "gemini-2.0-flash", temperature: 0.7)
    Langchain::LLM::GoogleGemini.new(
      api_key: Rails.application.credentials.dig(:google, :gemini_api_key),
      default_options: { chat_model: model, temperature: temperature }
    )
  end
end
```

### 3.2 IdeaAnalyzer 분석 항목
```
1. summary        - 아이디어 핵심 요약
2. target_users   - 주요 사용자 및 특성
3. market_analysis
   - market_potential  - 시장 잠재력
   - competitors       - 경쟁사
   - differentiation   - 차별화 포인트
4. recommendations
   - mvp_features      - MVP 기능
   - challenges        - 도전 과제
   - next_steps        - 다음 단계
5. score
   - innovation        - 혁신성 (1-10)
   - feasibility       - 실현 가능성 (1-10)
   - market_fit        - 시장 적합도 (1-10)
   - overall           - 종합 (1-10)
6. required_expertise - 필요 역할/기술
```

---

## 4. 실시간 기능

### 4.1 Solid Cable (WebSocket)
```yaml
# config/cable.yml
development:
  adapter: solid_cable
  polling_interval: 0.1.seconds
```

### 4.2 Turbo Streams 브로드캐스트
```ruby
# Message 모델에서 브로드캐스트
after_create_commit :broadcast_message

def broadcast_message
  Turbo::StreamsChannel.broadcast_append_to(
    "chat_room_#{chat_room_id}",
    target: "messages",
    partial: "messages/message",
    locals: { message: self }
  )
end
```

### 4.3 채팅 메시지 흐름
```
1. 사용자 메시지 입력 (new_message_controller.js)
2. POST /chat_rooms/:id/messages
3. Message 생성 → after_create_commit
4. Turbo Stream 브로드캐스트
5. 채팅방의 모든 참여자에게 실시간 표시
```

---

## 5. 인증/보안

### 5.1 Session 기반 인증
```ruby
# 로그인
session[:user_id] = user.id
session[:session_token] = SecureRandom.hex(32)

# 로그아웃
reset_session

# Session Fixation 방지
reset_session
session[:user_id] = user.id
```

### 5.2 OAuth 플로우
```
1. GET /oauth/:provider (OauthController#passthru)
2. 리다이렉트 → Provider 인증 페이지
3. 콜백 → GET /auth/:provider/callback
4. OmniauthCallbacksController#create
5. OAuthIdentity 생성/조회
6. User 연결 (같은 이메일 → 기존 계정에 연결)
7. 세션 생성
```

### 5.3 보안 설정
```ruby
# CSRF
protect_from_forgery with: :exception

# Open Redirect 방지
def safe_redirect_to(url)
  uri = URI.parse(url)
  if uri.host.nil? || uri.host == request.host
    redirect_to url
  else
    redirect_to root_path
  end
end

# Rack Attack
Rack::Attack.throttle("req/ip", limit: 300, period: 5.minutes) do |req|
  req.ip
end
```

---

## 6. 주요 데이터 흐름

### 6.1 온보딩 플로우
```
GET /                     → landing.html.erb
  └─ "시작하기" 클릭
GET /ai/input             → ai_input.html.erb
  └─ 아이디어 입력 & 제출
POST /ai/analyze          → IdeaAnalyzer.analyze
  └─ 분석 완료
GET /ai/result            → ai_result.html.erb
  └─ 전문가 클릭
GET /ai/expert/:id        → expert 상세
```

### 6.2 채팅 플로우
```
게시글 상세 (/posts/:id)
  └─ "문의하기" 클릭
POST /profiles/:id/start_chat
  └─ ChatRoom 생성 (source_post 연결)
GET /chat_rooms/:id
  └─ 메시지 입력
POST /chat_rooms/:id/messages
  └─ Turbo Stream 브로드캐스트
```

### 6.3 게시글 플로우
```
GET /community            → posts#index
  └─ FAB 클릭
GET /posts/new            → 글쓰기 폼
POST /posts               → 게시글 생성
GET /posts/:id            → 상세 페이지
  ├─ 좋아요 → POST /posts/:id/like
  ├─ 스크랩 → POST /posts/:id/bookmark
  └─ 댓글 → POST /posts/:id/comments
       └─ Notification 생성 → 작성자에게 알림
```

---

## 7. 프로젝트 특화 코딩 규칙

### 필수 패턴

| 패턴 | 이유 |
|------|------|
| `render_user_avatar()` 사용 | shadcn `render_avatar()`와 충돌 방지 |
| `og_meta_tags()`에서 UTF-8 처리 | 한글 URL 인코딩 문제 해결 |
| 검색 결과에 `onmousedown` 사용 | `onclick`은 blur로 인한 재검색 발생 |
| `includes()` 사용 | N+1 쿼리 방지 |
| Polymorphic 관계에 `as:` 지정 | likes/bookmarks 다형성 |

### 금지 패턴

| 패턴 | 문제 |
|------|------|
| `render_avatar(user)` | shadcn 메서드와 충돌 |
| `request.original_url` 직접 사용 | 한글 인코딩 오류 |
| `onclick`으로 검색 결과 네비게이션 | blur 시 검색 재실행 |
| `User.all` 페이지네이션 없이 | 성능 문제 |
| N+1 쿼리 | 성능 문제 |

### 명명 규칙

**Stimulus 컨트롤러**
```
단일 기능: {기능}_controller.js
  예: like_button_controller.js

복합 기능: {도메인}_{기능}_controller.js
  예: comment_like_button_controller.js
```

**뷰 파일**
```
Partial: _{이름}.html.erb
Turbo Stream: {액션}.turbo_stream.erb
카드 컴포넌트: _{도메인}_card.html.erb
```

---

## 8. 테스트 구조

```
test/
├── controllers/          # 컨트롤러 테스트
│   ├── posts_controller_test.rb
│   └── ...
├── models/               # 모델 테스트
│   ├── user_test.rb
│   └── ...
├── system/               # E2E 테스트
│   ├── posts_test.rb
│   └── ...
├── fixtures/             # 테스트 데이터
│   ├── users.yml
│   └── ...
└── test_helper.rb        # 테스트 헬퍼

# 테스트 실행
bin/rails test              # 전체
bin/rails test:models       # 모델만
bin/rails test:controllers  # 컨트롤러만
bin/rails test:system       # E2E만
```

---

## 9. 개발 명령어

```bash
# 서버 실행
bin/rails server

# 콘솔
bin/rails console

# 마이그레이션
bin/rails db:migrate
bin/rails db:migrate:status

# 테스트
bin/rails test

# Tailwind 빌드
bin/rails tailwindcss:build

# 라우팅 확인
bin/rails routes

# Credentials 편집
EDITOR=nano bin/rails credentials:edit
```
