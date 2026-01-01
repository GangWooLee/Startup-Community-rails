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

### 2.2 Stimulus Controllers (39개)

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

## 3. AI 멀티에이전트 시스템

### 3.1 아키텍처 개요

```
OnboardingController#ai_result
    ↓
Ai::Orchestrators::AnalysisOrchestrator
    ├─ Step 1: SummaryAgent (gemini-2.0-flash-lite)
    │   → summary, core_value, problem_statement
    ├─ Step 2: TargetUserAgent (gemini-3-flash-preview)
    │   → target_users, personas, pain_points, goals
    ├─ Step 3: MarketAnalysisAgent (gemini-3-flash-preview)
    │   ├─ Mode 1: GeminiGroundingTool (실시간 웹 검색)
    │   ├─ Mode 2: MarketDataTool + CompetitorDatabaseTool
    │   └─ Mode 3: LLM 직접 호출 (fallback)
    │   → market_size, trends, competitors, differentiation
    ├─ Step 4: StrategyAgent (gemini-3-flash-preview)
    │   → mvp_features, challenges, next_steps, actions
    └─ Step 5: ScoringAgent (gemini-3-flash-preview)
        → overall score, weak_areas, strong_areas, required_expertise
```

### 3.2 LangchainRB 설정

```ruby
# lib/langchain_config.rb
module LangchainConfig
  # 에이전트별 최적화된 모델 설정
  AGENT_MODEL_CONFIGS = {
    summary: { model: "gemini-2.0-flash-lite", temperature: 0.5 },
    target_user: { model: "gemini-3-flash-preview", temperature: 0.7 },
    market_analysis: { model: "gemini-3-flash-preview", temperature: 0.7 },
    strategy: { model: "gemini-3-flash-preview", temperature: 0.7 },
    scoring: { model: "gemini-3-flash-preview", temperature: 0.5 }
  }.freeze

  def self.llm_for_agent(agent_type)
    config = AGENT_MODEL_CONFIGS[agent_type]
    gemini_llm(model: config[:model], temperature: config[:temperature])
  end

  def self.gemini_api_key
    Rails.application.credentials.dig(:gemini, :api_key) ||
      Rails.application.credentials.dig(:google, :gemini_api_key) ||
      ENV["GOOGLE_GEMINI_API_KEY"] ||
      ENV["GEMINI_API_KEY"]
  end
end
```

### 3.3 5개 전문 에이전트

| 에이전트 | 역할 | 모델 | 출력 |
|---------|------|------|------|
| **SummaryAgent** | 아이디어 핵심 요약 | gemini-2.0-flash-lite | summary, core_value, problem_statement |
| **TargetUserAgent** | 타겟 사용자 분석 | gemini-3-flash-preview | target_users, personas, pain_points, goals |
| **MarketAnalysisAgent** | 시장 분석 | gemini-3-flash-preview | market_size, trends, competitors, differentiation |
| **StrategyAgent** | 실행 전략 | gemini-3-flash-preview | mvp_features, challenges, next_steps, actions |
| **ScoringAgent** | 종합 평가 | gemini-3-flash-preview | overall, weak_areas, strong_areas, required_expertise |

### 3.4 LangchainRB 도구

```ruby
# app/services/ai/tools/

# 1. GeminiGroundingTool - 실시간 웹 검색
class GeminiGroundingTool
  # Gemini 2.0 네이티브 Google Search 통합
  # 시장 규모, 최신 트렌드, 경쟁사 정보 실시간 검색
  def call(query:, idea:)
    # google_search_retrieval 도구로 실시간 데이터 조회
  end
end

# 2. MarketDataTool - 정적 시장 데이터
class MarketDataTool
  # 30+ 산업별 시장 규모/성장률/트렌드 데이터
  MARKET_DATA = {
    "fintech" => { size: "5조원", growth: "15%", trends: [...] },
    "edtech" => { size: "3조원", growth: "20%", trends: [...] },
    # ...
  }
end

# 3. CompetitorDatabaseTool - 경쟁사 정보
class CompetitorDatabaseTool
  # 80+ 분야별 주요 경쟁사 정보
  COMPETITOR_DATA = {
    "community_platform" => ["블라인드", "리멤버", "로켓펀치"],
    "freelance_matching" => ["크몽", "숨고", "탈잉"],
    # ...
  }
end
```

### 3.5 오케스트레이터 패턴

```ruby
# app/services/ai/orchestrators/analysis_orchestrator.rb
class Ai::Orchestrators::AnalysisOrchestrator
  def analyze
    results = {}

    # 순차 실행 (이전 결과를 다음 에이전트에 전달)
    results[:summary] = SummaryAgent.new(context).analyze
    results[:target_user] = TargetUserAgent.new(context.merge(previous: results)).analyze
    results[:market_analysis] = MarketAnalysisAgent.new(context.merge(previous: results)).analyze
    results[:strategy] = StrategyAgent.new(context.merge(previous: results)).analyze
    results[:score] = ScoringAgent.new(context.merge(previous: results)).analyze

    merge_results(results)
  end
end
```

### 3.6 에이전트 실행 결과 구조

```ruby
{
  # SummaryAgent
  summary: "아이디어 한 줄 요약",
  core_value: "핵심 가치",
  problem_statement: "해결하려는 문제",

  # TargetUserAgent
  target_users: {
    primary: "주요 타겟",
    characteristics: [...],
    personas: [{ name: "...", age_range: "...", description: "..." }]
  },

  # MarketAnalysisAgent
  market_analysis: {
    potential: "높음/중간/낮음",
    market_size: "시장 규모",
    trends: "트렌드",
    competitors: ["경쟁사1", "경쟁사2"],
    differentiation: "차별화 포인트"
  },

  # StrategyAgent
  recommendations: {
    mvp_features: ["MVP 기능1", "MVP 기능2"],
    challenges: ["도전과제 → 대응방안"],
    next_steps: ["다음 단계1", "다음 단계2"]
  },
  actions: [{ title: "액션", description: "설명" }],

  # ScoringAgent
  score: {
    overall: 72,  # 0-100
    weak_areas: ["시장 분석", "수익 모델"],
    strong_areas: ["아이디어 독창성", "타겟 명확성"],
    improvement_tips: ["개선 팁1", "개선 팁2"]
  },
  required_expertise: {
    roles: ["Developer", "Designer"],
    skills: ["React", "Node.js", "UI/UX"],
    description: "필요한 전문성 설명"
  },

  # 메타데이터
  metadata: {
    agents_completed: 5,
    agents_total: 5,
    execution_time: 55.25,
    partial_success: false
  }
}
```

### 3.7 AI 서비스 파일 구조

```
app/services/ai/
├── base_agent.rb                    # 기본 에이전트 클래스
├── follow_up_generator.rb           # 추가 질문 생성기
├── expert_score_predictor.rb        # 전문가 점수 예측
├── agents/
│   ├── summary_agent.rb             # 요약 에이전트
│   ├── target_user_agent.rb         # 타겟 사용자 에이전트
│   ├── market_analysis_agent.rb     # 시장 분석 에이전트
│   ├── strategy_agent.rb            # 전략 에이전트
│   └── scoring_agent.rb             # 점수 에이전트
├── orchestrators/
│   └── analysis_orchestrator.rb     # 멀티에이전트 오케스트레이터
└── tools/
    ├── market_data_tool.rb          # 시장 데이터 도구
    ├── competitor_database_tool.rb  # 경쟁사 데이터베이스 도구
    └── gemini_grounding_tool.rb     # Gemini 실시간 웹 검색 도구
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

### 5.2 Remember Me (로그인 상태 유지)

```ruby
# User 모델
class User < ApplicationRecord
  attr_accessor :remember_token

  # remember_digest 저장 (BCrypt 암호화)
  def remember
    self.remember_token = SecureRandom.urlsafe_base64
    update_column(:remember_digest, BCrypt::Password.create(remember_token))
  end

  # remember_digest 삭제
  def forget
    update_column(:remember_digest, nil)
  end

  # 토큰 검증
  def authenticated?(remember_token)
    return false if remember_digest.nil?
    BCrypt::Password.new(remember_digest).is_password?(remember_token)
  end
end

# SessionsController
def create
  user = User.find_by(email: params[:email].downcase)

  if user&.authenticate(params[:password])
    log_in(user)
    # Remember Me 체크 시 영구 쿠키 저장 (20년)
    params[:remember_me] == "1" ? remember(user) : forget(user)
    redirect_to community_path
  else
    flash.now[:alert] = "이메일 또는 비밀번호가 올바르지 않습니다."
    render :new, status: :unprocessable_entity
  end
end

# ApplicationController - 자동 로그인
def current_user
  if session[:user_id]
    @current_user ||= User.find_by(id: session[:user_id])
  elsif cookies.signed[:user_id]
    user = User.find_by(id: cookies.signed[:user_id])
    if user&.authenticated?(cookies[:remember_token])
      log_in(user)
      @current_user = user
    end
  end
end
```

**Remember Me 플로우**:
```
1. 로그인 폼에서 "로그인 상태 유지" 체크박스 선택
2. POST /login (remember_me=1)
3. User#remember 호출 → remember_digest 저장
4. 영구 쿠키 설정: user_id, remember_token (20년 유효)
5. 브라우저 재시작 후 접속 시:
   - session[:user_id] 없음
   - cookies.signed[:user_id] 확인
   - User#authenticated? 검증
   - 자동 로그인
```

### 5.3 OAuth 플로우
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

### 5.5 회원 탈퇴 시스템

**아키텍처 개요**:
```
사용자 탈퇴 요청
    ↓
UserDeletionsController#create
    ↓
Users::DeletionService
    ├─ 1. 즉시 익명화 (User 모델)
    │   └─ name → "탈퇴한 사용자", email → "deleted_#{id}@..."
    ├─ 2. 원본 정보 암호화 보관 (UserDeletion 모델)
    │   └─ AES-256-GCM 암호화 (Rails encrypts)
    └─ 3. 5년 후 자동 파기 예약
        └─ destroy_scheduled_at 설정

관리자 조회
    ↓
Admin::UserDeletionsController
    ├─ reveal_personal_info (복호화)
    └─ AdminViewLog 자동 기록 (감사 로그)

5년 후 자동 파기
    ↓
DestroyExpiredDeletionsJob
    └─ Solid Queue 스케줄러로 매일 실행
```

**암호화 구현**:
```ruby
# app/models/user_deletion.rb
class UserDeletion < ApplicationRecord
  # Rails 7 Active Record Encryption
  encrypts :email_original
  encrypts :name_original
  encrypts :phone_original
  encrypts :snapshot_data
  encrypts :email_hash, deterministic: true  # 검색 가능

  RETENTION_PERIOD = 5.years
end

# config/credentials.yml.enc
active_record_encryption:
  primary_key: [32바이트 키]
  deterministic_key: [32바이트 키]
  key_derivation_salt: [32바이트 솔트]
```

**탈퇴 서비스**:
```ruby
# app/services/users/deletion_service.rb
class Users::DeletionService
  def call
    ActiveRecord::Base.transaction do
      # 1. 탈퇴 기록 생성 (원본 정보 암호화 보관)
      create_deletion_record

      # 2. 즉시 익명화
      anonymize_user

      # 3. 관련 데이터 처리 (게시글/댓글은 유지)
      process_related_data
    end
  end

  private

  def anonymize_user
    @user.update!(
      name: "탈퇴한 사용자",
      email: "deleted_#{@user.id}@deleted.local",
      bio: nil,
      avatar_url: nil,
      deleted_at: Time.current
    )
  end
end
```

---

## 6. 주요 데이터 흐름

### 6.1 AI 온보딩 플로우
```
GET /                     → landing.html.erb
  └─ "시작하기" 클릭 (로그인 필수)
GET /ai/input             → ai_input.html.erb
  └─ 아이디어 입력 & 제출
POST /ai/questions        → FollowUpGenerator로 추가 질문 생성 (JSON)
  └─ 추가 질문 답변
GET /ai/result            → ai_result.html.erb
  ├─ AnalysisOrchestrator 실행 (5개 에이전트 순차)
  │   ├─ SummaryAgent → TargetUserAgent → MarketAnalysisAgent
  │   └─ StrategyAgent → ScoringAgent
  ├─ ExpertMatcher로 추천 전문가 검색
  └─ ExpertScorePredictor로 점수 향상 예측
GET /ai/expert/:id        → expert 프로필 오버레이 (Turbo Stream)
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
