# Startup Community Platform - Claude Context

> **새 세션 시작 시 먼저 읽어야 할 문서:**
> - 📋 **PROJECT_OVERVIEW.md** - 프로젝트 전체 구조 (필수)
> - 🏗️ **ARCHITECTURE_DETAIL.md** - 상세 아키텍처 및 코딩 패턴
> - 🎨 **DESIGN_SYSTEM.md** - 디자인 토큰, 컴포넌트, UI 패턴
>
> **도메인 전문가 (특정 도메인 작업 시):**
> - 🤖 `agents/README.md` - 11개 에이전트 가이드
> - 💬 `agents/domain/chat-expert.md` - 채팅 시스템
> - 👥 `agents/domain/community-expert.md` - 커뮤니티 (게시글/댓글)
> - 🧠 `agents/domain/ai-analysis-expert.md` - AI 분석 시스템
>
> **표준 규칙 (상세 개발 시 참조):**
> - 📘 `standards/rails-backend.md` - Rails 백엔드 규칙
> - 🎨 `standards/tailwind-frontend.md` - Tailwind/Stimulus 규칙
> - 🧪 `standards/testing.md` - 테스트 표준
>
> **워크플로우:**
> - 🔄 `workflows/feature-development.md` - 기능 개발 프로세스

## Quick Status
| 항목 | 상태 |
|------|------|
| **현재 버전** | MVP v0.9.0 |
| **마지막 업데이트** | 2026-01-25 |
| **진행 중 작업** | 문서 최신화, 안정성 개선 |
| **Rails** | 8.1.1 |
| **Ruby** | 3.4.7 |
| **프로덕션 URL** | https://undrewai.com |

## 핵심 기능 완성도 (업데이트: 2026-01-08)

| 기능 | 완성도 | 상태 | 완성된 기능 | 미완성 기능 |
|------|--------|------|------------|------------|
| 커뮤니티 | 95% | ✅ | CRUD, 이미지, 댓글, 대댓글, 좋아요, 스크랩 | 댓글 수정, 신고 |
| 채팅 | 95% | ✅ | 실시간(Solid Cable), 거래 카드, 읽음 표시 | 파일 첨부 |
| 프로필/OAuth | 90% | ✅ | Google/GitHub, 아바타, Remember Me | 팔로우 |
| AI 온보딩 | 95% | ✅ | 5개 에이전트, Gemini Grounding, 백그라운드 Job | 결과 공유, PDF |
| 알림 | 85% | ✅ | 댓글/좋아요/메시지, 읽음 처리 | 실시간 WebSocket, 이메일 |
| 검색 | 90% | ✅ | 라이브 검색, 카테고리 필터, 페이지네이션 | 자동완성 |
| 외주 | 75% | ⚠️ | Post 통합, Toss 결제, Order/Payment | 지원 버튼, 정산, 리뷰 |
| 회원 탈퇴 | 95% | ✅ | AES-256 암호화, 5년 보관, 자동 파기 | 복구 옵션 |
| 이메일 인증 | 95% | ✅ | Resend HTTP API, 6자리 코드, 10분 만료 | 재발송 제한 |

> **완성도 상세 근거**: [TASKS.md](TASKS.md#완성도-상세-근거) 참조

## ⚠️ 프로젝트 특화 규칙 (중요!)

### 필수 패턴
```ruby
# 아바타 렌더링 - render_avatar(user) 사용 금지!
render_user_avatar(user, size: "md")  # ✅ 올바른 방법

# OG 메타태그 - UTF-8 인코딩 처리됨
og_meta_tags(title: "제목", description: "설명")

# 검색 결과 클릭 - onclick 사용 금지!
onmousedown="event.preventDefault(); window.location.href = '...'"  # ✅
```

### 금지 패턴
| 패턴 | 문제 | 대안 |
|------|------|------|
| `render_avatar(user)` | shadcn 메서드 충돌 | `render_user_avatar()` |
| `request.original_url` 직접 사용 | 한글 인코딩 오류 | `og_meta_tags()` 헬퍼 사용 |
| `onclick` 검색 결과 | blur 시 재검색 | `onmousedown` 사용 |
| `faraday_ssl.rb` 파일 삭제 | Mac에서 SSL 에러 | **절대 삭제 금지!** (Mac 필수) |
| 레이아웃에서 인라인 CSS 삭제 | CSS Variables/애니메이션 깨짐 | **삭제 금지!** (빌드 CSS에 미포함) |
| `mx-auto` (고정 너비 없이) | 중앙 정렬 안 됨 | `flex justify-center` 또는 고정 너비 추가 |
| 중복 HTML ID (Turbo Stream 타겟) | 잘못된 컨테이너에 렌더링 | 전역 컨테이너 하나만 사용 |
| `document.querySelector(...).property` | null 시 TypeError | optional chaining `?.` 또는 Stimulus value 사용 |

### 🔐 비로그인 사용자 세션 관리 (2026-01-17)

**문제 배경**:
- 비로그인 사용자가 `browse=true`로 커뮤니티 진입 후
- 사이드바 링크(홍보, 자유게시판 등) 클릭 시 온보딩으로 리다이렉트되는 버그 발생
- 원인: URL 파라미터는 페이지 이동 시 유지되지 않음

**해결 패턴**:
```ruby
# PostsController#index
session[:browsing_community] = true if params[:browse] == "true"

# PostsController#redirect_to_onboarding
return if session[:browsing_community]  # ← 세션 체크 필수!
```

**핵심 원칙**:
| 상황 | 해결책 |
|------|--------|
| 일회성 파라미터로 상태 전달 | URL 파라미터 사용 |
| **페이지 이동 시에도 상태 유지 필요** | **세션** 사용 |
| 브라우저 종료 후에도 유지 필요 | **쿠키** 사용 |

**테스트**: `test/controllers/posts_controller_test.rb` - `redirect_to_onboarding 세션 기반 테스트` 섹션

### ⚠️ Tailwind CSS 아키텍처 (2026-01-18 전환 완료)
```
현재 구조:
- 빌드된 CSS 사용: stylesheet_link_tag "tailwind" (Line 58-59)
- CSS Variables + 애니메이션: 인라인 <style> 태그 (Line 61-295)
- app/assets/builds/tailwind.css (223KB, Tailwind v4.1.16 + safelist)

왜 인라인 CSS를 유지?
- CSS Variables는 Tailwind 빌드에 포함되지 않음
- 애니메이션은 인라인으로 두어 빌드 상태와 무관하게 동작 보장

성능 개선 (검증됨):
- CDN (407KB JavaScript) → 빌드 CSS (223KB, Gzip ~30KB)
- 렌더 블로킹 제거 (JavaScript 실행 불필요)
- 캐시 히트율: 60-70% → 95%+
- 예상 LCP 개선: -100~200ms

Safelist (config/shadcn.tailwind.js):
- 임의값 클래스 214개+ 등록
- bg-[#2C2825], z-[9999], h-[clamp(...)] 등

롤백 (문제 발생 시):
  ./scripts/rollback-to-cdn.sh

관련 파일:
- app/views/layouts/application.html.erb (CSS 로드 + 인라인 스타일)
- app/views/layouts/application.html.erb.cdn-backup (CDN 버전 백업)
- config/shadcn.tailwind.js (safelist 포함)
- app/assets/builds/tailwind.css (빌드된 CSS)
- app/assets/tailwind/application.css (소스)
```

### 🎨 CSS 패턴 가이드

#### z-index 계층 구조
| 레이어 | z-index | 용도 |
|--------|---------|------|
| 기본 콘텐츠 | 없음 | 일반 요소 |
| Sticky 헤더 | z-40~50 | compact_header |
| 모달/오버레이 | z-[60] | profile-overlay |
| 알림 드롭다운 | z-[100] | notification-dropdown |
| Flash 메시지 | z-[9999] | 최상위 알림 |

#### 중앙 정렬 패턴
```erb
<%# 고정 너비 요소 - mx-auto 작동 %>
<div class="mx-auto w-64">콘텐츠</div>

<%# 가변 너비 요소 - flex 사용 %>
<div class="flex justify-center">
  <div>콘텐츠</div>
</div>
```

#### CSS Grid 카드 높이 균일화
```erb
<%# 카드 wrapper에 h-full 필수 %>
<div class="grid md:grid-cols-3 gap-6">
  <div class="h-full">  <%# ← wrapper에 h-full %>
    <div class="h-full flex flex-col">  <%# ← 카드 본체에도 h-full + flex %>
      <div class="flex-1">콘텐츠</div>  <%# ← flex-1로 공간 채움 %>
      <div>하단 고정</div>
    </div>
  </div>
</div>
```

### 👤 익명 프로필 시스템

**핵심 추상화:**
```ruby
render_user_avatar(user, size: "md")  # 익명 아바타 자동 처리
user.display_name                      # 익명 닉네임 자동 처리
```

**동작 원리:**
1. `user.is_anonymous` 플래그 확인
2. 익명 시 → `using_anonymous_avatar?` → `/anonymous[N]-.png` 표시
3. 익명 시 → `display_name` → 익명 닉네임 반환

**관련 파일:**
- 아바타 헬퍼: `app/helpers/avatar_helper.rb`
- 프로필 Concern: `app/models/concerns/profileable.rb`

**사용처:**
- 전문가 카드/모달 (`_expert_card_v2.html.erb`, `_expert_profile_overlay.html.erb`)
- 프로필 위젯, 댓글, 채팅 등

### ⚡ Turbo Stream 주의사항

**중복 ID 문제:**
- Turbo Stream은 **DOM 순서상 첫 번째** 일치하는 ID를 타겟
- 로컬 컨테이너가 전역 컨테이너보다 먼저 있으면 로컬에 렌더링됨
- **해결**: 전역 컨테이너 하나만 사용 (application.html.erb)

**CSS 스택 컨텍스트:**
- `<main>` 내부 요소는 `<main>` 형제 요소를 z-index로 가릴 수 없음
- 모달/오버레이는 반드시 `<main>` **외부**에 렌더링되어야 함

**sessionStorage 페이지간 데이터 전달:**
```javascript
// 저장 (ai_result_controller.js)
sessionStorage.setItem('onboarding_idea_summary', summary)

// 사용 후 삭제 (post_form_controller.js)
const saved = sessionStorage.getItem('onboarding_idea_summary')
sessionStorage.removeItem('onboarding_idea_summary')
```

## 📋 Plan Mode 규칙 (필수!)

### references 폴더 참조 필수
**Plan mode 진입 시 반드시 다음 파일을 읽고 템플릿을 적용:**
```
.claude/references/cc-feature-implementer-main/
├── SKILL.md         # Feature planner 가이드라인
└── plan-template.md # Phase 기반 계획 템플릿
```

### TDD 워크플로우 (Red-Green-Refactor)
각 Phase에서 반드시 준수:
1. 🔴 **RED**: 테스트 먼저 작성 (실패 확인)
2. 🟢 **GREEN**: 최소 코드로 테스트 통과
3. 🔵 **REFACTOR**: 코드 품질 개선 (테스트 유지)
4. ✋ **Quality Gate**: 모든 검증 항목 체크 후 다음 Phase

### Phase 구조 (3-7개로 분리)
```markdown
### Phase N: [목표]
**Goal**: 이 Phase에서 달성할 구체적 기능

#### 🔴 RED: Write Failing Tests First
- [ ] Test N.1: [테스트 설명]
  - File: `test/[테스트파일].rb`
  - Expected: 테스트 실패 확인

#### 🟢 GREEN: Implement to Make Tests Pass
- [ ] Task N.2: [구현 설명]

#### 🔵 REFACTOR: Clean Up Code
- [ ] Task N.3: [리팩토링 설명]

#### Quality Gate ✋
- [ ] All tests pass (`bin/rails test`)
- [ ] No linting errors (`rubocop`)
- [ ] New functionality works
- [ ] No regressions
```

### Quality Gate 체크리스트
각 Phase 완료 후 **반드시** 검증:
- [ ] **Build**: 프로젝트 빌드/컴파일 오류 없음
- [ ] **Tests**: 모든 기존 테스트 통과
- [ ] **New Tests**: 새 기능에 대한 테스트 추가됨
- [ ] **Coverage**: 비즈니스 로직 80% 이상
- [ ] **Linting**: Rubocop 통과
- [ ] **Manual Test**: 수동 테스트 확인
- [ ] **No Regression**: 기존 기능 정상 작동

### Phase 사이징 가이드라인

| 범위 | Phase 수 | 총 소요시간 | 예시 |
|------|----------|-------------|------|
| **Small** | 2-3개 | 3-6시간 | 다크모드 토글, 간단한 UI 컴포넌트 |
| **Medium** | 4-5개 | 8-15시간 | 인증 시스템, 검색 기능 |
| **Large** | 6-7개 | 15-25시간 | AI 분석 시스템, 실시간 채팅 |

### Test Coverage 기준 (Rails 프로젝트)

| 레이어 | 최소 커버리지 | 테스트 유형 |
|--------|--------------|-------------|
| **Model (비즈니스 로직)** | ≥80% | Unit Test |
| **Service Object** | ≥80% | Unit Test |
| **Controller** | ≥70% | Integration Test |
| **View/UI** | - | System Test (E2E) |

**커버리지 명령어:**
```bash
# 테스트 실행
bin/rails test

# 시스템 테스트 (Capybara)
bin/rails test:system

# 특정 파일 테스트
bin/rails test test/models/user_test.rb
```

### Test-First Development 워크플로우

```
1. 🔴 RED Phase
   ├── 테스트 케이스 정의 (입력/출력/엣지케이스)
   ├── 실패하는 테스트 작성
   ├── 테스트 실행 → 실패 확인 ❌
   └── (선택) 실패 테스트 커밋

2. 🟢 GREEN Phase
   ├── 테스트 통과하는 최소 코드 작성
   ├── 2-5분마다 테스트 실행
   ├── 모든 테스트 통과 확인 ✅
   └── 추가 기능 작성 금지 (테스트 범위 내에서만)

3. 🔵 REFACTOR Phase
   ├── 코드 품질 개선 (중복 제거, 명명 개선)
   ├── 리팩토링 후 테스트 실행
   ├── 테스트 여전히 통과 확인 ✅
   └── 커밋
```

### 위험 평가 및 롤백 전략

**계획 문서에 반드시 포함:**
1. **Risk Assessment**: 기술/의존성/일정/품질 위험 식별
2. **Rollback Strategy**: 각 Phase 실패 시 복구 방법
3. **Progress Tracking**: Phase별 진행률, 체크박스 상태

### ⛔ Plan Mode에서 금지 사항
❌ TDD 없이 구현만 진행
❌ Quality Gate 생략
❌ Phase 건너뛰기
❌ 테스트 없이 다음 Phase 진행
❌ 기존 코드 불필요한 수정 (최소 변경 원칙)

### 계획 파일 위치
```
.claude/plans/[plan-name].md
```

### 📚 Plan Mode 참조 문서
상세 가이드라인은 다음 파일 참조:
- **SKILL.md**: Phase 사이징, 테스트 명세, 커버리지 계산
- **plan-template.md**: 완전한 계획 문서 템플릿 (TDD 구조 포함)

## 핵심 파일 Quick Reference

### 라우팅 & 컨트롤러
- **라우팅**: `config/routes.rb`
- **커뮤니티**: `app/controllers/posts_controller.rb`
- **채팅**: `app/controllers/chat_rooms_controller.rb`
- **인증**: `app/controllers/sessions_controller.rb`
- **AI 온보딩**: `app/controllers/onboarding_controller.rb`

### AI 서비스 (멀티에이전트 시스템)
- **설정**: `lib/langchain_config.rb`
- **기본 에이전트**: `app/services/ai/base_agent.rb`
- **오케스트레이터**: `app/services/ai/orchestrators/analysis_orchestrator.rb`
- **에이전트 (5개)**:
  - `app/services/ai/agents/summary_agent.rb`
  - `app/services/ai/agents/target_user_agent.rb`
  - `app/services/ai/agents/market_analysis_agent.rb`
  - `app/services/ai/agents/strategy_agent.rb`
  - `app/services/ai/agents/scoring_agent.rb`
- **도구 (3개)**:
  - `app/services/ai/tools/gemini_grounding_tool.rb` (실시간 웹 검색)
  - `app/services/ai/tools/market_data_tool.rb`
  - `app/services/ai/tools/competitor_database_tool.rb`
- **기타**: `app/services/ai/follow_up_generator.rb`, `app/services/ai/expert_score_predictor.rb`
- **전문가 매칭**: `app/services/expert_matcher.rb`

### 핵심 모델
- **사용자**: `app/models/user.rb`
- **게시글**: `app/models/post.rb`
- **채팅방**: `app/models/chat_room.rb`
- **알림**: `app/models/notification.rb`

### Stimulus 컨트롤러 (60개)
- `app/javascript/controllers/` 디렉토리
- 주요: `new_message`, `chat_list`, `live_search`, `image_upload`, `like_button`, `bookmark_button`
- Admin: `admin/bulk_select`, `admin/dropdown`, `admin/slide_panel`
- AI: `ai_loading`, `ai_result`, `ai_input`
- 기타: `email_verification`, `chat_room`, `message_form`, `load_more`, `confirm` 등

### AI 분석 → 커뮤니티 게시 흐름
- **ai_result_controller**: `app/javascript/controllers/ai_result_controller.js`
  - 분석 결과 → "커뮤니티에 게시" 버튼 클릭 시 요약을 sessionStorage 저장
- **post_form_controller**: `app/javascript/controllers/post_form_controller.js`
  - 게시 폼 로드 시 sessionStorage에서 제목 자동 채움

### 익명 프로필 시스템
- **아바타 헬퍼**: `app/helpers/avatar_helper.rb` - `render_user_avatar()`
- **프로필 Concern**: `app/models/concerns/profileable.rb` - `display_name`, `using_anonymous_avatar?`

### 회원 탈퇴 시스템
- **탈퇴 처리**: `app/services/users/deletion_service.rb`
- **탈퇴 모델**: `app/models/user_deletion.rb`
- **열람 로그**: `app/models/admin_view_log.rb`
- **사용자 컨트롤러**: `app/controllers/user_deletions_controller.rb`
- **관리자 컨트롤러**: `app/controllers/admin/user_deletions_controller.rb`
- **자동 파기 작업**: `app/jobs/destroy_expired_deletions_job.rb`

## 최근 작업 내역
- **[2026-01-25]** OAuth 보안 강화 (Open Redirect 3계층 방지, 필수 필드 검증, 세션 TTL 10분, 이메일 변경 감지)
- **[2026-01-22]** CI 시스템 테스트 안정성 개선 (Turbo 리다이렉트 타이밍, 동적 대기 시간)
- **[2026-01-22]** Hotwire Native P2 앱 출시 준비 완료 (Bridge, Push, Deep Link, Session API)
- **[2026-01-21]** P1 코드 품질 이슈 수정 (bare rescue 명시화, magic number 상수화)
- **[2026-01-21]** 새 메시지 익명 닉네임 표시 수정 (`recipient.name` → `recipient.display_name`)
- **[2026-01-21]** Admin N+1 쿼리 수정: `includes(:oauth_identities)` 추가 (UsersController, DashboardController)
- **[2026-01-21]** 코드 리뷰 개선사항 반영 (SSRF 방지, 날짜 필터 안정성, 쿼리 최적화)
- **[2026-01-21]** WebView 인앱 브라우저 OAuth 경고 기능 추가
- **[2026-01-21]** Hotwire Native 앱 개발 에이전트 9개 구축 (Core 3 + Feature 4 + Release 2)
- **[2026-01-18]** 프로젝트 특화 커스텀 에이전트 11개 구축 (도메인 7 + 품질 4)
- **[2026-01-18]** 채팅 탭 비활성화 후 복귀 시 상태 복구 로직 추가 (Visibility API)
- **[2026-01-18]** CLAUDE.md 채팅 시스템 베스트 프랙티스 10개 패턴 문서화
- **[2026-01-17]** CI 트러블슈팅 가이드 추가 (`rules/testing/ci-troubleshooting.md`)
- **[2026-01-17]** CLAUDE.md에 배운 교훈 및 지속적 개선 섹션 추가
- **[2026-01-16]** AI 분석 결과 UI 개선 (전문가 모달 z-index, 익명 프로필, 액션 카드 높이 균일화)
- **[2026-01-16]** AI → 커뮤니티 게시 흐름 개선 (제목에 요약, 본문 빈 상태로 사용자 직접 작성)
- **[2026-01-08]** Claude Code rules 대폭 확장 (9개 파일, 1,152줄)
- **[2026-01-08]** .claude/ 문서 최신성 업데이트
- **[2026-01-07]** Resend HTTP API 이메일 서비스 연동 (프로덕션)
- **[2026-01-07]** 이메일 인증 에러 처리 및 Sentry 연동
- **[2026-01-06]** 채팅 시스템 최적화 및 버그 수정
- **[2026-01-06]** GA4 맞춤 이벤트 12개 구현 (회원가입, 로그인, 게시글, 좋아요 등)
- **[2026-01-06]** Plan Mode 규칙 추가 (TDD, Quality Gate, references 폴더)
- **[2026-01-06]** Kaminari pagination initializer 추가
- **[2025-12-31]** Agent OS/Design OS 기반 .claude 폴더 구조 개선
  - `standards/` 폴더: rails-backend.md, tailwind-frontend.md, testing.md
  - `workflows/` 폴더: feature-development.md
  - `DESIGN_SYSTEM.md`: 디자인 토큰, 컴포넌트 라이브러리
- **[2025-12-31]** Remember Me (로그인 상태 유지) 기능 구현
- **[2025-12-30]** 회원 탈퇴 시스템 완성 (즉시 익명화, 암호화 보관, 5년 후 자동 파기)
- **[2025-12-30]** 관리자 회원관리 개선 (탈퇴 회원 필터, 원본 정보 표시, 열람 로그)
- **[2025-12-27]** AI 멀티에이전트 시스템 완성 (5개 전문 에이전트)
- **[2025-12-27]** Gemini Grounding 실시간 웹 검색 연동
- **[2025-12-26]** 검색 페이지 UTF-8 인코딩 오류 수정
- **[2025-12-25]** AI 아이디어 분석 Gemini API 연동
- **[2025-12-24]** 채팅 기능 완성 (실시간 메시지, 읽음 표시)
- **[2025-12-23]** OAuth 소셜 로그인 추가 (Google, GitHub)

## 다음 작업 우선순위
1. ~~AI 분석 기능 완성 및 안정화~~ ✅ 완료
2. ~~프로덕션 배포~~ ✅ 완료 (undrewai.com)
3. ~~이메일 인증 시스템~~ ✅ 완료 (Resend HTTP API)
4. 외주 시스템 완성 (지원 버튼, 정산, 리뷰)
5. N+1 쿼리 최적화
6. 🆕 **Hotwire Native 앱 개발** (iOS/Android)

---

## 📱 Hotwire Native 앱 개발 (2026-01-21)

> **상세 가이드**: [agents/mobile/README.md](agents/mobile/README.md)

### 모바일 앱 에이전트 (9개)

| 카테고리 | 에이전트 | 역할 |
|---------|---------|------|
| **Core** | hotwire-native-expert | 아키텍처, Path Configuration |
| | ios-expert | Swift, WKWebView, Keychain |
| | android-expert | Kotlin, WebView, Keystore |
| **Feature** | bridge-expert | 웹-네이티브 양방향 통신 |
| | mobile-auth-expert | 세션 동기화, 생체 인증 |
| | push-notification-expert | FCM, APNs |
| | deep-linking-expert | Universal/App Links |
| **Release** | app-store-expert | TestFlight, App Store 배포 |
| | play-store-expert | Play Store, AAB 배포 |

### 앱 개발 주요 패턴

| 패턴 | 설명 | 관련 에이전트 |
|------|------|--------------|
| **Path Configuration** | URL → 화면 동작 매핑 (modal, push, native) | hotwire-native-expert |
| **앱 감지** | `Turbo Native` User-Agent 확인 | hotwire-native-expert |
| **세션 동기화** | Keychain/Keystore ↔ WebView 쿠키 | mobile-auth-expert |
| **Bridge 통신** | Stimulus ↔ Swift/Kotlin 메시지 | bridge-expert |

### 앱 개발 시 주의사항

| 상황 | 웹 | 앱 |
|------|-----|-----|
| 레이아웃 | `application.html.erb` | `turbo_native.html.erb` (간소화) |
| 세션 저장 | 쿠키 | Keychain/Keystore + 쿠키 동기화 |
| JavaScript `alert()` | 작동 | **차단됨** → Bridge 사용 |
| OAuth | 브라우저 | ASWebAuthenticationSession |
| 딥 링크 | 일반 URL | Universal Links / App Links |

### 기존 에이전트와 협력

```
채팅 앱 연동:
chat-expert → bridge-expert → push-notification-expert

인증 시스템:
auth-expert → mobile-auth-expert → ios-expert/android-expert

게시글 공유:
community-expert → deep-linking-expert
```

### 📊 앱 출시 준비도 현황 (2026-01-22 업데이트)

> **상세 보고서**: [hotwire_native_readiness.html.erb](../app/views/reports/hotwire_native_readiness.html.erb)

| 영역 | Before | After | 상태 |
|------|--------|-------|------|
| **P0 (필수)** | 100% | 100% | ✅ 완료 |
| **P1 (품질)** | 45% | 90% | ✅ 완료 |
| **P2 (앱 핵심)** | 10% | 95% | ✅ 완료 |
| **종합 준비도** | 68% | **95%** | ✅ 출시 가능 |

**강점:**
- 실시간 채팅 (Turbo Streams + Solid Cable)
- 66개 Stimulus 컨트롤러 + 5개 Bridge 컨트롤러
- Remember Me 20년 영구 쿠키
- OAuth 세션 백업 패턴
- API 토큰 기반 세션 동기화

### ✅ P2 구현 완료 (2026-01-22)

**생성된 파일:**

| 카테고리 | 파일 | 용도 |
|----------|------|------|
| **API** | `app/controllers/api/v1/devices_controller.rb` | 디바이스 등록 |
| | `app/controllers/api/v1/auth_controller.rb` | 세션 동기화 |
| **Core** | `app/controllers/concerns/turbo_native_navigation.rb` | 앱 리다이렉션 |
| | `app/models/device.rb` | FCM 토큰 저장 |
| **Push** | `app/services/push_notifications/fcm_service.rb` | FCM 서비스 |
| | `app/jobs/send_push_notification_job.rb` | 비동기 푸시 |
| **Bridge** | `app/javascript/controllers/bridge/*.js` | 5개 컨트롤러 |
| **Deep Link** | `public/.well-known/apple-app-site-association` | iOS Universal Links |
| | `public/.well-known/assetlinks.json` | Android App Links |
| **Config** | `public/hotwire-native/path-configuration.json` | URL 매핑 |

**API 엔드포인트:**

| Endpoint | Method | 용도 |
|----------|--------|------|
| `/api/v1/devices` | POST | 디바이스 등록 |
| `/api/v1/devices/:id` | DELETE | 디바이스 해제 |
| `/api/v1/auth` | POST | 토큰 발급 |
| `/api/v1/auth/validate` | GET | 토큰 검증 |
| `/api/v1/auth` | DELETE | 토큰 폐기 |

### 🔧 네이티브 개발자 필요 작업

| 파일 | 수정 내용 |
|------|----------|
| `apple-app-site-association` | `TEAM_ID` → 실제 Apple Team ID |
| `assetlinks.json` | `PLACEHOLDER_SHA256_FINGERPRINT` → 서명 핑거프린트 |
| `application.html.erb:15` | `APP_ID` → 실제 App Store ID |
| Firebase Console | FCM credentials 설정 |

### 📌 브랜치 현황

| 브랜치 | 상태 | 포함 내용 |
|--------|------|----------|
| `main` | 배포됨 | P0 (앱 레이아웃, 보안 헤더) |
| `feature/hotwire-native-p1` | 미배포 | P1 + P2 (전체 앱 인프라) |

**머지 시점**: 네이티브 앱 개발 완료 후

---

## 프로젝트 개요
스타트업 커뮤니티 플랫폼 - Rails 기반 웹 애플리케이션

**비전**: "아이디어·사람·외주가 한 공간에서 연결되는 최초의 창업 커뮤니티"

**목적**:
한국 초보 창업자들이 겪는 정보 부족, 외주처 산재, 네트워크 부재 문제를 해결하기 위해
**커뮤니티 기반의 신뢰 데이터**와 **외주 기능**을 결합하여
처음 창업하는 사람들이 시행착오 없이 시작할 수 있도록 돕는 플랫폼

**핵심 가치**:
- 커뮤니티 활동 → 프로필 → 외주 공고가 자연스럽게 연결되는 사용자 흐름
- 신뢰 기반 프로필을 통한 사람과 프로젝트의 매칭
- 파편화된 정보의 통합 (커뮤니티 + 외주 + 네트워킹)

**타겟 사용자**:
- 대학생/초기 창업자
- 사이드프로젝트를 하고 싶은 개발자/디자이너/기획자
- 외주를 맡기고 싶은 소규모 창업자
- 창업 관련 인사이트를 얻고 싶은 일반 사용자

---

## 기술 스택

### Backend
- **Rails**: 8.1.1
- **Ruby**: 3.4.7
- **Database**: SQLite3 (개발), PostgreSQL (프로덕션 권장)
- **Job Queue**: Solid Queue
- **Cache**: Solid Cache
- **WebSocket**: Solid Cable

### Frontend
- **Framework**: Hotwire (Turbo + Stimulus)
- **Asset Pipeline**: Propshaft
- **Import Maps**: importmap-rails
- **Styling**: [CSS 프레임워크 선택 시 추가]

### Infrastructure
- **Web Server**: Puma
- **Deployment**: Kamal (Docker)
- **Image Processing**: ImageMagick (image_processing gem)

### Development & Testing
- **Testing**: Minitest, Capybara, Selenium
- **Linting**: Rubocop Rails Omakase
- **Security**: Brakeman, Bundler Audit
- **Debugging**: Debug gem

---

## 프로젝트 구조

```
app/
├── controllers/     # MVC Controllers
├── models/          # ActiveRecord Models
├── views/           # ERB Templates
├── javascript/      # Stimulus Controllers
├── assets/          # CSS, Images
├── jobs/            # Background Jobs
├── mailers/         # Email Templates
└── helpers/         # View Helpers

config/
├── routes.rb        # 라우팅 정의
├── database.yml     # DB 설정
└── initializers/    # 초기화 코드

db/
├── migrate/         # 마이그레이션
└── seeds.rb         # 초기 데이터

test/
├── controllers/     # Controller 테스트
├── models/          # Model 테스트
├── system/          # E2E 테스트
└── fixtures/        # 테스트 데이터
```

---

## 코딩 규칙 & 컨벤션

### Ruby/Rails 스타일
- **Style Guide**: Rubocop Rails Omakase 준수
- **Naming**: snake_case (변수/메서드), CamelCase (클래스)
- **Indentation**: 2 spaces
- **Line Length**: 120자 이하

### 아키텍처 원칙
- **RESTful Design**: 리소스 기반 라우팅 우선
- **Skinny Controllers, Fat Models**: 비즈니스 로직은 모델에
- **DRY**: 중복 코드 제거, Concern 활용
- **Convention over Configuration**: Rails 규약 준수

### 데이터베이스
- **Migration**: 롤백 가능하게 작성
- **Index**: 외래키, 검색 컬럼에 인덱스 추가
- **Validation**: 모델 레벨 검증 필수

### 테스팅
- **Coverage**: 핵심 기능 80% 이상
- **Test Types**:
  - Unit (모델, 헬퍼)
  - Integration (컨트롤러)
  - System (E2E)
- **Fixtures**: 명확하고 최소한의 데이터

### 보안
- **Strong Parameters**: 컨트롤러에서 파라미터 필터링
- **CSRF Protection**: Rails 기본 보호 활성화
- **SQL Injection**: Raw SQL 지양, ActiveRecord 사용
- **XSS**: ERB 자동 이스케이핑 활용
- **Authentication**: has_secure_password 사용 권장

---

## 개발 워크플로우

### Branch 전략
```
main          # 프로덕션 브랜치
└── develop   # 개발 브랜치
    └── feature/[기능명]  # 기능 브랜치
```

### Commit 메시지
```
[타입] 제목 (50자 이내)

상세 설명 (선택사항)

예시:
[feat] 사용자 회원가입 기능 구현
[fix] 로그인 세션 버그 수정
[refactor] User 모델 리팩토링
[test] User 모델 테스트 추가
[docs] README 업데이트
```

### 개발 순서
1. 요구사항 분석
2. 모델 설계 (ERD)
3. 마이그레이션 작성
4. 모델 + 테스트 작성
5. 컨트롤러 + 라우팅
6. 뷰 구현
7. 통합 테스트
8. 리팩토링

---

## 금지 사항

### 절대 하지 말 것
❌ `User.all` (without pagination)
❌ N+1 쿼리 (includes/joins 사용)
❌ SQL Injection 가능한 raw query
❌ 민감정보 로그 출력
❌ credentials 파일 커밋
❌ 테스트 없는 핵심 기능 배포
❌ production에서 db:reset/drop

### 지양할 것
⚠️ 컨트롤러에 비즈니스 로직
⚠️ 뷰에 복잡한 Ruby 로직
⚠️ God Object (거대한 클래스)
⚠️ Magic Number (상수화 필요)
⚠️ 과도한 Callback (모델)

---

## 📚 배운 교훈 (Lessons Learned)

> **목적**: 반복되는 실수를 방지하고 프로젝트 지식을 축적

### 🔐 OAuth 보안 4계층 방어 (Critical! 2026-01-25)

**배경**: OAuth 플로우는 외부 리다이렉션이 많아 Open Redirect, 세션 탈취, 필드 위변조 공격에 취약

#### 1. Open Redirect 방지 (3계층 검증)

```ruby
# app/controllers/concerns/session_redirect.rb

def validate_redirect_url(url)
  return nil if url.blank?

  # 1층: 상대 경로 허용 (단, // 프로토콜 상대 URL 제외)
  return url if url.start_with?("/") && !url.start_with?("//")

  # 2층: 절대 URL 파싱
  uri = URI.parse(url)

  # 3층: http/https만 허용 (javascript:, data: 스킴 차단 - XSS 방지)
  if uri.scheme.present? && !%w[http https].include?(uri.scheme.downcase)
    Rails.logger.warn "[SessionRedirect] Blocked dangerous scheme: #{uri.scheme}"
    return nil
  end

  # 같은 호스트만 허용
  uri.path.presence || "/" if uri.host.nil? || uri.host == request.host
end
```

**핵심 포인트**:
| 공격 유형 | 차단 계층 | 예시 |
|----------|----------|------|
| 외부 도메인 리다이렉트 | 호스트 검증 | `https://evil.com/steal` |
| 프로토콜 상대 URL | `//` 검사 | `//evil.com/path` |
| XSS via javascript: | 스킴 검증 | `javascript:alert(1)` |
| XSS via data: | 스킴 검증 | `data:text/html,...` |

**관련 파일**: `app/controllers/concerns/session_redirect.rb`

#### 2. OAuth 필수 필드 검증

```ruby
# app/controllers/omniauth_callbacks_controller.rb

def valid_oauth_auth?(auth)
  return false if auth.blank?
  return false if auth.provider.blank?  # 필수: 제공자
  return false if auth.uid.blank?       # 필수: 고유 ID
  return false if auth.info&.email.blank?  # 필수: 이메일
  true
end
```

**위험 시나리오**: 악의적인 OAuth 제공자가 uid나 email 없이 응답 → 사용자 식별 불가 → 잘못된 계정 연결

#### 3. 세션 TTL 관리 (만료 시간)

```ruby
# 신규 OAuth 사용자 - 약관 동의 대기
session[:pending_oauth_user_id] = @user.id
session[:pending_oauth_created_at] = Time.current.to_i  # ← 타임스탬프!

# 약관 동의 페이지에서 10분 만료 체크
def validate_session_timeout(timeout: 10.minutes)
  created_at = session[:pending_oauth_created_at]
  return false if created_at.blank?
  Time.current.to_i - created_at < timeout.to_i
end
```

**목적**: 미완료 OAuth 플로우가 무한정 유효하지 않도록 제한

#### 4. 이메일 변경 감지 (보안 감사)

```ruby
# app/models/concerns/oauthable.rb

# 기존 OAuth 연결로 로그인 시
if email.present? && user.email != email
  Rails.logger.warn "[OAuth] Email mismatch detected: User##{user.id} " \
                    "(stored: #{user.email}, oauth: #{email}, provider: #{provider})"
  Sentry.capture_message("OAuth email mismatch", level: :warning, extra: { ... })
end
```

**탐지 대상**: 계정 탈취 시도, OAuth 제공자의 이메일 변경, 데이터 불일치

**관련 파일**:
- `app/controllers/concerns/session_redirect.rb` - Open Redirect 방지
- `app/controllers/omniauth_callbacks_controller.rb` - 필수 필드 검증, 세션 TTL
- `app/models/concerns/oauthable.rb` - 이메일 변경 감지

### 🛡️ SSRF (Server-Side Request Forgery) 방지 (2026-01-21)

**공격 시나리오**: 사용자가 입력한 URL로 서버가 요청 → 내부 네트워크(AWS metadata 등) 접근 가능

```ruby
# app/services/url_sanitizer.rb

class UrlSanitizer
  PRIVATE_IP_RANGES = [
    IPAddr.new("127.0.0.0/8"),      # Loopback (localhost)
    IPAddr.new("10.0.0.0/8"),       # Class A private
    IPAddr.new("172.16.0.0/12"),    # Class B private
    IPAddr.new("192.168.0.0/16"),   # Class C private
    IPAddr.new("169.254.0.0/16"),   # Link-local (⚠️ AWS metadata!)
    IPAddr.new("0.0.0.0/8"),        # This network
    IPAddr.new("::1/128"),          # IPv6 loopback
    IPAddr.new("fc00::/7"),         # IPv6 unique local
    IPAddr.new("fe80::/10")         # IPv6 link-local
  ].freeze

  def self.safe?(url)
    new(url).safe?
  end

  def safe?
    valid_uri? && valid_scheme? && public_ip?
  end

  private

  # DNS rebinding 공격 방지: hostname이 아닌 해석된 IP로 검증
  def public_ip?
    ip_address = Resolv.getaddress(@uri.host)
    !PRIVATE_IP_RANGES.any? { |range| range.include?(IPAddr.new(ip_address)) }
  end
end
```

**사용 예시**:
```ruby
# 외부 이미지 URL 수집 시
def fetch_image(url)
  return nil unless UrlSanitizer.safe?(url)
  # 안전한 URL만 요청
  HTTParty.get(url, timeout: 5)
end
```

**차단 대상**:
| IP 범위 | 용도 | 위험성 |
|---------|------|--------|
| `127.0.0.0/8` | localhost | 내부 서비스 접근 |
| `169.254.169.254` | AWS metadata | IAM 토큰 탈취 가능 |
| `10.x.x.x` | 사설 네트워크 | 내부 API 접근 |
| `192.168.x.x` | 사설 네트워크 | 개발 서버 접근 |

**관련 파일**: `app/services/url_sanitizer.rb`

### 📱 WebView/인앱 브라우저 OAuth 제한 (2026-01-21)

**문제**: Google은 2016년부터 WebView에서 OAuth 인증을 금지 (피싱 공격 위험)

**영향받는 앱**:
| 앱 | User-Agent 패턴 | 특수 처리 |
|----|----------------|----------|
| 카카오톡 | `kakaotalk` | `kakaotalk://web/openExternal` 스킴 지원 |
| Instagram | `instagram` | 외부 브라우저 안내 필요 |
| Facebook | `fban`, `fbav` | 외부 브라우저 안내 필요 |
| LINE | `line/` | 외부 브라우저 안내 필요 |
| 네이버 | `naver` | 외부 브라우저 안내 필요 |

```ruby
# app/helpers/user_agent_helper.rb

def in_app_browser?
  ua = request.user_agent.to_s.downcase

  # Android WebView: "wv" 토큰 또는 Version/X.X Chrome 패턴
  return true if ua.include?("android") && (ua.include?("; wv)") || ua.match?(/version\/[\d.]+ chrome/))

  # iOS WebView: Mobile/ 있지만 Safari/ 없음
  return true if (ua.include?("iphone") || ua.include?("ipad")) && ua.include?("mobile/") && !ua.include?("safari/")

  # 소셜 앱 인앱 브라우저
  return true if ua.match?(/fban|fbav|instagram|twitter|line\/|kakaotalk|naver|discord|slack/)

  false
end

def detected_app_name
  ua = request.user_agent.to_s.downcase
  case
  when ua.include?("kakaotalk") then "카카오톡"
  when ua.include?("instagram") then "Instagram"
  when ua.match?(/fban|fbav/) then "Facebook"
  # ... 기타 앱
  else "인앱 브라우저"
  end
end
```

**OAuth 컨트롤러에서 사용**:
```ruby
def oauth_warning
  if in_app_browser?
    flash.now[:alert] = "#{detected_app_name}에서는 Google 로그인이 제한됩니다. " \
                        "Safari 또는 Chrome에서 열어주세요."
    render :oauth_warning  # 외부 브라우저 안내 페이지
    return
  end
  # 정상 OAuth 진행
end
```

**관련 파일**: `app/helpers/user_agent_helper.rb`, `app/controllers/oauth_controller.rb`

### 📦 뷰 인라인 로직 → 컨트롤러 추출 패턴 (2026-01-25)

**문제**: ERB 템플릿에서 복잡한 로직(URI 빌딩, 조건 계산 등)을 인라인으로 작성하면:
1. 테스트하기 어려움 (뷰 테스트 필요)
2. 에러 처리가 복잡해짐
3. 코드 중복 가능성 증가

**개선 전** (뷰에서 인라인 URI 빌딩):
```erb
<%# ❌ 뷰에서 직접 URI 빌딩 - 테스트 어려움 %>
<%
  uri = URI.parse(@login_url)
  chrome_path = "#{uri.host}#{uri.path}"
  chrome_path += "?#{uri.query}" if uri.query.present?
  ios_chrome_url = "googlechromes://#{chrome_path}"
%>
<a href="<%= ios_chrome_url %>">Chrome에서 열기</a>
```

**개선 후** (컨트롤러 헬퍼 메서드):
```ruby
# ✅ 컨트롤러에서 미리 계산 + 에러 처리
# app/controllers/oauth_controller.rb

def webview_warning
  @ios_chrome_url = build_ios_chrome_url(@login_url)
  @android_intent_url = build_android_intent_url(@login_url)
end

private

def build_ios_chrome_url(url)
  uri = URI.parse(url)
  chrome_path = "#{uri.host}#{uri.path}"
  chrome_path += "?#{uri.query}" if uri.query.present?
  "googlechromes://#{chrome_path}"
rescue URI::InvalidURIError => e
  Rails.logger.warn "[OAuth] Invalid URI: #{e.message}"
  nil  # 뷰에서 nil 체크 가능
end
```

```erb
<%# 뷰는 단순하게 %>
<a href="<%= @ios_chrome_url %>">Chrome에서 열기</a>
```

**장점**:
| 측면 | 개선 전 | 개선 후 |
|------|---------|---------|
| 테스트 | 시스템 테스트만 가능 | 단위 테스트 가능 |
| 에러 처리 | 템플릿 에러 발생 | 컨트롤러에서 처리 |
| 재사용 | 불가 | 다른 액션에서 호출 가능 |
| 가독성 | ERB + Ruby 혼재 | 분리된 관심사 |

**관련 파일**: `app/controllers/oauth_controller.rb`, `app/views/oauth/webview_warning.html.erb`

### 🔒 JavaScript DOM 쿼리 null 방어 강화 (2026-01-25)

**문제**: `getElementById`가 요소를 찾지 못하면 `null` 반환 → 프로퍼티 접근 시 TypeError

**개선 전**:
```javascript
// ❌ null 시 크래시
function showCopySuccess() {
  const buttonText = document.getElementById('copy-button-text');
  buttonText.textContent = '복사되었습니다!';  // TypeError if null
}
```

**개선 후**:
```javascript
// ✅ null 방어 + DOM 제거 대비
function showCopySuccess() {
  const buttonText = document.getElementById('copy-button-text');
  if (!buttonText) return;  // Early return

  const originalText = buttonText.textContent;
  buttonText.textContent = '복사되었습니다!';

  setTimeout(() => {
    // 타이머 실행 시 DOM에서 제거되었을 수 있음
    if (buttonText.parentElement) {
      buttonText.textContent = originalText;
    }
  }, 2000);
}
```

**체크 패턴**:
| 상황 | 체크 방법 |
|------|----------|
| 요소 존재 확인 | `if (!element) return;` |
| DOM 제거 여부 | `if (element.parentElement)` |
| Optional chaining | `element?.textContent` |

**발생 조건**:
- 조건부 렌더링으로 요소가 없는 경우
- Turbo 네비게이션 중 DOM 교체
- 중복 ID로 잘못된 요소 선택

**관련 파일**: `app/views/oauth/webview_warning.html.erb`

### 🧪 CI 테스트: Turbo 리다이렉트 타이밍 (2026-01-22)

**문제**: CI 환경에서 Turbo 리다이렉트 완료 전 assertion 실행 → 간헐적 테스트 실패

```ruby
# test/support/system_test_helpers.rb

# CI 환경 대기 시간 상수
CI_WAIT_TIME = 20      # CI는 느림
LOCAL_WAIT_TIME = 10   # 로컬은 빠름

def ci_environment?
  ENV["CI"].present? || ENV["GITHUB_ACTIONS"].present?
end

def default_wait_time
  ci_environment? ? CI_WAIT_TIME : LOCAL_WAIT_TIME
end

# Turbo 리다이렉트 완료 대기 헬퍼
def wait_for_turbo_redirect(expected_path = nil, wait: nil)
  wait ||= default_wait_time

  # Turbo 로딩 인디케이터가 사라질 때까지 대기
  assert_no_selector ".turbo-progress-bar", wait: wait

  # 예상 경로가 지정되면 경로 확인
  assert_current_path expected_path, wait: wait if expected_path
end
```

**사용 예시**:
```ruby
test "로그인 후 리다이렉트" do
  log_in_as(@user)

  # ❌ 불안정 - Turbo 완료 전 assertion 실행 가능
  assert_current_path community_path

  # ✅ 안정 - Turbo 로딩 완료 후 assertion
  wait_for_turbo_redirect community_path
end
```

**핵심 포인트**:
| 환경 | 기본 대기 시간 | 특이사항 |
|------|--------------|---------|
| 로컬 | 10초 | 빠른 피드백 |
| CI (GitHub Actions) | 20초 | 리소스 제한으로 느림 |

**관련 파일**: `test/support/system_test_helpers.rb`

### 🚨 코드 수정 후 배포 확인 필수 (Critical! 2026-01-21)

**문제**: 로컬에서 코드를 수정했지만 **커밋/푸시를 안 해서** 배포 서버에 반영되지 않음

**실제 사례**: 익명 닉네임 수정 (`recipient.name` → `recipient.display_name`)
- 로컬에서 수정 완료 ✅
- 테스트 통과 ✅
- **커밋 안 함** ❌ → 배포 서버에서 버그 지속

**필수 체크리스트** (수정 완료 후):
```bash
# 1. 변경사항 확인
git status

# 2. 커밋 (변경 파일이 있으면)
git add [파일] && git commit -m "[타입] 메시지"

# 3. 푸시
git push origin main

# 4. 배포 확인 (프로덕션에서 직접 테스트)
```

**원칙**: 코드 수정 → **반드시 `git status` 확인** → 커밋/푸시 → 배포 서버 테스트

### 익명 프로필 시스템: `display_name` 필수 사용 (2026-01-21)

**핵심 규칙**: 사용자 이름 표시하는 **모든 곳**에서 `display_name` 사용

| 메서드 | 반환값 | 사용 조건 |
|--------|--------|----------|
| `user.name` | 실제 이름 (항상) | **❌ 사용자에게 노출되는 곳에서 금지** |
| `user.display_name` | 익명이면 닉네임, 아니면 실명 | **✅ 항상 이것 사용** |

**적용 위치**:
```ruby
# ❌ 금지 - 익명성 침해
<%= recipient.name %>
data-preselected-name-value="<%= recipient.name %>"

# ✅ 올바른 방법
<%= recipient.display_name %>
data-preselected-name-value="<%= recipient.display_name %>"
```

**관련 파일**:
- `app/views/chat_rooms/_new_message_panel.html.erb:11`
- `app/models/concerns/profileable.rb` - `display_name` 정의

### N+1 쿼리 방지: Association 메서드 호출 시 includes() 필수 (2026-01-21)

**문제**: 뷰에서 `user.oauth_user?` 같은 association 메서드 호출 시 N+1 쿼리 발생

```ruby
# ❌ N+1 발생 - 목록의 각 유저마다 쿼리 실행
@users.each { |u| u.oauth_user? }  # 20명 = 20개 추가 쿼리

# ✅ includes로 미리 로드
@users = User.includes(:oauth_identities).limit(20)
@users.each { |u| u.oauth_user? }  # 1개 쿼리로 해결
```

**흔한 패턴**:
| 뷰에서 호출 | 컨트롤러에서 필요 |
|------------|------------------|
| `user.oauth_user?` | `includes(:oauth_identities)` |
| `user.admin?` | (is_admin 컬럼이므로 불필요) |
| `post.user.name` | `includes(:user)` |
| `comment.replies` | `includes(:replies)` |

**관련 파일**:
- `app/controllers/admin/users_controller.rb:52`
- `app/controllers/admin/dashboard_controller.rb:31`

### OAuth 세션 손실 패턴 (Critical!)

**문제**: OAuth 외부 리다이렉션 시 Rails 세션 데이터 손실

```ruby
# ❌ 세션만 사용 - OAuth 리다이렉션 후 손실 가능
session[:pending_idea] = idea

# ✅ 세션 + 쿠키 백업 - OAuth 대비
session[:pending_idea] = idea
cookies.encrypted[:pending_idea_backup] = {
  value: idea,
  expires: 1.hour.from_now
}

# ✅ 복원 시 세션 우선, 쿠키 폴백
idea = session[:pending_idea] || cookies.encrypted[:pending_idea_backup]
```

**상태 저장 선택 가이드**:
| 시나리오 | 권장 방법 |
|---------|----------|
| 내부 리다이렉션만 (일반 폼 제출) | 세션 |
| **OAuth 등 외부 리다이렉션** | **세션 + 쿠키 백업** |
| 브라우저 종료 후에도 유지 | 쿠키 |
| 민감 데이터 | `cookies.encrypted` 필수 |

**관련 파일**: `app/controllers/concerns/pending_analysis.rb`

### 데이터 병합 필드 누락 방지

**문제**: 복잡한 객체 병합 시 중첩 필드 누락

```ruby
# ❌ 수동 병합 - 필드 누락 위험
result[:score] = {
  total_score: score.total_score,
  grade: score.grade
  # radar_chart_data 누락!
}

# ✅ 전용 빌더 메서드 사용
result[:score] = build_score_result(score)

def build_score_result(score)
  {
    total_score: score.total_score,
    grade: score.grade,
    dimension_scores: score.dimension_scores,
    radar_chart_data: score.radar_chart_data  # 모든 필드 명시
  }
end
```

**원칙**: 복잡한 데이터 구조 병합은 **전용 빌더 메서드**로 추출하여 필드 누락 방지

### CI 실패 패턴 (System Test)

**상세 가이드**: [rules/testing/ci-troubleshooting.md](rules/testing/ci-troubleshooting.md)

| 패턴 | 빈도 | 핵심 해결책 |
|------|------|-------------|
| **Stale Element** | 20% | JavaScript `querySelector` 사용 (반복문 내부) |
| **ESC 키 모달** | 10% | `document.dispatchEvent` 사용 |
| **Stimulus 타이밍** | 25% | `assert_selector "[data-controller='xxx']", wait: 5` |
| **Dropdown 경쟁** | 15% | 옵션 표시 대기 후 클릭 |
| **상태 오염** | 5% | `SecureRandom.hex(4)` 유니크 데이터 |

### 알려진 함정 (Known Pitfalls)

| 상황 | 잘못된 접근 | 올바른 접근 |
|------|------------|-------------|
| Turbo Stream 후 요소 조작 | Ruby 변수 재사용 | `find()` 재호출 또는 JS querySelector |
| 모달 ESC 키 닫기 | `send_keys(:escape)` | `document.dispatchEvent(KeyboardEvent)` |
| 숨겨진 요소 클릭 | Capybara `.click` | `page.execute_script("arguments[0].click()")` |
| 폼 제출 중복 방지 테스트 | 요소 캐싱 | 매 반복마다 새로 찾기 |

### JavaScript DOM 쿼리 Null 안전성 (2026-01-19)

**문제**: `document.querySelector()`가 요소를 찾지 못하면 `null` 반환 → 프로퍼티 접근 시 TypeError

```javascript
// ❌ 위험 - null 시 크래시
document.querySelector('meta[name="csrf-token"]').content

// ✅ 안전 - Optional chaining + 폴백
document.querySelector('meta[name="csrf-token"]')?.content || ''

// ✅ 최적 - Stimulus value 사용 (DOM 쿼리 제거)
// View: data-controller-csrf-token-value="<%= form_authenticity_token %>"
// JS: this.csrfTokenValue
```

**CSRF 토큰 접근 우선순위**:
| 방법 | 안전성 | 성능 | 사용 조건 |
|------|--------|------|----------|
| `this.csrfTokenValue` | ✅ 최적 | ✅ 빠름 | static values에 csrfToken 정의됨 |
| `?.content \|\| ''` | ✅ 안전 | ⚠️ DOM 쿼리 | csrfToken value 미정의 시 |
| `.content` (no chaining) | ❌ 위험 | - | **금지** |

**발생 조건**:
- 비로그인 사용자
- 네트워크 지연으로 메타태그 로드 전 스크립트 실행
- 브라우저 확장 프로그램 간섭
- Turbo 캐시에서 불완전한 DOM 복원

**관련 파일**:
- `ai_input_controller.js:147`
- `canvas_modal_controller.js:296`
- `leave_chat_controller.js:52`

### 채팅 시스템 베스트 프랙티스

#### 1. 메시지 중복 방지 3계층
```
┌─────────────────────────────────────────────────┐
│ 1. 클라이언트 (message_form_controller.js)     │
│    - isSubmitting 플래그로 연타 방지            │
│    - event.isComposing 체크 (한글 IME 방지)    │
├─────────────────────────────────────────────────┤
│ 2. 서버 검증 (message.rb)                      │
│    - 5초 내 동일 content 중복 체크 validation  │
├─────────────────────────────────────────────────┤
│ 3. Broadcaster (broadcaster.rb)                │
│    - 발신자에게는 text 메시지 브로드캐스트 X   │
│    - HTTP 응답으로 이미 렌더링됨               │
└─────────────────────────────────────────────────┘
```

**관련 파일**:
- `app/javascript/controllers/message_form_controller.js`
- `app/models/message.rb:122-136`
- `app/services/messages/broadcaster.rb:42-57`

#### 2. Race Condition 방지 (카운터 업데이트)
```ruby
# ❌ 위험: 동시 요청 시 카운트 손실
participants.each { |p| p.update(unread_count: p.unread_count + 1) }

# ✅ Row-level locking으로 원자성 보장
participants.lock("FOR UPDATE")
           .where.not(user_id: sender_id)
           .update_all("unread_count = unread_count + 1")
```
**적용**: `unread_count`, `likes_count`, `comments_count` 등

#### 3. 트랜잭션과 부수 효과 분리
```ruby
# ✅ 데이터 일관성이 필요한 작업만 트랜잭션 내부
ActiveRecord::Base.transaction do
  message.save!
  update_unread_counts
end

# ✅ 트랜잭션 외부: 실패해도 롤백 불필요한 작업
broadcast_to_participants
send_push_notification
```

#### 4. has_one으로 N+1 방지 (채팅 목록 최적화)
```ruby
# ❌ 전체 메시지 로드
has_many :messages
# 채팅목록에서 messages.last 호출 시 N+1

# ✅ 마지막 메시지만 로드
has_one :last_message_preview,
        -> { order(created_at: :desc) },
        class_name: "Message"

# 사용: includes(:last_message_preview)
```

#### 5. Preload 상태 확인 패턴
```ruby
# ✅ preload 여부에 따라 쿼리/Ruby 처리 분기
def other_participant(current_user)
  if users.loaded?
    users.find { |u| u.id != current_user.id }  # Ruby (쿼리 없음)
  else
    users.where.not(id: current_user.id).first  # SQL
  end
end
```

#### 6. SQL 집계 활용 (N+1 방지)
```ruby
# ❌ Ruby 반복 - N+1 발생
participants.sum { |p| p.unread_count }

# ✅ SQL 집계 - 단일 쿼리
participants.sum(:unread_count)
```

#### 7. update 메서드 선택 가이드
| 메서드 | 콜백 실행 | 용도 |
|--------|----------|------|
| `update` | O | 일반 업데이트 |
| `update_columns` | X | 단일 레코드, 타임스탬프 건너뛰기 |
| `update_all` | X | 여러 레코드 일괄 업데이트 |

#### 8. 탭 비활성화 후 복귀 처리 (Visibility API)
```javascript
// ✅ 탭 재활성화 시 상태 복구
document.addEventListener("visibilitychange", () => {
  if (document.visibilityState === "visible") {
    // 고정된 isSubmitting 상태 리셋
    // ActionCable 연결 상태 확인 및 재연결
  }
})
```
**문제**: 폼 제출 중 탭 전환 시 `turbo:submit-end` 누락 → `isSubmitting: true` 고정

#### 9. nil 체크 3단계 방어선
```ruby
# Model: optional 설정
belongs_to :other_user, optional: true

# Controller: Early return
def profile_overlay
  return head :not_found unless @other_user
end

# View: 조건부 렌더링
<% if other_user.present? %>
  <%= other_user.name %>
<% else %>
  <span class="text-gray-400">Unknown</span>
<% end %>
```

#### 10. 에러 처리 패턴 (Sentry 연동)
```ruby
def call
  # 비즈니스 로직
rescue StandardError => e
  Rails.logger.error "[ChatService] #{e.class}: #{e.message}"
  Sentry.capture_exception(e) if defined?(Sentry)
  raise  # 삼키지 않음! 호출자가 결정하도록
end
```

### Stimulus 이벤트 리스너 bind() 패턴 (2026-01-19)

**문제**: `bind(this)` 인라인 호출 시 `removeEventListener` 실패

```javascript
// ❌ 위험 - 매번 새 함수 객체 생성
connect() {
  element.addEventListener('event', this.handler.bind(this))
}
disconnect() {
  element.removeEventListener('event', this.handler.bind(this))  // 실패!
}

// ✅ 안전 - 동일 참조 유지
connect() {
  this.boundHandler = this.handler.bind(this)
  element.addEventListener('event', this.boundHandler)
}
disconnect() {
  element.removeEventListener('event', this.boundHandler)
}
```

**원인**: JavaScript의 `bind()`는 매번 **새로운 함수 객체**를 생성하므로 `func.bind(this) !== func.bind(this)`

**결과**: 리스너 미제거 → 메모리 누수 → "disconnected port object" 오류 (Turbo 네비게이션 시)

**관련 파일** (수정 완료):
- `app/javascript/controllers/image_carousel_controller.js`
- `app/javascript/controllers/confirm_controller.js`

### Stimulus 키 필터 문법 (2026-01-19)

**문제**: Stimulus는 `keydown.escape`를 지원하지 않음

| 잘못된 사용 | 올바른 사용 |
|------------|------------|
| `keydown.escape` | `keydown.esc` |

**Stimulus 지원 키 필터**:
| 키 | 필터 |
|----|------|
| Escape | `esc` |
| Enter | `enter` |
| Tab | `tab` |
| Space | `space` |
| 화살표 | `arrow-down`, `arrow-up`, `arrow-left`, `arrow-right` |

**에러 메시지**: `contains unknown key filter: escape`

**관련 파일** (수정 완료):
- `app/views/shared/_search_modal.html.erb`

### 파일 편집 시 인접 코드 삭제 주의 (2026-01-19)

**문제**: 특정 줄을 수정할 때 인접한 코드 블록이 실수로 삭제됨

**실제 사례**: PNG→WebP 이미지 경로 변경 작업 중 Flash 메시지 섹션 삭제
```erb
<%# 수정 대상: 이미지 경로만 변경 %>
<img src="/undrew_hello_icon.webp" ...>

<%# 실수로 삭제된 코드 (15줄) %>
<% if flash[:alert].present? || flash[:notice].present? %>
  <%# ... Flash 메시지 렌더링 ... %>
<% end %>
```

**영향**:
- 로그인 실패 시 에러 메시지 미표시
- 보호된 페이지 리다이렉션 시 알림 미표시
- 사용자가 폼이 고장났다고 오해

**방지 체크리스트**:
| 단계 | 확인 사항 |
|------|----------|
| **편집 전** | 수정할 파일 전체 구조 파악 (Read 먼저) |
| **편집 중** | old_string에 최소한의 컨텍스트만 포함 |
| **편집 후** | 변경된 줄 수가 예상과 일치하는지 확인 |
| **검증** | 관련 테스트 실행 및 수동 확인 |

**안전한 편집 패턴**:
```ruby
# ✅ 최소 컨텍스트로 정확한 위치 지정
old_string: 'src="/image.png"'
new_string: 'src="/image.webp"'

# ❌ 위험 - 넓은 범위 지정 시 의도치 않은 삭제 가능
old_string: '<img src="/image.png" ...전체 태그...>'
```

**관련 파일**: `app/views/sessions/new.html.erb` (Flash 메시지 복원)

### Ruby 예외 처리: 명시적 클래스 지정 필수 (2026-01-21)

**문제**: `rescue => e`는 동작하지만 Ruby 스타일 가이드 위반

| 패턴 | 평가 | 설명 |
|------|------|------|
| `rescue => e` | ⚠️ 암묵적 | StandardError만 잡지만 명시성 부족 |
| `rescue StandardError => e` | ✅ 명시적 | 의도가 명확, 권장 패턴 |
| `rescue Exception => e` | ❌ 금지 | SystemExit, Interrupt까지 잡음 |

**수정 사례**:
```ruby
# ❌ 암묵적 (url_sanitizer.rb 수정 전)
rescue => e
  Rails.logger.warn "[UrlSanitizer] #{e.message}"
  false
end

# ✅ 명시적 (수정 후)
rescue StandardError => e
  Rails.logger.warn "[UrlSanitizer] #{e.message}"
  false
end
```

**이유**:
- `SystemExit`, `Interrupt` 등 시스템 예외는 잡으면 안 됨
- 코드 리뷰 시 의도 파악 용이
- Rubocop `Style/RescueStandardError` 규칙 준수

**관련 파일**: `app/services/url_sanitizer.rb`

### Magic Number 상수 추출 필수 (2026-01-21)

**문제**: 숫자 리터럴이 코드에 직접 나타나면 의미 파악 어려움

**수정 사례**:
```ruby
# ❌ Magic number (admin/users_controller.rb 수정 전)
@per_page = 20

# ✅ 상수 추출 (수정 후)
PER_PAGE = 20
# ...
@per_page = PER_PAGE
```

**상수 추출 기준**:
| 조건 | 상수화 여부 |
|------|------------|
| 비즈니스 의미가 있는 숫자 | ✅ 필수 |
| 2회 이상 사용되는 숫자 | ✅ 필수 |
| 변경 가능성 있는 설정값 | ✅ 필수 |
| 배열 인덱스 (0, 1) | ❌ 불필요 |
| 수학 상수 (100 for %) | ⚠️ 상황에 따라 |

**명명 규칙**:
- `SCREAMING_SNAKE_CASE` 사용
- 단위 포함: `MAX_FILE_SIZE_MB`, `TIMEOUT_SECONDS`
- 목적 명확: `PER_PAGE`, `MAX_RETRY_COUNT`

**관련 파일**: `app/controllers/admin/users_controller.rb`

---

## 🔄 지속적 개선 (Continuous Improvement)

> **원칙**: 같은 실수를 두 번 하지 않는다

### 문서화 트리거

다음 상황 발생 시 **반드시** 관련 문서 업데이트:

| 상황 | 문서화 대상 | 위치 |
|------|------------|------|
| CI 실패 수정 | 실패 패턴 + 해결책 | `rules/testing/ci-troubleshooting.md` |
| 프로젝트 특화 버그 | 금지 패턴 + 대안 | `CLAUDE.md` → 프로젝트 특화 규칙 |
| 아키텍처 결정 | 결정 배경 + 이유 | `ARCHITECTURE_DETAIL.md` |
| 보안 이슈 | 취약점 + 방어책 | `rules/backend/security.md` |

### 문서화 절차

```
1. 문제 발생 → 원인 분석
2. 해결책 적용 → 테스트 통과 확인
3. 패턴 일반화 → 재발 방지 규칙 도출
4. 문서 업데이트 → 커밋에 포함
```

### 작업 완료 체크리스트

모든 작업 완료 시 확인:
- [ ] 테스트 통과 (`bin/rails test`)
- [ ] Rubocop 통과 (`rubocop`)
- [ ] CI 통과 확인
- [ ] **새로운 패턴 발견 시 문서화** ← 필수!

### 세션 종료 시 점검

```
☐ 이번 세션에서 새로 발견한 패턴이 있는가?
  → 있다면 적절한 문서에 기록
☐ CI 실패를 수정했는가?
  → 있다면 ci-troubleshooting.md에 추가
☐ 프로젝트 특화 규칙을 위반했다가 수정했는가?
  → 있다면 CLAUDE.md 금지 패턴에 추가
```

---

## 참조 문서

### 핵심 문서 (새 세션 시 필수)
- 📋 **PROJECT_OVERVIEW.md** - 프로젝트 전체 구조, 기능 현황, Quick Reference
- 🏗️ **ARCHITECTURE_DETAIL.md** - 상세 아키텍처, 코딩 패턴, 데이터 흐름
- 🎨 **DESIGN_SYSTEM.md** - 디자인 토큰, 컴포넌트 라이브러리, UI 패턴

### 표준 규칙 (Agent OS 스타일)
- 📘 **standards/rails-backend.md** - Rails 백엔드 개발 규칙
- 🎨 **standards/tailwind-frontend.md** - Tailwind + Stimulus 프론트엔드 규칙
- 🧪 **standards/testing.md** - Minitest 테스트 표준

### 워크플로우 (Design OS 스타일)
- 🔄 **workflows/feature-development.md** - 기능 개발 단계별 프로세스

### 상세 문서
- **PRD.md** - 제품 요구사항 상세
- **API.md** - API 설계 문서
- **DATABASE.md** - ERD 및 스키마
- **TASKS.md** - 작업 목록 및 진행상황
- **PERFORMANCE.md** - 성능 최적화 가이드
- **SECURITY_GUIDE.md** - 보안 및 암호화 가이드 (회원 탈퇴 데이터 복호화)

### Claude Skills (17개)
- **[skills/README.md](skills/README.md)** - 전체 스킬 가이드 및 사용법

| 카테고리 | 스킬 | 트리거 키워드 |
|----------|------|--------------|
| **Backend** | rails-resource, test-gen, api-endpoint, background-job, service-object, query-object | "모델 생성", "테스트 추가", "API 만들어줘" |
| **Frontend** | ui-component, stimulus-controller, frontend-design | "컴포넌트 만들어줘", "인터랙션 추가", "예쁘게" |
| **DevOps** | logging-setup | "로깅 설정" |
| **Maintenance** | database-maintenance, security-audit, performance-check, code-review | "DB 체크", "보안 감사", "성능 분석" |
| **UI Workflow** | bridge | `/bridge`, `/bridge yolo` |
| **Rails Expert** | rails-dev | "Rails 아키텍처", "rails security" |
| **Documentation** | doc-sync | "문서 업데이트" |

---

## .claude 폴더 구조

```
.claude/
├── CLAUDE.md                    # 이 파일 (메인 컨텍스트)
├── PROJECT_OVERVIEW.md          # 프로젝트 전체 구조
├── ARCHITECTURE_DETAIL.md       # 상세 아키텍처
├── DESIGN_SYSTEM.md             # 디자인 시스템
│
├── standards/                   # 코드 품질 기준 (Agent OS 스타일)
│   ├── rails-backend.md         # Rails 백엔드 규칙
│   ├── tailwind-frontend.md     # Tailwind/Stimulus 규칙
│   └── testing.md               # 테스트 표준
│
├── workflows/                   # 작업 프로세스 (Design OS 스타일)
│   └── feature-development.md   # 기능 개발 5단계
│
├── references/                  # 📋 Plan Mode 참조 문서 (필수!)
│   └── cc-feature-implementer-main/
│       ├── SKILL.md             # Feature planner 가이드라인
│       └── plan-template.md     # Phase 기반 계획 템플릿
│
├── plans/                       # 계획 파일 저장소
│   └── [plan-name].md           # 진행 중인 계획 문서
│
├── rules/                       # Claude Code Rules (9개 파일, 1,152줄)
│   ├── backend/                 # Rails 백엔드 규칙
│   │   ├── rails-anti-patterns.md
│   │   ├── security.md
│   │   └── model-patterns.md
│   ├── frontend/                # 프론트엔드 규칙
│   │   ├── tailwind-dos-donts.md
│   │   ├── stimulus-patterns.md
│   │   └── accessibility.md
│   ├── testing/
│   │   ├── conventions.md       # 테스트 규칙
│   │   └── ci-troubleshooting.md # CI 실패 패턴 및 해결책
│   ├── infrastructure/critical-files.md  # 인프라 규칙
│   └── common/code-quality.md   # 공통 코드 품질
│
├── agents/                      # 프로젝트 특화 에이전트 (20개)
│   ├── README.md                # 에이전트 가이드
│   ├── domain/                  # 도메인 에이전트 (7개)
│   │   ├── chat-expert.md       # 채팅 시스템
│   │   ├── community-expert.md  # 커뮤니티 (게시글/댓글)
│   │   ├── ai-analysis-expert.md # AI 분석 시스템
│   │   ├── auth-expert.md       # 인증/OAuth
│   │   ├── search-expert.md     # 검색 시스템
│   │   ├── admin-expert.md      # 관리자 기능
│   │   └── ui-ux-expert.md      # UI/UX
│   ├── quality/                 # 품질 에이전트 (4개)
│   │   ├── security-expert.md   # 보안 분석
│   │   ├── code-review-expert.md # 코드 리뷰
│   │   ├── data-integrity-expert.md # 데이터 정합성
│   │   └── performance-expert.md # 성능 최적화
│   └── mobile/                  # 🆕 모바일 에이전트 (9개)
│       ├── README.md            # 모바일 에이전트 가이드
│       ├── core/                # 핵심 (hotwire-native, ios, android)
│       ├── feature/             # 기능 (bridge, auth, push, deeplink)
│       └── release/             # 배포 (app-store, play-store)
│
└── skills/                      # Claude Skills (17개)
    ├── README.md                # 스킬 가이드 및 사용법
    ├── rails-resource/          # 리소스 생성
    ├── test-gen/                # 테스트 생성
    ├── frontend-design/         # 고품질 디자인 (NEW)
    ├── rails-dev/               # Rails 전문가 (NEW)
    └── ... (13개 더)
```

### 문서 역할 구분

| 유형 | 목적 | 사용 시점 |
|------|------|----------|
| **Standards** | 코드 작성 시 준수할 규칙 | 코드 작성 중 참조 |
| **References** | Plan Mode 템플릿 및 가이드 | Plan Mode 진입 시 **반드시** 참조 |
| **Workflows** | 작업 단계별 프로세스 | 새 기능 개발 시작 시 |
| **Agents** | 도메인별 전문 지식 제공 | 트리거 키워드로 자동 활성화 |
| **Skills** | 자동화된 작업 수행 | 키워드로 자동 활성화 |

---

## Claude 작업 지침

### 코드 생성 시
1. **먼저 읽기**: 관련 파일 Read로 확인
2. **테스트 작성**: TDD 방식 권장
3. **마이그레이션**: 모델 변경 시 자동 생성
4. **라우팅**: RESTful 패턴 우선
5. **검증**: Rubocop, 테스트 실행

### 파일 수정 시
1. 기존 코드 스타일 유지
2. 관련 테스트 함께 수정
3. 변경사항 명확히 설명
4. 잠재적 사이드 이펙트 언급

### 문제 해결 시
1. 에러 로그 전체 확인
2. 관련 파일 컨텍스트 파악
3. Rails 가이드 참조
4. 여러 해결책 제시 (장단점)
