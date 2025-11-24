# Startup Community Platform

스타트업 커뮤니티를 위한 Rails 기반 웹 플랫폼

## 📋 프로젝트 정보

- **Rails Version**: 8.1.1
- **Ruby Version**: 3.4.7
- **Database**: SQLite3 (개발), PostgreSQL (프로덕션)
- **Frontend**: Hotwire (Turbo + Stimulus)

## 🚀 시작하기

### 필수 요구사항

- Ruby 3.4.7
- Rails 8.1.1
- SQLite3
- Node.js (for asset pipeline)

### 설치 및 실행

```bash
# 저장소 클론
git clone https://github.com/GangWooLee/Startup-Community-rails.git
cd Startup-Community-rails

# 의존성 설치
bundle install

# 데이터베이스 설정
rails db:create
rails db:migrate
rails db:seed

# 개발 서버 실행
rails server
```

브라우저에서 `http://localhost:3000` 접속

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

## 📦 주요 기능

- [ ] 사용자 인증 (회원가입/로그인)
- [ ] 게시글 CRUD
- [ ] 댓글 시스템
- [ ] 실시간 알림
- [ ] 검색 및 필터링

## 🏗️ 프로젝트 구조

```
app/
├── controllers/  # MVC Controllers
├── models/       # ActiveRecord Models
├── views/        # ERB Templates
├── javascript/   # Stimulus Controllers
└── assets/       # CSS, Images

.claude/          # Claude AI 문서
├── CLAUDE.md     # 프로젝트 컨텍스트
├── PRD.md        # 제품 요구사항
├── ARCHITECTURE.md
├── DATABASE.md
└── API.md
```

## 🛠️ 기술 스택

### Backend
- Rails 8.1.1
- Puma (Web Server)
- Solid Cache, Queue, Cable

### Frontend
- Hotwire (Turbo + Stimulus)
- Propshaft (Asset Pipeline)
- Import Maps

### Database
- SQLite3 (Development)
- PostgreSQL (Production)

### Deployment
- Docker
- Kamal

## 📚 문서

상세한 프로젝트 문서는 `.claude/` 디렉토리에서 확인하세요:

- [프로젝트 가이드](.claude/CLAUDE.md)
- [제품 요구사항](.claude/PRD.md)
- [아키텍처 설계](.claude/ARCHITECTURE.md)
- [데이터베이스 설계](.claude/DATABASE.md)
- [API 문서](.claude/API.md)

## 🤝 기여하기

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 라이선스

This project is licensed under the MIT License

## 👥 팀

- [GangWooLee](https://github.com/GangWooLee)

---

**Built with ❤️ using Rails 8.1**
