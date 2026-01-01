# Project Tasks & Progress

## 문서 정보
- **프로젝트**: Startup Community Platform
- **업데이트**: 2025-12-31

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

### 외주 시스템 Post 모델 통합 (50% → 80%)
- [x] ✅ Post 모델에 hiring/seeking 카테고리 추가
- [ ] 🔄 job_posts/index에서 Post 모델 사용
- [ ] 📋 구인/구직 전용 필드 추가 (budget, duration, skills_required)
- [ ] 📋 지원/문의 기능
- [ ] 📋 외주 글 필터링 UI 개선

### N+1 쿼리 최적화
- [ ] 📋 Bullet gem 적용
- [ ] 📋 posts#index includes 최적화
- [ ] 📋 chat_rooms#index includes 최적화
- [ ] 📋 검색 쿼리 최적화

---

## 향후 계획 📋

### 프로덕션 배포 준비
- [ ] 📋 SQLite → PostgreSQL 전환
- [ ] 📋 환경변수 설정 (production)
- [ ] 📋 Kamal 배포 설정
- [ ] 📋 도메인 연결
- [ ] 📋 SSL 인증서

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
- [ ] ⏸️ 모니터링 (Sentry, New Relic)
- [ ] ⏸️ CDN 설정 (CloudFlare)
- [ ] ⏸️ 백업 자동화

---

## 최근 작업 로그

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

## 관련 문서

- **메인 컨텍스트**: `.claude/CLAUDE.md`
- **프로젝트 개요**: `.claude/PROJECT_OVERVIEW.md`
- **상세 아키텍처**: `.claude/ARCHITECTURE_DETAIL.md`
- **디자인 시스템**: `.claude/DESIGN_SYSTEM.md`
- **데이터베이스**: `.claude/DATABASE.md`
- **API 설계**: `.claude/API.md`
- **보안 가이드**: `.claude/SECURITY_GUIDE.md`
- **성능 최적화**: `.claude/PERFORMANCE.md`
