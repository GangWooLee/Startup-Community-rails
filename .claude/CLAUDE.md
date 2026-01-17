# Startup Community Platform - Claude Context

> **새 세션 시작 시 먼저 읽어야 할 문서:**
> - 📋 **PROJECT_OVERVIEW.md** - 프로젝트 전체 구조 (필수)
> - 🏗️ **ARCHITECTURE_DETAIL.md** - 상세 아키텍처 및 코딩 패턴
> - 🎨 **DESIGN_SYSTEM.md** - 디자인 토큰, 컴포넌트, UI 패턴
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
| **마지막 업데이트** | 2026-01-17 |
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
| 레이아웃에서 애니메이션 CSS 삭제 | 랜딩 페이지 깨짐 | **삭제 금지!** (CDN은 커스텀 CSS 미포함) |
| `mx-auto` (고정 너비 없이) | 중앙 정렬 안 됨 | `flex justify-center` 또는 고정 너비 추가 |
| 중복 HTML ID (Turbo Stream 타겟) | 잘못된 컨테이너에 렌더링 | 전역 컨테이너 하나만 사용 |

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

### ⚠️ 애니메이션 CSS 아키텍처 (중요!)
```
현재 구조:
- Tailwind CDN 사용 (application.html.erb Line 29)
- 커스텀 애니메이션은 인라인 <style> 태그에 정의 (Line 198-270)
- app/assets/tailwind/application.css는 백업용 (브라우저에 로드 안됨)

왜 이렇게?
- CDN은 커스텀 @keyframes를 모름
- 빌드된 CSS (app/assets/builds/tailwind.css)는 로드되지 않음
- 따라서 애니메이션은 반드시 레이아웃에 인라인으로 있어야 함

관련 파일:
- app/views/layouts/application.html.erb (애니메이션 정의)
- app/javascript/controllers/scroll_animation_controller.js
- app/views/onboarding/landing.html.erb (사용처)
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
├── rules/                       # 🆕 Claude Code Rules (9개 파일, 1,152줄)
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
