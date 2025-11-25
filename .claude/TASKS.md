# Project Tasks & Progress

## 문서 정보
- **프로젝트**: Startup Community Platform
- **업데이트**: 2025-11-26

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

## MVP Phase 1: 커뮤니티 + 프로필 + 외주 기본 흐름 (4주)

### Week 1: 프로젝트 셋업 & 인증 시스템

#### 프로젝트 초기화
- [x] ✅ Rails 프로젝트 생성
- [x] ✅ Git 저장소 초기화
- [x] ✅ .claude/ 디렉토리 문서 작성
- [ ] 📋 README.md 업데이트

#### 개발 환경 설정
- [ ] 📋 Gemfile 정리 (필요한 gem 추가)
  - pagy (페이지네이션)
  - rubocop-rails-omakase (린팅)
  - annotate (모델 주석)
- [ ] 📋 Rubocop 설정
- [ ] 📋 Git hooks 설정 (pre-commit)

#### 사용자 인증 (Authentication)
- [ ] 📋 User 모델 생성
  ```bash
  rails g model User email:string password_digest:string name:string role_title:string bio:text avatar_url:string last_sign_in_at:datetime
  ```
- [ ] 📋 User 모델 검증 및 관계 설정
- [ ] 📋 User 모델 테스트 작성
- [ ] 📋 SessionsController 생성 (로그인/로그아웃)
- [ ] 📋 UsersController 생성 (회원가입)
- [ ] 📋 인증 헬퍼 메서드 (ApplicationController)
- [ ] 📋 회원가입 뷰 작성
- [ ] 📋 로그인 뷰 작성
- [ ] 📋 인증 시스템 테스트

#### 기본 레이아웃
- [ ] 📋 application.html.erb 레이아웃 구성
- [ ] 📋 내비게이션 바 (로그인/로그아웃 상태별)
- [ ] 📋 Flash 메시지 표시
- [ ] 📋 기본 CSS 스타일 (또는 Tailwind CSS 도입)

**Week 1 목표**: 사용자가 회원가입/로그인/로그아웃을 할 수 있다.

---

### Week 2: 커뮤니티 게시판 (Posts)

#### Post 모델
- [ ] 📋 Post 모델 생성
  ```bash
  rails g model Post user:references title:string content:text status:integer views_count:integer likes_count:integer comments_count:integer
  ```
- [ ] 📋 Post 모델 검증 및 관계 설정
- [ ] 📋 Post 모델 scope 추가 (published, recent, popular)
- [ ] 📋 Post 모델 테스트 작성

#### Comment 모델
- [ ] 📋 Comment 모델 생성
  ```bash
  rails g model Comment post:references user:references content:text
  ```
- [ ] 📋 Comment 모델 검증 및 관계 설정
- [ ] 📋 counter_cache 설정 (Post의 comments_count)
- [ ] 📋 Comment 모델 테스트 작성

#### Like 모델 (Polymorphic)
- [ ] 📋 Like 모델 생성
  ```bash
  rails g model Like user:references likeable:references{polymorphic}
  ```
- [ ] 📋 Like 모델 검증 및 관계 설정
- [ ] 📋 counter_cache 설정
- [ ] 📋 Like 모델 테스트 작성

#### PostsController
- [ ] 📋 PostsController 생성 (CRUD)
- [ ] 📋 index 액션 (페이지네이션 적용)
- [ ] 📋 show 액션 (조회수 증가)
- [ ] 📋 new/create 액션 (작성 권한 확인)
- [ ] 📋 edit/update 액션 (수정 권한 확인)
- [ ] 📋 destroy 액션 (삭제 권한 확인)
- [ ] 📋 컨트롤러 테스트 작성

#### CommentsController
- [ ] 📋 CommentsController 생성
- [ ] 📋 create 액션 (Turbo Stream 응답)
- [ ] 📋 destroy 액션 (Turbo Stream 응답)
- [ ] 📋 컨트롤러 테스트 작성

#### LikesController
- [ ] 📋 LikesController 생성
- [ ] 📋 create 액션 (Turbo Stream 응답)
- [ ] 📋 destroy 액션 (Turbo Stream 응답)
- [ ] 📋 컨트롤러 테스트 작성

#### 뷰 작성
- [ ] 📋 posts/index.html.erb (게시글 목록)
- [ ] 📋 posts/show.html.erb (게시글 상세 + 댓글)
- [ ] 📋 posts/new.html.erb (게시글 작성 폼)
- [ ] 📋 posts/edit.html.erb (게시글 수정 폼)
- [ ] 📋 posts/_post.html.erb (게시글 카드 partial)
- [ ] 📋 comments/_comment.html.erb (댓글 partial)
- [ ] 📋 comments/_form.html.erb (댓글 폼 partial)
- [ ] 📋 Turbo Stream 뷰 작성 (댓글, 좋아요)

**Week 2 목표**: 사용자가 게시글을 작성하고, 댓글과 좋아요를 달 수 있다.

---

### Week 3: 프로필 & 외주 기능

#### 프로필 페이지 (Profiles)
- [ ] 📋 ProfilesController 생성 (UsersController alias)
- [ ] 📋 show 액션 (기본: Posts 탭)
- [ ] 📋 posts, job_posts, talent_listings 액션 (탭별 데이터)
- [ ] 📋 edit/update 액션 (프로필 수정)
- [ ] 📋 profiles/show.html.erb (탭 UI)
- [ ] 📋 profiles/edit.html.erb (프로필 수정 폼)
- [ ] 📋 프로필 페이지 테스트

#### JobPost 모델
- [ ] 📋 JobPost 모델 생성
  ```bash
  rails g model JobPost user:references title:string description:text category:integer project_type:integer budget:string status:integer views_count:integer
  ```
- [ ] 📋 JobPost 모델 검증 및 관계 설정
- [ ] 📋 JobPost enum 설정 (category, project_type, status)
- [ ] 📋 JobPost 모델 scope 추가
- [ ] 📋 JobPost 모델 테스트 작성

#### TalentListing 모델
- [ ] 📋 TalentListing 모델 생성
  ```bash
  rails g model TalentListing user:references title:string description:text category:integer project_type:integer rate:string status:integer views_count:integer
  ```
- [ ] 📋 TalentListing 모델 검증 및 관계 설정
- [ ] 📋 TalentListing enum 설정
- [ ] 📋 TalentListing 모델 테스트 작성

#### JobPostsController
- [ ] 📋 JobPostsController 생성 (CRUD)
- [ ] 📋 index 액션 (카테고리/타입 필터링)
- [ ] 📋 show 액션
- [ ] 📋 new/create/edit/update/destroy 액션
- [ ] 📋 job_posts/index.html.erb
- [ ] 📋 job_posts/show.html.erb
- [ ] 📋 job_posts/new.html.erb & edit.html.erb
- [ ] 📋 job_posts/_job_post.html.erb (카드 partial)
- [ ] 📋 컨트롤러 테스트

#### TalentListingsController
- [ ] 📋 TalentListingsController 생성 (CRUD)
- [ ] 📋 index 액션 (카테고리/타입 필터링)
- [ ] 📋 show 액션
- [ ] 📋 new/create/edit/update/destroy 액션
- [ ] 📋 talent_listings/index.html.erb
- [ ] 📋 talent_listings/show.html.erb
- [ ] 📋 talent_listings/_talent_listing.html.erb (카드 partial)
- [ ] 📋 컨트롤러 테스트

**Week 3 목표**: 프로필 페이지에서 사용자의 활동을 3개 탭으로 확인할 수 있고, 구인/구직 글을 작성할 수 있다.

---

### Week 4: 마이페이지 & 북마크 & 통합 테스트

#### Bookmark 모델 (Polymorphic)
- [ ] 📋 Bookmark 모델 생성
  ```bash
  rails g model Bookmark user:references bookmarkable:references{polymorphic}
  ```
- [ ] 📋 Bookmark 모델 검증 및 관계 설정
- [ ] 📋 Bookmark 모델 테스트 작성

#### BookmarksController
- [ ] 📋 BookmarksController 생성
- [ ] 📋 create 액션 (Turbo Stream)
- [ ] 📋 destroy 액션 (Turbo Stream)
- [ ] 📋 북마크 버튼 partial 작성
- [ ] 📋 컨트롤러 테스트

#### My Page (namespace :my)
- [ ] 📋 My::ProfilesController (프로필 수정)
- [ ] 📋 My::BookmarksController (내 스크랩)
- [ ] 📋 My::PostsController (내 게시글)
- [ ] 📋 My::JobPostsController (내 구인 글)
- [ ] 📋 My::TalentListingsController (내 구직 글)
- [ ] 📋 my/bookmarks/index.html.erb
- [ ] 📋 my/posts/index.html.erb
- [ ] 📋 마이페이지 내비게이션 구성
- [ ] 📋 마이페이지 테스트

#### Seed 데이터
- [ ] 📋 db/seeds.rb 작성 (테스트 데이터 생성)
- [ ] 📋 샘플 사용자 10명
- [ ] 📋 샘플 게시글 30개
- [ ] 📋 샘플 댓글 50개
- [ ] 📋 샘플 구인/구직 글 각 15개
- [ ] 📋 샘플 좋아요 & 북마크
- [ ] 📋 Seed 실행 확인

#### 통합 테스트 & 리팩토링
- [ ] 📋 System 테스트 작성 (E2E)
  - 회원가입 → 로그인 → 게시글 작성 → 댓글 → 좋아요
  - 프로필 페이지 탭 전환
  - 구인 글 작성 → 북마크
- [ ] 📋 N+1 쿼리 제거 (Bullet gem 사용)
- [ ] 📋 DB 인덱스 최적화 확인
- [ ] 📋 Rubocop 실행 및 수정
- [ ] 📋 테스트 커버리지 확인
- [ ] 📋 보안 스캔 (Brakeman)

#### 배포 준비
- [ ] 📋 프로덕션 환경 설정 (database.yml, credentials)
- [ ] 📋 환경변수 설정
- [ ] 📋 Kamal 배포 설정 (선택)
- [ ] 📋 README.md 업데이트 (설치, 실행 방법)

**Week 4 목표**: MVP 완성 - 커뮤니티 활동 → 프로필 → 외주 공고 흐름이 자연스럽게 연결된다.

---

## MVP 체크리스트

### 핵심 기능 (Must Have)
- [ ] 회원가입/로그인/로그아웃
- [ ] 게시글 CRUD (커뮤니티)
- [ ] 댓글 CRUD
- [ ] 좋아요 기능
- [ ] 프로필 페이지 (3개 탭: Posts, Job Posts, Talent Listings)
- [ ] 구인 공고 CRUD
- [ ] 구직 정보 CRUD
- [ ] 북마크/스크랩 기능
- [ ] 마이페이지 (프로필 수정, 스크랩 관리)

### 비기능 요구사항
- [ ] 반응형 디자인 (모바일 최적화)
- [ ] 페이지 로딩 속도 < 2초
- [ ] N+1 쿼리 제거
- [ ] 테스트 커버리지 > 70%
- [ ] 보안 (Strong Parameters, CSRF, XSS 방지)

---

## Phase 2: Enhancement (향후 계획)

### 기능 개선
- [ ] ⏸️ 검색 기능 (게시글, 사용자, 구인/구직)
- [ ] ⏸️ 필터링 고도화 (다중 필터, 정렬 옵션)
- [ ] ⏸️ 태그 시스템 (acts-as-taggable-on)
- [ ] ⏸️ 알림 시스템 (댓글, 좋아요 알림)
- [ ] ⏸️ 실시간 채팅 (Action Cable)
- [ ] ⏸️ 이메일 인증
- [ ] ⏸️ 비밀번호 재설정
- [ ] ⏸️ 소셜 로그인 (OAuth - Google, GitHub)

### 외주 기능 강화
- [ ] ⏸️ 지원/문의 기능 (JobPost에 지원하기)
- [ ] ⏸️ 매칭 알고리즘 (AI 기반 추천)
- [ ] ⏸️ 평판 시스템 (리뷰, 평점)
- [ ] ⏸️ 포트폴리오 첨부 (Active Storage + S3)
- [ ] ⏸️ 결제/정산 기능 (Stripe/토스페이먼츠)

### UX 개선
- [ ] ⏸️ 무한 스크롤 (Turbo Frames)
- [ ] ⏸️ 실시간 업데이트 (Turbo Streams)
- [ ] ⏸️ 다크모드
- [ ] ⏸️ 접근성 개선 (ARIA, 키보드 내비게이션)
- [ ] ⏸️ 온보딩 튜토리얼

### 인프라 & DevOps
- [ ] ⏸️ PostgreSQL 전환
- [ ] ⏸️ Redis 캐시
- [ ] ⏸️ CDN 설정 (CloudFlare)
- [ ] ⏸️ CI/CD 파이프라인 (GitHub Actions)
- [ ] ⏸️ 모니터링 (New Relic, Sentry)
- [ ] ⏸️ 백업 자동화

### 관리자 기능
- [ ] ⏸️ Admin 대시보드 (사용자, 게시글 관리)
- [ ] ⏸️ 신고 시스템 (스팸, 부적절한 콘텐츠)
- [ ] ⏸️ 통계 대시보드 (가입자, 활동 지표)

---

## 일일 작업 로그

### 2025-11-26
**작업 내용**:
- ✅ one-pager.md 기반 .claude/ 디렉토리 문서 작성
- ✅ CLAUDE.md - 프로젝트 비전 및 컨텍스트
- ✅ PRD.md - 상세 제품 요구사항
- ✅ DATABASE.md - ERD 및 스키마 설계
- ✅ API.md - RESTful 라우팅 및 컨트롤러 설계
- ✅ ARCHITECTURE.md - 시스템 아키텍처
- ✅ TASKS.md - MVP 작업 목록

**다음 작업**:
- User 모델 생성 및 인증 시스템 구축
- 기본 레이아웃 및 내비게이션 구성

**메모**:
- Rails 8.1 + Hotwire 환경 활용
- Pagy로 페이지네이션 구현
- Turbo Streams로 실시간 업데이트
- 모바일 우선 반응형 디자인

---

## 참고 링크

### 프로젝트 문서
- **One-pager**: `/one-pager.md` - 제품 비전 및 핵심 기능
- **PRD**: `.claude/PRD.md` - 제품 요구사항
- **DATABASE**: `.claude/DATABASE.md` - ERD 및 스키마
- **API**: `.claude/API.md` - 라우팅 및 API 설계
- **ARCHITECTURE**: `.claude/ARCHITECTURE.md` - 시스템 아키텍처

### 개발 도구
- Rails Guides: https://guides.rubyonrails.org
- Hotwire: https://hotwired.dev
- Pagy: https://github.com/ddnexus/pagy

---

## 팀 노트

### 주요 결정사항
- **2025-11-26**: Hotwire (Turbo + Stimulus) 사용, JSON API는 필요 시 추가
- **2025-11-26**: Pagy로 페이지네이션 구현 (Kaminari 대신)
- **2025-11-26**: Polymorphic 관계 사용 (Likes, Bookmarks)

### 기술 스택 확정
- Backend: Rails 8.1.1, Ruby 3.4.7
- Frontend: Hotwire (Turbo + Stimulus)
- Database: SQLite3 (dev) → PostgreSQL (prod)
- Deployment: Kamal (Docker)
- Testing: Minitest

### 개발 원칙
- **모바일 우선** 반응형 디자인
- **N+1 쿼리 방지** (includes, counter_cache)
- **RESTful 라우팅** 준수
- **TDD** (테스트 작성 후 구현)
- **심플함 유지** (오버엔지니어링 지양)
