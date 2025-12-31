# Startup Community Platform

스타트업 커뮤니티를 위한 Rails 기반 웹 플랫폼

**비전**: "아이디어·사람·외주가 한 공간에서 연결되는 최초의 창업 커뮤니티"

> **브랜드명**: Undrew

## 📋 프로젝트 정보

| 항목 | 값 |
|------|-----|
| **버전** | MVP v0.8 |
| **Rails** | 8.1.1 |
| **Ruby** | 3.4.7 |
| **마지막 업데이트** | 2025-12-31 |
| **Database** | SQLite3 (개발), PostgreSQL (프로덕션) |
| **Frontend** | Hotwire (Turbo + Stimulus) + Tailwind CSS v4 |

---

## 📦 주요 기능

| 기능 | 완성도 | 상태 | 설명 |
|------|--------|------|------|
| 커뮤니티 | 95% | ✅ 완성 | 게시글 CRUD, 댓글, 좋아요, 이미지, 스크랩 |
| 채팅 | 90% | ✅ 완성 | 실시간 1:1 채팅, Solid Cable, Turbo Streams |
| 프로필/OAuth | 85% | ✅ 완성 | Google, GitHub 소셜 로그인 |
| AI 온보딩 | 85% | ✅ 완성 | 멀티에이전트 아이디어 분석, Gemini 3 Flash |
| 알림 시스템 | 70% | ✅ 기본 완성 | 댓글, 좋아요, 채팅 알림 |
| 검색 | 80% | ✅ 완성 | 실시간 검색, 탭 필터링 |
| 외주 | 50% | ⚠️ 진행중 | 구인/구직, Post 모델 통합 중 |

---

## 🚀 시작하기

### 필수 요구사항

- Ruby 3.4.7
- Rails 8.1.1
- SQLite3
- Node.js (Tailwind CSS 빌드용)

### 설치 및 실행

```bash
# 저장소 클론
git clone https://github.com/GangWooLee/Startup-Community-rails.git
cd Startup-Community-rails

# 의존성 설치
bundle install

# 데이터베이스 설정
rails db:create db:migrate db:seed

# 개발 서버 실행
rails server
```

브라우저에서 `http://localhost:3000` 접속

### 테스트 계정

| 계정 | 이메일 | 비밀번호 |
|------|--------|----------|
| 관리자 | admin@startup.com | password |
| 사용자1~10 | user0@startup.com ~ user9@startup.com | password |

---

## 🪟 Windows 환경 설정 (WSL2)

Windows에서 개발하려면 WSL2 + Ubuntu를 사용합니다.

### 1. WSL2 설치

PowerShell을 **관리자 권한**으로 실행:

```powershell
wsl --install
```

설치 후 **컴퓨터 재시작** → Microsoft Store에서 **Ubuntu** 설치

### 2. Rails 환경 설정

Ubuntu 터미널에서 Rails 설치 가이드 참조:
**https://rails.insomenia.com/install_ruby_on_rails**

### 3. 문제 해결

```bash
# bundle install 에러 시
sudo apt-get update
sudo apt-get install -y build-essential libssl-dev libreadline-dev zlib1g-dev
bundle install

# 데이터베이스 에러 시
rails db:drop db:create db:migrate db:seed

# 서버가 이미 실행 중일 때
kill -9 $(lsof -t -i:3000)
rails server
```

---

## 🏗️ 프로젝트 구조

```
app/
├── controllers/          # 19개 컨트롤러
├── models/               # 15개 모델
├── views/                # 20개 뷰 디렉토리
│   ├── layouts/          # 레이아웃
│   ├── shared/           # 공유 컴포넌트, 아이콘
│   ├── components/ui/    # shadcn UI 컴포넌트
│   ├── posts/            # 게시글
│   ├── chat_rooms/       # 채팅
│   ├── search/           # 검색
│   └── onboarding/       # AI 온보딩
├── javascript/
│   └── controllers/      # 33개 Stimulus 컨트롤러
├── services/
│   ├── ai/               # AI 멀티에이전트 시스템
│   │   ├── agents/       # 5개 전문 에이전트
│   │   ├── orchestrators/# 에이전트 오케스트레이터
│   │   └── tools/        # LangchainRB 도구
│   └── expert_matcher.rb # 전문가 매칭
└── helpers/              # 뷰 헬퍼

config/
├── routes.rb             # 라우팅 정의
├── credentials.yml.enc   # 암호화된 API 키
└── initializers/
    ├── langchain.rb      # AI 설정
    └── omniauth.rb       # OAuth 설정

db/
├── migrate/              # 30개 마이그레이션
└── schema.rb             # 현재 스키마

.claude/                  # Claude AI 문서 (14개 Skills 포함)
├── CLAUDE.md             # 메인 컨텍스트 ⭐
├── PROJECT_OVERVIEW.md   # 프로젝트 개요 ⭐
├── ARCHITECTURE_DETAIL.md # 상세 아키텍처 ⭐
├── PRD.md                # 제품 요구사항
├── DATABASE.md           # ERD 및 스키마
├── API.md                # API 설계
├── PERFORMANCE.md        # 성능 가이드
└── skills/               # 14개 Claude Skills
```

---

## 🛠️ 기술 스택

### Backend
- **Rails 8.1.1** + Ruby 3.4.7
- **SQLite3** (개발) / **PostgreSQL** (프로덕션)
- **Solid Queue** - 백그라운드 작업 (Redis 불필요)
- **Solid Cache** - 캐싱
- **Solid Cable** - WebSocket (실시간 채팅)
- **Active Storage** - 이미지 업로드

### Frontend
- **Hotwire** (Turbo + Stimulus) - SPA 같은 UX
- **Tailwind CSS v4** + **shadcn-ui** - 디자인 시스템
- **Import Maps** - ES 모듈 (번들러 불필요)

### AI
- **LangchainRB** - AI 에이전트 프레임워크
- **Google Gemini 3 Flash** - LLM (멀티에이전트 아이디어 분석)
  - 5개 전문 에이전트: Summary, TargetUser, MarketAnalysis, Strategy, Scoring
  - Gemini Grounding - 실시간 웹 검색
  - 에이전트별 최적화 모델 (gemini-3-flash-preview, gemini-2.0-flash-lite)

### Auth
- **has_secure_password** - 세션 기반 인증
- **OmniAuth** - OAuth (Google, GitHub)

### DevOps
- **Docker** + **Kamal** - 배포
- **Rack Attack** - Rate Limiting

---

## 🔗 주요 라우팅

### 인증
```
POST   /login              → 로그인
DELETE /logout             → 로그아웃
GET    /signup             → 회원가입
GET    /auth/:provider/callback → OAuth 콜백
```

### 커뮤니티
```
GET    /community          → 게시글 목록 (메인)
GET    /posts/:id          → 게시글 상세
POST   /posts/:id/like     → 좋아요 토글
POST   /posts/:id/bookmark → 스크랩 토글
```

### 채팅
```
GET    /chat_rooms         → 채팅 목록
GET    /chat_rooms/:id     → 채팅방
POST   /chat_rooms/:id/messages → 메시지 전송
```

### AI 온보딩
```
GET    /                   → 랜딩 페이지
GET    /ai/input           → 아이디어 입력
GET    /ai/result          → 분석 결과
```

---

## 🧪 테스트

```bash
# 전체 테스트 실행
rails test

# 모델 테스트만
rails test:models

# 컨트롤러 테스트만
rails test:controllers

# 시스템 테스트 (E2E)
rails test:system

# 코드 품질 검사
rubocop
brakeman
```

---

## 📝 최근 업데이트

| 날짜 | 내용 |
|------|------|
| 2025-12-31 | Gemini 3 Flash 모델 업그레이드 (AI 분석 정확도 향상) |
| 2025-12-31 | Undrew 브랜딩 적용 (로고, 헤더 통일) |
| 2025-12-30 | 회원 탈퇴 시스템 구현 (암호화 보관, 5년 후 자동 파기) |
| 2025-12-30 | GA4 (Google Analytics 4) 연동 |
| 2025-12-27 | AI 멀티에이전트 시스템 완성 (5개 전문 에이전트) |
| 2025-12-27 | Gemini Grounding 실시간 웹 검색 연동 |
| 2025-12-27 | Admin 패널 추가 (사용자/채팅방 관리) |
| 2025-12-26 | 검색 페이지 UTF-8 인코딩 오류 수정 |
| 2025-12-26 | 검색 결과 클릭 문제 해결 (onmousedown 사용) |
| 2025-12-26 | render_avatar 메서드명 충돌 해결 |
| 2025-12-26 | .env → Rails credentials 전환 |
| 2025-12-25 | AI 아이디어 분석 Gemini API 연동 |
| 2025-12-24 | 채팅 기능 완성 (실시간 메시지, 읽음 표시) |
| 2025-12-23 | OAuth 소셜 로그인 추가 (Google, GitHub) |

---

## 🎯 현재 진행 중인 작업

1. ~~**AI 아이디어 분석 기능 안정화**~~ ✅ 완료 (85%)
2. **외주 시스템 Post 모델 통합** (50% → 80%)
3. **N+1 쿼리 최적화**
4. **프로덕션 배포 준비**

---

## 📚 문서

상세한 프로젝트 문서는 `.claude/` 디렉토리에서 확인하세요:

| 문서 | 설명 |
|------|------|
| [CLAUDE.md](.claude/CLAUDE.md) | 메인 프로젝트 컨텍스트 |
| [PROJECT_OVERVIEW.md](.claude/PROJECT_OVERVIEW.md) | 프로젝트 전체 구조 |
| [ARCHITECTURE_DETAIL.md](.claude/ARCHITECTURE_DETAIL.md) | 상세 아키텍처 및 패턴 |
| [PRD.md](.claude/PRD.md) | 제품 요구사항 |
| [DATABASE.md](.claude/DATABASE.md) | ERD 및 스키마 |
| [API.md](.claude/API.md) | API 라우팅 설계 |
| [PERFORMANCE.md](.claude/PERFORMANCE.md) | 성능 최적화 가이드 |

### Claude Skills (14개)

| 카테고리 | 스킬 |
|----------|------|
| Backend | rails-resource, test-gen, api-endpoint, background-job, service-object, query-object |
| DevOps | logging-setup |
| Maintenance | database-maintenance, security-audit, performance-check |
| Quality | code-review |
| Frontend | ui-component, stimulus-controller |
| Documentation | doc-sync |

---

## 🤝 기여하기

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📝 라이선스

This project is licensed under the MIT License

## 👥 팀

- [GangWooLee](https://github.com/GangWooLee)

---

**Built with ❤️ using Rails 8.1**
