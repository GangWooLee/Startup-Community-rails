# Project Tasks & Progress

## 문서 정보
- **프로젝트**: Startup Community Platform
- **업데이트**: 2025-11-25

---

## 작업 상태

```
📋 Todo       - 계획됨
🔄 In Progress - 진행 중
✅ Done       - 완료
⏸️ On Hold    - 보류
❌ Cancelled  - 취소
```

---

## MVP Phase 1 (Week 1-4)

### Week 1: 프로젝트 셋업 & 기본 구조

#### 환경 설정
- [x] Rails 프로젝트 생성
- [x] Git 저장소 초기화
- [ ] 📋 Ruby/Rails 환경 설치 (WSL)
- [ ] 📋 개발 도구 설정 (VS Code, extensions)
- [ ] 📋 Docker 환경 구성 (선택)

#### 기본 설정
- [ ] 📋 Database 설정 (SQLite → PostgreSQL 마이그레이션 계획)
- [ ] 📋 Rubocop 설정 (.rubocop.yml)
- [ ] 📋 Testing 프레임워크 설정
- [ ] 📋 CI/CD 파이프라인 구성 (.github/workflows)

#### 문서화
- [x] ✅ .claude/ 디렉토리 구조 생성
- [x] ✅ CLAUDE.md 작성
- [x] ✅ PRD.md 템플릿 생성
- [x] ✅ ARCHITECTURE.md 작성
- [x] ✅ DATABASE.md 작성
- [x] ✅ API.md 작성
- [ ] 📋 README.md 업데이트

---

### Week 2: 인증 & 사용자 관리

#### 사용자 모델
- [ ] 📋 User 모델 생성
- [ ] 📋 has_secure_password 설정
- [ ] 📋 User 유효성 검증 (email, password)
- [ ] 📋 User 테스트 작성

#### 인증 시스템
- [ ] 📋 SessionsController 생성
- [ ] 📋 회원가입 (signup) 구현
- [ ] 📋 로그인/로그아웃 구현
- [ ] 📋 세션 관리 헬퍼 메서드
- [ ] 📋 인증 테스트 작성

#### UI/UX
- [ ] 📋 회원가입 폼
- [ ] 📋 로그인 폼
- [ ] 📋 플래시 메시지 (Turbo)
- [ ] 📋 반응형 디자인 (모바일)

---

### Week 3: 핵심 기능 #1

#### [도메인 모델 - 프로젝트에 맞게 수정]
- [ ] 📋 Post 모델 생성
- [ ] 📋 User ↔ Post 관계 설정
- [ ] 📋 모델 유효성 검증
- [ ] 📋 모델 테스트 작성

#### CRUD 기능
- [ ] 📋 PostsController 생성
- [ ] 📋 게시글 목록 (index)
- [ ] 📋 게시글 상세 (show)
- [ ] 📋 게시글 작성 (new/create)
- [ ] 📋 게시글 수정 (edit/update)
- [ ] 📋 게시글 삭제 (destroy)
- [ ] 📋 컨트롤러 테스트

#### UI 구현
- [ ] 📋 목록 페이지 (Turbo Frames)
- [ ] 📋 상세 페이지
- [ ] 📋 작성/수정 폼
- [ ] 📋 삭제 확인 모달

---

### Week 4: 핵심 기능 #2 & 배포 준비

#### 추가 기능
- [ ] 📋 페이지네이션 (Kaminari/Pagy)
- [ ] 📋 검색 기능 (LIKE 쿼리)
- [ ] 📋 정렬 기능 (최신순, 인기순)
- [ ] 📋 권한 관리 (admin, user)

#### 성능 최적화
- [ ] 📋 N+1 쿼리 제거 (Bullet gem)
- [ ] 📋 DB 인덱스 추가
- [ ] 📋 Fragment 캐싱
- [ ] 📋 이미지 최적화 (ImageMagick)

#### 배포 준비
- [ ] 📋 환경변수 설정 (credentials)
- [ ] 📋 프로덕션 DB 설정 (PostgreSQL)
- [ ] 📋 Asset precompile 확인
- [ ] 📋 에러 모니터링 (Sentry/Rollbar)

#### 테스팅
- [ ] 📋 System 테스트 (E2E)
- [ ] 📋 테스트 커버리지 확인
- [ ] 📋 보안 스캔 (Brakeman)

---

## Phase 2: Enhancement (Week 5-8)

### Week 5-6: 고급 기능
- [ ] 📋 댓글 시스템
- [ ] 📋 좋아요/북마크
- [ ] 📋 알림 시스템 (Action Cable)
- [ ] 📋 파일 업로드 (Active Storage)

### Week 7-8: UX 개선
- [ ] 📋 무한 스크롤 (Turbo)
- [ ] 📋 실시간 업데이트 (Turbo Streams)
- [ ] 📋 다크모드
- [ ] 📋 접근성 개선 (ARIA)

---

## Phase 3: Growth (Week 9-12)

### Week 9-10: 분석 & 최적화
- [ ] 📋 Google Analytics 연동
- [ ] 📋 성능 모니터링 (APM)
- [ ] 📋 SEO 최적화
- [ ] 📋 로그 분석

### Week 11-12: 확장
- [ ] 📋 API 문서화 (Swagger)
- [ ] 📋 Mobile App 준비 (API)
- [ ] 📋 Admin 대시보드
- [ ] 📋 데이터 백업 자동화

---

## Backlog (우선순위 낮음)

### 기능
- [ ] ⏸️ 소셜 로그인 (OAuth)
- [ ] ⏸️ 이메일 인증
- [ ] ⏸️ 비밀번호 재설정
- [ ] ⏸️ 2FA (Two-Factor Auth)
- [ ] ⏸️ 다국어 지원 (i18n)

### 인프라
- [ ] ⏸️ Redis 캐시
- [ ] ⏸️ CDN 설정
- [ ] ⏸️ Load Balancer
- [ ] ⏸️ Auto Scaling

---

## 일일 작업 로그

### 2025-11-25
**작업 내용**:
- ✅ .claude/ 디렉토리 구조 생성
- ✅ 프로젝트 문서 작성 (CLAUDE.md, PRD.md, etc.)

**다음 작업**:
- Ruby/Rails 환경 설정
- User 모델 설계 시작

**메모**:
- PRD 상세 내용 작성 필요
- ERD 다이어그램 도구 선정 (draw.io, dbdiagram.io)

---

## 참고 링크

### 프로젝트 관리
- GitHub Issues: [저장소 URL]
- Trello/Notion: [보드 URL]

### 개발 환경
- Staging: [URL]
- Production: [URL]

### 문서
- API Docs: [URL]
- Figma: [URL]

---

## 팀 노트

### 결정 사항
- [ ] 날짜: 내용

### 기술 스택 변경
- [ ] 날짜: 변경 내용 및 이유

### 회고
- [ ] 날짜: 배운 점, 개선할 점
