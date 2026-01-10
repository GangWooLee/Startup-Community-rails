# Project Tasks & Progress

## 문서 정보
- **프로젝트**: Startup Community Platform
- **업데이트**: 2026-01-08

---

## 작업 상태 범례

```
✅ Done        - 완료됨
🔄 In Progress - 진행 중
📋 Todo        - 계획됨
⏸️ On Hold     - 보류
```

---

## MVP Phase 1: 커뮤니티 + 프로필 + 외주 기본 흐름 ✅ 완료

### Week 1-2: 프로젝트 셋업 & 인증 & 커뮤니티

#### 프로젝트 초기화 ✅
- [x] ✅ Rails 8.1.1 프로젝트 생성
- [x] ✅ Git 저장소 초기화
- [x] ✅ .claude/ 디렉토리 문서 작성
- [x] ✅ Gemfile 정리 (pagy, langchainrb, omniauth 등)
- [x] ✅ Tailwind CSS v4 적용

#### 인증 시스템 ✅
- [x] ✅ User 모델 생성 (email, password_digest, name, bio 등)
- [x] ✅ has_secure_password 기반 인증
- [x] ✅ SessionsController (로그인/로그아웃)
- [x] ✅ UsersController (회원가입)
- [x] ✅ OAuth 소셜 로그인 (Google, GitHub)
- [x] ✅ OmniAuth Callbacks Controller
- [x] ✅ oauth_identities 테이블 (동일 이메일 계정 통합)
- [x] ✅ Remember Me (로그인 상태 유지) - BCrypt 기반 영구 쿠키

#### 커뮤니티 게시판 ✅
- [x] ✅ Post 모델 (category enum: free/question/promo/hiring/seeking)
- [x] ✅ Comment 모델 (counter_cache)
- [x] ✅ Like 모델 (polymorphic)
- [x] ✅ Bookmark 모델 (polymorphic)
- [x] ✅ PostsController CRUD
- [x] ✅ CommentsController (Turbo Stream)
- [x] ✅ LikesController (Turbo Stream)
- [x] ✅ BookmarksController (Turbo Stream)
- [x] ✅ Active Storage 이미지 업로드
- [x] ✅ Stimulus 컨트롤러 (like_button, bookmark_button, image_upload)

### Week 3-4: 프로필 & 채팅 & 검색

#### 프로필 페이지 ✅
- [x] ✅ ProfilesController (3개 탭: 소개/커뮤니티 글/외주 공고)
- [x] ✅ 프로필 이미지 업로드 (Active Storage)
- [x] ✅ 활동 상태 다중 선택 (외주 가능, 팀 구하는 중 등)
- [x] ✅ 연락처 링크 (open_chat_url, github_url, portfolio_url)
- [x] ✅ MyPageController (프로필 수정)

#### 실시간 채팅 ✅
- [x] ✅ ChatRoom 모델
- [x] ✅ Message 모델
- [x] ✅ ChatRoomsController
- [x] ✅ MessagesController
- [x] ✅ Solid Cable WebSocket 설정
- [x] ✅ Turbo Streams 실시간 메시지
- [x] ✅ 읽음 표시 (read_at)
- [x] ✅ Stimulus 컨트롤러 (new_message, chat_room, chat_list)

#### 알림 시스템 ✅
- [x] ✅ Notification 모델 (polymorphic)
- [x] ✅ NotificationsController
- [x] ✅ 댓글, 좋아요, 채팅 알림
- [x] ✅ 읽지 않은 알림 카운트

#### 검색 기능 ✅
- [x] ✅ SearchController
- [x] ✅ 실시간 검색 (Stimulus live_search)
- [x] ✅ 탭 필터링 (게시글/사용자/외주)
- [x] ✅ UTF-8 인코딩 처리 (og_meta_tags)

---

## MVP Phase 2: AI & 보안 강화 ✅ 완료

### AI 멀티에이전트 시스템 (2025-12-25 ~ 12-27) ✅
- [x] ✅ LangchainRB 프레임워크 통합
- [x] ✅ Google Gemini 3 Flash API 연동
- [x] ✅ BaseAgent 클래스 (app/services/ai/base_agent.rb)
- [x] ✅ AnalysisOrchestrator (멀티에이전트 오케스트레이션)
- [x] ✅ 5개 전문 에이전트:
  - SummaryAgent (아이디어 요약)
  - TargetUserAgent (타겟 사용자 분석)
  - MarketAnalysisAgent (시장 분석)
  - StrategyAgent (전략 제안)
  - ScoringAgent (점수 평가)
- [x] ✅ 3개 도구:
  - GeminiGroundingTool (실시간 웹 검색)
  - MarketDataTool (정적 시장 데이터)
  - CompetitorDatabaseTool (경쟁사 데이터)
- [x] ✅ FollowUpGenerator (추가 질문 생성)
- [x] ✅ ExpertScorePredictor (전문가 점수 예측)
- [x] ✅ ExpertMatcher (전문가 매칭)
- [x] ✅ OnboardingController (AI 온보딩 플로우)
- [x] ✅ IdeaAnalysis 모델 (분석 결과 저장)

### 회원 탈퇴 시스템 (2025-12-30) ✅
- [x] ✅ UserDeletion 모델 (탈퇴 기록)
- [x] ✅ Users::DeletionService (탈퇴 처리)
- [x] ✅ 즉시 익명화 (이름, 이메일 → "탈퇴한 사용자")
- [x] ✅ AES-256-GCM 암호화 (원본 정보 보관)
- [x] ✅ UserDeletionsController (사용자 탈퇴 요청)
- [x] ✅ Admin::UserDeletionsController (관리자 조회)
- [x] ✅ AdminViewLog (열람 감사 로그)
- [x] ✅ DestroyExpiredDeletionsJob (5년 후 자동 파기)

### 문서화 개선 (2025-12-31) ✅
- [x] ✅ Agent OS/Design OS 기반 .claude 폴더 구조 개선
- [x] ✅ DESIGN_SYSTEM.md 생성 (색상, 컴포넌트, UI 패턴)
- [x] ✅ SECURITY_GUIDE.md 생성 (암호화 가이드)
- [x] ✅ standards/ 폴더 추가:
  - rails-backend.md
  - tailwind-frontend.md
  - testing.md
- [x] ✅ workflows/ 폴더 추가:
  - feature-development.md
- [x] ✅ 14개 Claude Skills 작성

### 기타 완료된 작업 ✅
- [x] ✅ Admin 패널 (사용자/채팅방 관리)
- [x] ✅ GA4 (Google Analytics 4) 연동
- [x] ✅ Undrew 브랜딩 적용 (로고, 헤더)
- [x] ✅ .env → Rails credentials 전환
- [x] ✅ Seed 데이터 (테스트 계정 10개)

---

## 현재 진행 중인 작업 🔄

### 이메일 인증 시스템 ✅ 완료 (2026-01-07)
- [x] ✅ EmailVerification 모델 생성
- [x] ✅ Resend HTTP API 연동
- [x] ✅ 6자리 인증 코드, 10분 만료
- [x] ✅ 에러 처리 및 Sentry 연동
- [x] ✅ Stimulus 컨트롤러 (email_verification)

### 프로덕션 배포 ✅ 완료 (2026-01-06)
- [x] ✅ Kamal 배포 설정
- [x] ✅ 도메인 연결 (undrewai.com)
- [x] ✅ SSL 인증서
- [x] ✅ 환경변수 설정 (production)
- [x] ✅ Sentry 에러 트래킹

### 외주 시스템 Post 모델 통합 (75%)
- [x] ✅ Post 모델에 hiring/seeking 카테고리 추가
- [x] ✅ job_posts/index에서 Post 모델 사용
- [ ] 📋 지원/문의 기능
- [ ] 📋 외주 글 필터링 UI 개선
- [ ] 📋 정산 시스템

### N+1 쿼리 최적화
- [ ] 📋 Bullet gem 적용
- [ ] 📋 posts#index includes 최적화
- [ ] 📋 chat_rooms#index includes 최적화
- [ ] 📋 검색 쿼리 최적화

---

## 🔧 배포 후 개선사항 (2026-01-10 안정성 점검 결과)

> **배경**: 프로젝트 안정성 점검 결과 즉시 조치 불필요하나, 기술 부채 해소를 위해 권장되는 개선사항입니다.
> **현재 상태**: ✅ 프로덕션 운영 가능 (1,302개 테스트 통과, 보안 취약점 없음)

### Phase 1: 코드 품질 개선 (우선순위: 높음)

#### 1.1 User 모델 Concern 분리 (God Object 해결)
- **현재 문제**: `app/models/user.rb` 670줄 - 너무 많은 책임
- **목표**: 200줄 이하로 분리
- **작업 내용**:
  - [ ] 📋 `Authenticatable` Concern 완성 (인증 로직 120줄)
  - [ ] 📋 `Deletable` Concern 완성 (삭제/복구 50줄)
  - [ ] 📋 `Oauthable` Concern 생성 (OAuth 연동 40줄)
  - [ ] 📋 `Notifiable` Concern 생성 (알림 처리 60줄)
  - [ ] 📋 `Chattable` Concern 생성 (채팅 관련 40줄)
- **이미 시작됨** (미커밋 상태):
  ```
  app/models/concerns/authenticatable.rb
  app/models/concerns/deletable.rb
  ```
- **예상 효과**: 유지보수성 향상, 테스트 용이성 증가

#### 1.2 Message 콜백 체인 정리 (Service Object 추출)
- **현재 문제**: `app/models/message.rb`에 5개 after_create 콜백
  ```ruby
  after_create :increment_unread_count
  after_create :broadcast_message
  after_create :update_chat_room_timestamp
  after_create :send_notification
  after_create :process_image_variant
  ```
- **위험**: 순서 의존성, 부분 실패 시 복구 어려움
- **작업 내용**:
  - [ ] 📋 `MessageCreationService` 생성
  - [ ] 📋 콜백 로직을 Service로 이동
  - [ ] 📋 트랜잭션 처리 개선
  - [ ] 📋 에러 처리 로직 추가
- **예상 효과**: 안정성 향상, 디버깅 용이

### Phase 2: 프론트엔드 개선 (우선순위: 중간)

#### 2.1 ai_input_controller.js 분리
- **현재 문제**: `app/javascript/controllers/ai_input_controller.js` 581줄
- **권장 최대**: 300줄
- **작업 내용**:
  - [ ] 📋 `ai_form_controller.js` 생성 (폼 처리)
  - [ ] 📋 `ai_validation_controller.js` 생성 (유효성 검사)
  - [ ] 📋 `ai_response_controller.js` 생성 (응답 처리)
- **예상 효과**: 개발 생산성 향상, 코드 재사용성 증가

### Phase 3: 테스트 커버리지 개선 (우선순위: 낮음)

#### 3.1 미테스트 컨트롤러 추가
- **현재 상태**: 21/37 컨트롤러 테스트됨 (57%)
- **미테스트 컨트롤러** (16개):
  ```
  SearchController
  OnboardingController
  IdeasController
  Admin::BaseController
  Admin::UsersController
  Admin::PostsController
  Admin::ChatRoomsController
  OauthCallbacksController
  ...
  ```
- **작업 내용**:
  - [ ] 📋 SearchController 테스트 추가 (우선)
  - [ ] 📋 OnboardingController 테스트 추가 (우선)
  - [ ] 📋 Admin 컨트롤러 테스트 추가 (선택)
- **참고**: 핵심 비즈니스 로직은 이미 100% 테스트됨

#### 3.2 SimpleCov 설정 개선
- **현재 문제**: 커버리지 2.0% (설정 이슈로 낮게 측정됨)
- **작업 내용**:
  - [ ] 📋 `test/test_helper.rb` SimpleCov 설정 수정
  - [ ] 📋 그룹별 커버리지 설정 (Models, Controllers, Services)
  - [ ] 📋 minimum_coverage 20% 설정

### Phase 4: 인프라 정리 (우선순위: 낮음)

#### 4.1 .gitignore 정리
- [x] ✅ `.mcp.json` 추가 완료 (2026-01-10)

#### 4.2 미커밋 파일 정리
- [ ] 📋 `authenticatable.rb`, `deletable.rb` 커밋
- [ ] 📋 `app/services/payments/` 정리 또는 커밋
- [ ] 📋 `e2e/` 디렉토리 정리

---

### 개선사항 우선순위 요약

| 순위 | 작업 | 영향도 | 예상 시간 | 긴급성 |
|------|------|--------|----------|--------|
| 1 | User 모델 Concern 분리 | 높음 | 4-6시간 | 낮음 |
| 2 | Message 콜백 → Service | 높음 | 2-3시간 | 낮음 |
| 3 | ai_input_controller 분리 | 중간 | 2-3시간 | 낮음 |
| 4 | 미테스트 컨트롤러 추가 | 낮음 | 4-6시간 | 낮음 |
| 5 | SimpleCov 설정 개선 | 낮음 | 30분 | 낮음 |

### 참고 문서
- 안정성 점검 상세 결과: `.claude/plans/robust-wishing-thimble.md`
- 코드 품질 규칙: `.claude/rules/common/code-quality.md`
- 모델 패턴 가이드: `.claude/rules/backend/model-patterns.md`

---

## 향후 계획 📋

### 프로덕션 배포 ✅ 완료
- [x] ✅ Kamal 배포 설정
- [x] ✅ 환경변수 설정 (production)
- [x] ✅ 도메인 연결 (undrewai.com)
- [x] ✅ SSL 인증서
- [x] ✅ Sentry 에러 트래킹

### Phase 3: 기능 확장
- [ ] ⏸️ 실시간 알림 (WebSocket)
- [ ] ⏸️ 이메일 알림 (Action Mailer)
- [ ] ⏸️ 다크모드
- [ ] ⏸️ PWA 지원
- [ ] ⏸️ 무한 스크롤
- [ ] ⏸️ 이미지 최적화 (variant)
- [ ] ⏸️ 평판 시스템 (리뷰, 평점)
- [ ] ⏸️ 포트폴리오 첨부

### 인프라 & DevOps
- [ ] ⏸️ CI/CD 파이프라인 (GitHub Actions)
- [x] ✅ 모니터링 (Sentry) - 완료
- [ ] ⏸️ CDN 설정 (CloudFlare)
- [ ] ⏸️ 백업 자동화

---

## 최근 작업 로그

### 2026-01-10
- ✅ 프로젝트 안정성 점검 및 코드 리뷰 완료
- ✅ 테스트 전체 실행 확인 (1,302개 통과, 0 실패)
- ✅ 보안 취약점 검사 완료 (SQL Injection/XSS 없음)
- ✅ 코드 품질 분석 및 개선사항 문서화
- ✅ 배포 후 개선사항 TASKS.md에 기록
- ✅ .gitignore에 .mcp.json 추가
- ✅ 채팅 이미지 표시 버그 수정 (libvips 설치, url_for 제거)

### 2026-01-08
- ✅ Claude Code rules 대폭 확장 (53줄 → 1,152줄)
- ✅ .claude/ 문서 최신성 업데이트

### 2026-01-07
- ✅ Resend HTTP API 이메일 서비스 연동 (프로덕션)
- ✅ 이메일 인증 에러 처리 및 Sentry 연동
- ✅ Resend 전용 initializer 추가

### 2026-01-06
- ✅ 채팅 시스템 최적화 및 버그 수정
- ✅ GA4 맞춤 이벤트 12개 구현
- ✅ Plan Mode 규칙 추가 (TDD, Quality Gate)
- ✅ Kaminari pagination initializer 추가

### 2025-12-31
- ✅ Agent OS/Design OS 기반 .claude 폴더 구조 개선
- ✅ Remember Me (로그인 상태 유지) 기능 구현
- ✅ Gemini 3 Flash 모델 업그레이드

### 2025-12-30
- ✅ 회원 탈퇴 시스템 완성 (즉시 익명화, 암호화 보관)
- ✅ 관리자 회원관리 개선 (탈퇴 회원 필터, 열람 로그)
- ✅ GA4 연동

### 2025-12-27
- ✅ AI 멀티에이전트 시스템 완성 (5개 전문 에이전트)
- ✅ Gemini Grounding 실시간 웹 검색 연동
- ✅ Admin 패널 추가

### 2025-12-26
- ✅ 검색 페이지 UTF-8 인코딩 오류 수정
- ✅ 검색 결과 클릭 문제 해결 (onmousedown)
- ✅ render_avatar 메서드명 충돌 해결
- ✅ .env → Rails credentials 전환

### 2025-12-25
- ✅ AI 아이디어 분석 Gemini API 연동

### 2025-12-24
- ✅ 채팅 기능 완성 (실시간 메시지, 읽음 표시)

### 2025-12-23
- ✅ OAuth 소셜 로그인 추가 (Google, GitHub)

---

## 주요 결정사항

| 날짜 | 결정 | 이유 |
|------|------|------|
| 2025-12-31 | Agent OS/Design OS 폴더 구조 | 문서 유지보수 용이성 |
| 2025-12-30 | AES-256-GCM 암호화 | 5년 보관 법적 요구사항 |
| 2025-12-27 | 멀티에이전트 시스템 | 복잡한 분석을 병렬 처리 |
| 2025-12-26 | onmousedown 사용 | blur 이벤트 충돌 해결 |
| 2025-12-26 | render_user_avatar | shadcn 메서드 충돌 회피 |
| 2025-12-25 | Gemini 3 Flash | 최신 모델, 더 나은 분석 |
| 2025-12-24 | Solid Cable | Redis 불필요, Rails 8 내장 |

---

## 기술 스택 현황

| 카테고리 | 기술 | 버전 |
|---------|------|------|
| Framework | Rails | 8.1.1 |
| Language | Ruby | 3.4.7 |
| Database | SQLite3 (dev) | - |
| Frontend | Hotwire (Turbo + Stimulus) | Rails 8 내장 |
| Styling | Tailwind CSS | v4 |
| AI | LangchainRB + Gemini 3 Flash | - |
| WebSocket | Solid Cable | Rails 8 내장 |
| Background Jobs | Solid Queue | Rails 8 내장 |
| Auth | has_secure_password + OmniAuth | - |

---

## 기능 완성도 현황 (업데이트: 2026-01-08)

| 기능 | 완성도 | 상태 | 완성된 기능 | 미완성 기능 |
|------|--------|------|------------|------------|
| 커뮤니티 | 95% | ✅ | Post CRUD, 이미지(5개/5MB), 댓글, 대댓글, 좋아요, 스크랩, Turbo Stream | 댓글 수정, 신고/차단 |
| 채팅 | 95% | ✅ | 1:1 채팅, 실시간(Solid Cable), 프로필/연락처/거래 카드, 읽음 표시 | 파일 첨부, 타이핑 표시 |
| 프로필/OAuth | 90% | ✅ | Google/GitHub OAuth, 프로필 편집, 아바타, Remember Me | 포트폴리오 첨부, 팔로우 |
| AI 온보딩 | 95% | ✅ | 5개 에이전트, Gemini Grounding, 추가질문, 전문가 매칭, 백그라운드 Job | 결과 공유, 분석 이력, PDF |
| 알림 시스템 | 85% | ✅ | 댓글/좋아요/메시지 알림, 읽음 처리, 드롭다운 | 실시간 WebSocket, 이메일/푸시 |
| 검색 | 90% | ✅ | 실시간 라이브 검색, 사용자/게시글, 카테고리 필터, 페이지네이션 | 자동완성, 고급 필터 |
| 외주 | 75% | ⚠️ | Post 통합(hiring/seeking), Toss 결제, Order/Payment, 채팅 거래 | 지원 버튼, 정산, 리뷰 |
| 회원 탈퇴 | 95% | ✅ | 즉시 익명화, AES-256 암호화, 5년 보관, 자동 파기, 관리자 열람 로그 | 복구 옵션, 데이터 내보내기 |
| 이메일 인증 | 95% | ✅ | Resend HTTP API, 6자리 코드, 10분 만료, 에러 처리, Sentry 연동 | 재발송 횟수 제한 |

### 완성도 산정 기준

- **95-100%**: 핵심 기능 완료 + 대부분의 부가 기능 완료
- **85-94%**: 핵심 기능 완료 + 일부 부가 기능 완료
- **70-84%**: 핵심 기능 대부분 완료
- **50-69%**: 핵심 기능 일부만 완료
- **<50%**: 초기 개발 단계

---

## 완성도 상세 근거

### 커뮤니티 (95%)

**완성된 기능**:
- [x] Post CRUD (create, read, update, delete)
- [x] 이미지 업로드 (Active Storage, 최대 5개, 5MB)
- [x] 댓글 시스템 (create, delete, counter_cache)
- [x] 대댓글 (parent_id 기반, 깊이 1)
- [x] 좋아요 (polymorphic, Post + Comment)
- [x] 스크랩 (polymorphic, Bookmark 모델)
- [x] Turbo Stream 실시간 UI

**미완성 기능** (5%):
- [ ] 댓글 수정 기능
- [ ] 게시글 신고/차단
- [ ] 수정 이력 추적

---

### 채팅 (95%)

**완성된 기능**:
- [x] 1:1 채팅방 (find_or_create_between)
- [x] Solid Cable 실시간 메시지
- [x] 메시지 타입 (text, profile_card, contact_card, offer_card)
- [x] 읽음 표시 (unread_count, read_at)
- [x] 거래 확정/취소 (채팅 내 Order 생성)
- [x] 사용자 검색 (채팅 시작)
- [x] 채팅방 숨기기/복구

**미완성 기능** (5%):
- [ ] 파일/이미지 첨부
- [ ] 타이핑 표시
- [ ] 메시지 수정/삭제

---

### 프로필/OAuth (90%)

**완성된 기능**:
- [x] Google OAuth2 로그인
- [x] GitHub OAuth 로그인
- [x] 프로필 편집 (name, bio, role_title, affiliation, skills)
- [x] 아바타 업로드 (Active Storage)
- [x] Remember Me (영구 쿠키, BCrypt)
- [x] 활동 상태 다중 선택
- [x] 소셜 링크 (LinkedIn, GitHub, Portfolio, OpenChat)

**미완성 기능** (10%):
- [ ] 포트폴리오 파일 첨부
- [ ] 팔로우 기능
- [ ] 프로필 공개/비공개 설정

---

### AI 온보딩 (95%)

**완성된 기능**:
- [x] 5개 전문 에이전트 (Summary, TargetUser, MarketAnalysis, Strategy, Scoring)
- [x] AnalysisOrchestrator (병렬 실행)
- [x] Gemini Grounding 실시간 웹 검색
- [x] 추가 질문 생성 (FollowUpGenerator)
- [x] 전문가 점수 예측 (ExpertScorePredictor)
- [x] IdeaAnalysis 모델 (JSON 저장)
- [x] AiAnalysisJob (Solid Queue 백그라운드)
- [x] 진행률 브로드캐스트 (5단계)
- [x] 사용 횟수 제한 (5회)

**미완성 기능** (5%):
- [ ] 결과 URL 공유
- [ ] 분석 이력 조회
- [ ] PDF/Excel 내보내기

---

### 알림 시스템 (85%)

**완성된 기능**:
- [x] Notification 모델 (polymorphic)
- [x] 댓글 알림 (댓글, 대댓글)
- [x] 좋아요 알림
- [x] 메시지 알림
- [x] 읽음/안읽음 처리
- [x] 드롭다운 헤더 알림
- [x] unread 카운트

**미완성 기능** (15%):
- [ ] 실시간 WebSocket 알림
- [ ] 이메일 알림 (Action Mailer)
- [ ] 푸시 알림
- [ ] 알림 설정 (수신 거부)

---

### 검색 (90%)

**완성된 기능**:
- [x] 실시간 라이브 검색 (150ms debounce)
- [x] 게시글 검색 (title, content)
- [x] 사용자 검색 (name, role_title, bio)
- [x] 카테고리 필터 (all, community, hiring, seeking)
- [x] 탭 시스템 (all, users, posts)
- [x] 페이지네이션
- [x] 최근 검색어 (쿠키, 최대 10개)
- [x] SQL Injection 방지 (sanitize_like)

**미완성 기능** (10%):
- [ ] 검색어 자동완성
- [ ] 고급 필터 (날짜, 가격)
- [ ] 검색 결과 하이라이트

---

### 외주 (75%)

**완성된 기능**:
- [x] Post 모델 통합 (hiring, seeking 카테고리)
- [x] 외주 전용 필드 (service_type, price, work_type, portfolio_url, skills)
- [x] Order 모델 (주문 생성, 상태 관리)
- [x] Payment 모델 (Toss Payments 연동)
- [x] 채팅 기반 거래 (offer_card → Order)
- [x] 플랫폼 수수료 계산 (10%)
- [x] 거래 확정/취소

**미완성 기능** (25%):
- [ ] 지원 버튼 (구직 글에 지원하기)
- [ ] 지원자 목록 (구인자 전용)
- [ ] 실제 정산 로직 (송금)
- [ ] 리뷰/평점 시스템
- [ ] 분쟁 해결 프로세스

---

### 회원 탈퇴 (95%)

**완성된 기능**:
- [x] Users::DeletionService (즉시 익명화)
- [x] UserDeletion 모델 (암호화 보관)
- [x] AES-256-GCM 암호화 (Rails 7 encrypts)
- [x] 5년 보관 + 자동 파기
- [x] DestroyExpiredDeletionsJob (Solid Queue)
- [x] AdminViewLog (관리자 열람 감사)
- [x] 재가입 방지 (email_hash)

**미완성 기능** (5%):
- [ ] 탈퇴 복구 옵션 (유예 기간)
- [ ] 데이터 내보내기 (GDPR)

---

## 관련 문서

- **메인 컨텍스트**: `.claude/CLAUDE.md`
- **프로젝트 개요**: `.claude/PROJECT_OVERVIEW.md`
- **상세 아키텍처**: `.claude/ARCHITECTURE_DETAIL.md`
- **디자인 시스템**: `.claude/DESIGN_SYSTEM.md`
- **데이터베이스**: `.claude/DATABASE.md`
- **API 설계**: `.claude/API.md`
- **보안 가이드**: `.claude/SECURITY_GUIDE.md`
- **성능 최적화**: `.claude/PERFORMANCE.md`
