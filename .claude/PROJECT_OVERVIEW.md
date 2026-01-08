# Startup Community Platform - 프로젝트 개요

> **이 문서는 새 세션에서 프로젝트를 빠르게 이해하기 위한 핵심 문서입니다.**

## 프로젝트 정보

| 항목 | 값 |
|------|-----|
| **프로젝트명** | Startup Community Platform |
| **버전** | MVP v0.9.0 |
| **Rails** | 8.1.1 |
| **Ruby** | 3.4.7 |
| **마지막 업데이트** | 2026-01-08 |
| **프로덕션 URL** | https://undrewai.com |

**핵심 비전**: "아이디어·사람·외주가 한 공간에서 연결되는 최초의 창업 커뮤니티"

---

## 기능 완성도 현황 (업데이트: 2026-01-08)

| 기능 | 완성도 | 상태 | 완성된 기능 | 미완성 기능 |
|------|--------|------|------------|------------|
| 커뮤니티 | 95% | ✅ | CRUD, 이미지(5개), 댓글, 대댓글, 좋아요, 스크랩, Turbo Stream | 댓글 수정, 신고/차단 |
| 채팅 | 95% | ✅ | 1:1 채팅, 실시간(Solid Cable), 거래 카드, 읽음 표시 | 파일 첨부, 타이핑 표시 |
| 프로필/OAuth | 90% | ✅ | Google/GitHub OAuth, 아바타, Remember Me, 소셜 링크 | 포트폴리오 첨부, 팔로우 |
| AI 온보딩 | 95% | ✅ | 5개 에이전트, Gemini Grounding, 추가질문, 백그라운드 Job | 결과 공유, 분석 이력, PDF |
| 알림 시스템 | 85% | ✅ | 댓글/좋아요/메시지 알림, 읽음 처리, 드롭다운 | 실시간 WebSocket, 이메일/푸시 |
| 검색 | 90% | ✅ | 실시간 라이브 검색, 카테고리 필터, 페이지네이션 | 자동완성, 고급 필터 |
| 외주 | 75% | ⚠️ | Post 통합(hiring/seeking), Toss 결제, Order/Payment | 지원 버튼, 정산, 리뷰 |
| 회원 탈퇴 | 95% | ✅ | AES-256 암호화, 5년 보관, 자동 파기, 관리자 열람 로그 | 복구 옵션, 데이터 내보내기 |
| 이메일 인증 | 95% | ✅ | Resend HTTP API, 6자리 코드, 10분 만료, 에러 처리 | 재발송 횟수 제한 |

> **완성도 상세 근거**: [TASKS.md](TASKS.md#완성도-상세-근거) 참조

---

## 디렉토리 구조

```
Startup-Community-rails/
├── app/
│   ├── controllers/          # 36개 컨트롤러 (admin 8개 포함)
│   ├── models/               # 24개 모델 (concern 2개 포함)
│   ├── views/                # 20개 뷰 디렉토리
│   │   ├── layouts/          # 레이아웃
│   │   ├── shared/           # 공유 컴포넌트, 아이콘
│   │   ├── components/ui/    # shadcn UI 컴포넌트
│   │   ├── posts/            # 게시글
│   │   ├── chat_rooms/       # 채팅
│   │   ├── comments/         # 댓글
│   │   ├── profiles/         # 프로필
│   │   ├── search/           # 검색
│   │   ├── onboarding/       # AI 온보딩
│   │   └── ...
│   ├── javascript/
│   │   └── controllers/      # 60개 Stimulus 컨트롤러
│   ├── services/
│   │   ├── ai/               # AI 멀티에이전트 시스템
│   │   │   ├── agents/       # 5개 전문 에이전트
│   │   │   ├── orchestrators/# 에이전트 오케스트레이터
│   │   │   └── tools/        # LangchainRB 도구 (3개)
│   │   └── expert_matcher.rb # 전문가 매칭
│   └── helpers/              # 뷰 헬퍼
│
├── config/
│   ├── routes.rb             # 라우팅 정의
│   ├── credentials.yml.enc   # 암호화된 API 키
│   └── initializers/         # 12개 초기화 파일
│       ├── langchain.rb      # AI 설정
│       ├── omniauth.rb       # OAuth 설정
│       ├── resend.rb         # 🆕 이메일 서비스 (Resend HTTP API)
│       ├── sentry.rb         # 🆕 에러 트래킹
│       ├── kaminari_config.rb # 🆕 페이지네이션
│       └── rack_attack.rb    # Rate limiting
│
├── lib/
│   └── langchain_config.rb   # LangChain 설정
│
├── db/
│   ├── migrate/              # 30개 마이그레이션
│   └── schema.rb             # 현재 스키마
│
└── .claude/                  # Claude 프로젝트 문서
    ├── CLAUDE.md             # 메인 컨텍스트 ⭐
    ├── PROJECT_OVERVIEW.md   # 이 문서 ⭐
    ├── ARCHITECTURE_DETAIL.md # 상세 아키텍처 ⭐
    ├── DESIGN_SYSTEM.md      # 디자인 시스템 (색상, 컴포넌트)
    ├── PRD.md                # 제품 요구사항
    ├── DATABASE.md           # ERD, 스키마
    ├── API.md                # API 설계
    ├── TASKS.md              # 작업 목록
    ├── PERFORMANCE.md        # 성능 가이드
    ├── SECURITY_GUIDE.md     # 보안 및 암호화 가이드
    ├── standards/            # Agent OS 스타일 표준 규칙
    │   ├── rails-backend.md
    │   ├── tailwind-frontend.md
    │   └── testing.md
    ├── workflows/            # Design OS 스타일 워크플로우
    │   └── feature-development.md
    ├── rules/                # 🆕 Claude Code Rules (9개 파일)
    │   ├── backend/          # Rails 백엔드 규칙
    │   ├── frontend/         # 프론트엔드 규칙
    │   ├── testing/          # 테스트 규칙
    │   ├── infrastructure/   # 인프라 규칙
    │   └── common/           # 공통 품질 규칙
    └── skills/               # 17개 Claude Skills
```

---

## 핵심 파일 Quick Reference

### Controllers (36개, Admin 8개 포함)

| 파일 | 역할 |
|------|------|
| `application_controller.rb` | 인증, 헬퍼, 에러 핸들링 |
| `posts_controller.rb` | 게시글 CRUD, 이미지 |
| `comments_controller.rb` | 댓글 CRUD |
| `likes_controller.rb` | 좋아요 토글 |
| `bookmarks_controller.rb` | 스크랩 토글 |
| `chat_rooms_controller.rb` | 채팅방 관리 |
| `messages_controller.rb` | 메시지 전송 |
| `profiles_controller.rb` | 프로필 조회 |
| `search_controller.rb` | 검색 기능 |
| `onboarding_controller.rb` | AI 온보딩 |
| `sessions_controller.rb` | 로그인/로그아웃 |
| `users_controller.rb` | 회원가입 |
| `omniauth_callbacks_controller.rb` | OAuth 콜백 |
| `notifications_controller.rb` | 알림 관리 |
| `my_page_controller.rb` | 마이페이지 |
| `job_posts_controller.rb` | 구인 공고 |
| `email_verifications_controller.rb` | 🆕 이메일 인증 |
| `account_recovery_controller.rb` | 계정 복구 |
| `admin/*_controller.rb` | 관리자 패널 (8개) |

### Models (24개, Concern 2개 포함)

| 파일 | 역할 | 주요 관계 |
|------|------|----------|
| `user.rb` | 사용자 | has_many: posts, comments, likes, chat_rooms |
| `post.rb` | 게시글 | belongs_to: user, has_many: comments, likes |
| `comment.rb` | 댓글 | belongs_to: post, user |
| `like.rb` | 좋아요 | polymorphic (likeable) |
| `bookmark.rb` | 스크랩 | polymorphic (bookmarkable) |
| `chat_room.rb` | 채팅방 | has_many: messages, participants |
| `message.rb` | 메시지 | belongs_to: chat_room, sender |
| `notification.rb` | 알림 | polymorphic (notifiable) |
| `oauth_identity.rb` | OAuth | belongs_to: user |
| `email_verification.rb` | 🆕 이메일 인증 | 6자리 코드, 10분 만료 |
| `order.rb` | 주문 | belongs_to: buyer, seller |
| `payment.rb` | 결제 | belongs_to: order |
| `user_deletion.rb` | 탈퇴 기록 | AES-256 암호화 |
| `admin_view_log.rb` | 열람 로그 | 관리자 감사 |
| `idea_analysis.rb` | AI 분석 | JSON 저장 |
| `report.rb` | 신고 | polymorphic |
| `inquiry.rb` | 문의 | belongs_to: user |
| `follow.rb` | 팔로우 | self-join |

### Stimulus Controllers (60개) - 핵심

| 파일 | 기능 |
|------|------|
| `like_button_controller.js` | 좋아요 토글 |
| `bookmark_button_controller.js` | 스크랩 토글 |
| `live_search_controller.js` | 실시간 검색 |
| `comment_form_controller.js` | 댓글 입력 |
| `new_message_controller.js` | 메시지 전송 |
| `chat_room_controller.js` | 채팅방 UI |
| `image_upload_controller.js` | 이미지 업로드 |
| `post_form_controller.js` | 글쓰기 폼 |
| `write_bottomsheet_controller.js` | 글쓰기 바텀시트 |
| `share_controller.js` | 공유 기능 |

### AI/Services - 멀티에이전트 시스템

| 파일 | 역할 |
|------|------|
| `lib/langchain_config.rb` | LLM 설정, 에이전트별 모델 최적화 |
| `app/services/ai/base_agent.rb` | AI 에이전트 베이스 클래스 |
| `app/services/ai/follow_up_generator.rb` | 추가 질문 생성기 |
| `app/services/ai/expert_score_predictor.rb` | 전문가 점수 예측 |
| `app/services/ai/orchestrators/analysis_orchestrator.rb` | 멀티에이전트 오케스트레이터 |
| `app/services/ai/agents/summary_agent.rb` | 요약 에이전트 |
| `app/services/ai/agents/target_user_agent.rb` | 타겟 사용자 에이전트 |
| `app/services/ai/agents/market_analysis_agent.rb` | 시장 분석 에이전트 |
| `app/services/ai/agents/strategy_agent.rb` | 전략 에이전트 |
| `app/services/ai/agents/scoring_agent.rb` | 점수 에이전트 |
| `app/services/ai/tools/gemini_grounding_tool.rb` | Gemini 실시간 웹 검색 |
| `app/services/ai/tools/market_data_tool.rb` | 정적 시장 데이터 |
| `app/services/ai/tools/competitor_database_tool.rb` | 경쟁사 데이터베이스 |
| `app/services/expert_matcher.rb` | 전문가 매칭 |

### 회원 탈퇴 시스템

| 파일 | 역할 |
|------|------|
| `app/models/user_deletion.rb` | 탈퇴 기록 (암호화된 개인정보) |
| `app/models/admin_view_log.rb` | 관리자 열람 감사 로그 |
| `app/services/users/deletion_service.rb` | 탈퇴 처리 서비스 |
| `app/controllers/user_deletions_controller.rb` | 사용자 탈퇴 요청 처리 |
| `app/controllers/admin/user_deletions_controller.rb` | 관리자 탈퇴 기록 조회 |
| `app/jobs/destroy_expired_deletions_job.rb` | 5년 후 자동 파기 작업 |

---

## 기술 스택 요약

### Backend
- **Rails 8.1.1** + Ruby 3.4.7
- **SQLite3** (개발) / **PostgreSQL** (프로덕션)
- **Solid Queue** - 백그라운드 작업
- **Solid Cache** - 캐싱
- **Solid Cable** - WebSocket (실시간 채팅)

### Frontend
- **Hotwire** (Turbo + Stimulus)
- **Tailwind CSS v4** + **shadcn-ui**
- **Import Maps** (ES 모듈)
- **Active Storage** (이미지)

### AI
- **LangchainRB** - AI 에이전트 프레임워크
- **Google Gemini 3 Flash** - LLM (5개 전문 에이전트)
  - gemini-3-flash-preview, gemini-2.0-flash-lite
  - Gemini Grounding (실시간 웹 검색)

### Auth
- **Session 기반 인증** (has_secure_password)
- **OAuth** - Google, GitHub (OmniAuth)

### DevOps
- **Docker** + **Kamal** (배포)
- **Rack Attack** (보안)

---

## 라우팅 구조 요약

### 인증
```
POST   /login              → sessions#create
DELETE /logout             → sessions#destroy
GET    /signup             → users#new
POST   /signup             → users#create
GET    /auth/:provider/callback → OAuth 콜백
```

### 커뮤니티
```
GET    /community          → posts#index (메인)
GET    /posts/:id          → posts#show
POST   /posts              → posts#create
POST   /posts/:id/like     → likes#toggle
POST   /posts/:id/bookmark → bookmarks#toggle
```

### 채팅
```
GET    /chat_rooms         → chat_rooms#index
GET    /chat_rooms/:id     → chat_rooms#show
POST   /chat_rooms/:id/messages → messages#create
```

### AI 온보딩
```
GET    /                   → onboarding#landing (루트)
GET    /ai/input           → onboarding#ai_input (로그인 필수)
POST   /ai/questions       → onboarding#ai_questions (추가 질문 생성)
GET    /ai/result          → onboarding#ai_result (5개 에이전트 분석)
GET    /ai/expert/:id      → onboarding#expert_profile (Turbo Stream)
```

### 회원 탈퇴
```
GET    /settings           → settings#show (탈퇴 버튼)
GET    /withdrawal/new     → user_deletions#new
POST   /withdrawal         → user_deletions#create
```

### 기타
```
GET    /search             → search#index
GET    /profiles/:id       → profiles#show
GET    /my_page            → my_page#show
GET    /notifications      → notifications#index
```

---

## 최근 해결된 이슈

| 날짜 | 이슈 | 해결 방법 |
|------|------|----------|
| 2026-01-07 | 프로덕션 이메일 발송 실패 | Resend 전용 initializer 추가 |
| 2026-01-07 | 이메일 인증 에러 처리 부재 | rescue 블록 + Sentry 연동 |
| 2026-01-06 | 채팅 시스템 버그 | 읽음 표시 및 최적화 수정 |
| 2026-01-06 | GA4 프로덕션 로드 실패 | 환경별 조건부 로딩 적용 |
| 2025-12-26 | 검색 페이지 UTF-8 인코딩 오류 | `og_meta_tags`에서 `force_encoding("UTF-8")` 적용 |
| 2025-12-26 | 검색 결과 클릭 시 두 번 클릭 | `onclick` → `onmousedown` + `preventDefault()` |
| 2025-12-26 | render_avatar 메서드명 충돌 | `render_user_avatar()`로 이름 변경 |

---

## 현재 진행 중인 작업

1. ~~**AI 아이디어 분석 기능 안정화**~~ ✅ 완료
2. ~~**프로덕션 배포**~~ ✅ 완료 (https://undrewai.com)
3. ~~**이메일 인증 시스템**~~ ✅ 완료 (Resend HTTP API)
4. **외주 시스템 완성** (지원 버튼, 정산, 리뷰)
5. **N+1 쿼리 최적화**

---

## 관련 문서

### 핵심 문서
- **상세 아키텍처**: `.claude/ARCHITECTURE_DETAIL.md`
- **디자인 시스템**: `.claude/DESIGN_SYSTEM.md`
- **데이터베이스 설계**: `.claude/DATABASE.md`
- **API 설계**: `.claude/API.md`

### 표준 규칙 (Agent OS 스타일)
- **Rails 백엔드**: `.claude/standards/rails-backend.md`
- **Tailwind 프론트엔드**: `.claude/standards/tailwind-frontend.md`
- **테스트 표준**: `.claude/standards/testing.md`

### 워크플로우 (Design OS 스타일)
- **기능 개발**: `.claude/workflows/feature-development.md`

### 기타
- **작업 목록**: `.claude/TASKS.md`
- **제품 요구사항**: `.claude/PRD.md`
- **보안 및 암호화 가이드**: `.claude/SECURITY_GUIDE.md`
- **성능 최적화**: `.claude/PERFORMANCE.md`
