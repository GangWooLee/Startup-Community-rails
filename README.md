# Startup Community Platform

스타트업 커뮤니티를 위한 Rails 기반 웹 플랫폼

**비전**: "아이디어·사람·외주가 한 공간에서 연결되는 최초의 창업 커뮤니티"

## 📋 프로젝트 정보

| 항목 | 값 |
|------|-----|
| **버전** | MVP v0.8 |
| **Rails** | 8.1.1 |
| **Ruby** | 3.4.7 |
| **Database** | SQLite3 (개발), PostgreSQL (프로덕션) |
| **Frontend** | Hotwire (Turbo + Stimulus) + Tailwind CSS |

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

## 📦 주요 기능

| 기능 | 완성도 | 상태 |
|------|--------|------|
| 커뮤니티 (게시글/댓글/좋아요) | 95% | ✅ 완성 |
| 채팅 (실시간 1:1) | 90% | ✅ 완성 |
| 프로필/OAuth | 85% | ✅ 완성 |
| AI 온보딩 | 70% | 🔄 진행중 |
| 알림 시스템 | 70% | ✅ 기본 완성 |
| 검색 | 80% | ✅ 완성 |
| 외주 (구인/구직) | 50% | ⚠️ 진행중 |

---

## 🧪 테스트

```bash
# 전체 테스트 실행
rails test

# 시스템 테스트 실행
rails test:system

# 코드 품질 검사
rubocop
brakeman
```

---

## 🏗️ 프로젝트 구조

```
app/
├── controllers/     # 19개 컨트롤러
├── models/          # 15개 모델
├── views/           # ERB 템플릿
├── javascript/      # 33개 Stimulus 컨트롤러
├── services/ai/     # AI 에이전트 (LangChain + Gemini)
└── helpers/         # 뷰 헬퍼

.claude/             # Claude AI 문서
├── CLAUDE.md        # 메인 컨텍스트 ⭐
├── PROJECT_OVERVIEW.md  # 프로젝트 개요 ⭐
├── ARCHITECTURE_DETAIL.md  # 상세 아키텍처 ⭐
├── PRD.md           # 제품 요구사항
├── DATABASE.md      # ERD 및 스키마
├── API.md           # API 설계
└── PERFORMANCE.md   # 성능 가이드
```

---

## 🛠️ 기술 스택

### Backend
- Rails 8.1.1 + Ruby 3.4.7
- Solid Queue/Cache/Cable (Redis 불필요)
- Active Storage (이미지 업로드)

### Frontend
- Hotwire (Turbo + Stimulus)
- Tailwind CSS v4 + shadcn-ui
- Import Maps (번들러 불필요)

### AI
- LangchainRB + Google Gemini API

### Auth
- has_secure_password + OAuth (Google, GitHub)

### Deployment
- Docker + Kamal

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
