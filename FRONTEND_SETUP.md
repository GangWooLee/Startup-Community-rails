# 프론트엔드 통합 완료 가이드

프론트엔드 코드가 성공적으로 통합되었습니다! 아래 단계에 따라 설정을 완료하고 실행하세요.

## 📋 통합된 내용

### 1. **Tailwind CSS 통합**
- ✅ `Gemfile`에 `tailwindcss-rails` gem 추가
- ✅ `app/assets/stylesheets/application.tailwind.css` 생성 (CSS 변수 및 다크모드 지원)
- ✅ 레이아웃 파일 업데이트 (`app/views/layouts/application.html.erb`)

### 2. **뷰 파일 복사**
- ✅ `app/views/shared/` - 공통 컴포넌트
  - `_bottom_nav.html.erb` - 하단 내비게이션
  - `icons/` - SVG 아이콘 13개
- ✅ `app/views/posts/index.html.erb` - 커뮤니티 홈
- ✅ `app/views/profiles/show.html.erb` - 프로필 페이지 (탭 UI)
- ✅ `app/views/job_posts/index.html.erb` - 외주 마켓플레이스
- ✅ `app/views/my_page/show.html.erb` - 마이페이지

### 3. **컨트롤러 생성**
- ✅ `PostsController` - 커뮤니티 게시글
- ✅ `ProfilesController` - 사용자 프로필
- ✅ `JobPostsController` - 구인/구직
- ✅ `MyPageController` - 마이페이지

### 4. **라우팅 설정**
- ✅ `config/routes.rb` 업데이트
  - `/` → 커뮤니티 홈 (posts#index)
  - `/posts` → 게시글 목록
  - `/profiles/:id` → 프로필 페이지
  - `/job_posts` → 외주 마켓플레이스
  - `/my_page` → 마이페이지

---

## 🚀 설치 및 실행 단계

### 1. Bundler 및 Gem 설치

현재 bundler 버전 문제가 있으므로 먼저 bundler를 업데이트하세요:

```bash
# Bundler 업데이트
gem install bundler:2.6.9

# 또는 최신 버전으로 업데이트
bundle update --bundler

# Gem 설치
bundle install
```

### 2. Tailwind CSS 설정

Tailwind CSS를 초기화합니다:

```bash
rails tailwindcss:install
```

이 명령어는 다음을 수행합니다:
- `config/tailwind.config.js` 생성
- `app/assets/builds/` 디렉토리 생성
- `Procfile.dev` 업데이트 (Tailwind 빌드 프로세스 추가)

### 3. 데이터베이스 설정

데이터베이스를 생성하고 마이그레이션합니다:

```bash
rails db:create
rails db:migrate
```

### 4. 개발 서버 실행

Tailwind CSS와 Rails 서버를 동시에 실행합니다:

```bash
./bin/dev
```

**또는** 두 개의 터미널을 사용:

**터미널 1 - Tailwind 빌드:**
```bash
rails tailwindcss:watch
```

**터미널 2 - Rails 서버:**
```bash
rails server
```

### 5. 브라우저에서 확인

브라우저에서 다음 주소를 열어 확인하세요:

- **커뮤니티 홈**: http://localhost:3000/
- **외주 마켓플레이스**: http://localhost:3000/job_posts
- **프로필 페이지**: http://localhost:3000/profiles/1
- **마이페이지**: http://localhost:3000/my_page

---

## 🎨 디자인 시스템

### CSS 변수
프로젝트는 CSS 변수를 사용하여 다크모드를 지원합니다:

```css
:root {
  --background: oklch(1 0 0);
  --foreground: oklch(0.145 0 0);
  --primary: oklch(0.205 0 0);
  /* ... */
}

.dark {
  --background: oklch(0.145 0 0);
  --foreground: oklch(0.985 0 0);
  /* ... */
}
```

### Tailwind 유틸리티 클래스
주요 클래스들:
- `bg-background` - 배경색
- `text-foreground` - 텍스트 색
- `bg-card` - 카드 배경
- `border-border` - 테두리 색
- `text-primary` - 주요 색상
- `text-muted-foreground` - 흐린 텍스트

---

## 📱 현재 구현된 기능

### 1. **커뮤니티 홈** (`/`)
- 게시글 카드 리스트
- 작성자 프로필 링크
- 좋아요, 댓글, 공유, 북마크 버튼
- 플로팅 액션 버튼 (새 게시글 작성)
- 하단 내비게이션

### 2. **프로필 페이지** (`/profiles/:id`)
- 프로필 정보 (아바타, 이름, 역할, 회사, 소개)
- 연락처 정보 (위치, 이메일, 웹사이트)
- 스킬 태그
- 탭 UI (커뮤니티 글 / 외주 공고)
- 메시지 보내기 버튼

### 3. **외주 마켓플레이스** (`/job_posts`)
- 구인/구직 탭 전환
- 공고 카드 리스트
- 스킬 태그
- 예산/기간 정보

### 4. **마이페이지** (`/my_page`)
- 프로필 카드
- 내가 쓴 글
- 스크랩한 글
- 설정 및 로그아웃 버튼

### 5. **공통 컴포넌트**
- 하단 내비게이션 (커뮤니티 / 외주 / 마이페이지)
- SVG 아이콘 13개
- 반응형 디자인 (모바일 우선)

---

## 🔧 다음 단계 (실제 기능 구현)

현재는 샘플 데이터로 UI만 구현되어 있습니다. 다음 단계로 실제 기능을 구현하세요:

### 1. **모델 생성** (DATABASE.md 참조)
```bash
# User 모델
rails g model User email:string password_digest:string name:string role_title:string bio:text

# Post 모델
rails g model Post user:references title:string content:text status:integer views_count:integer

# Comment 모델
rails g model Comment post:references user:references content:text

# JobPost 모델
rails g model JobPost user:references title:string description:text category:integer

# 마이그레이션 실행
rails db:migrate
```

### 2. **컨트롤러 업데이트**
현재 컨트롤러의 샘플 데이터를 실제 DB 쿼리로 교체:

```ruby
# app/controllers/posts_controller.rb
def index
  @posts = Post.includes(:user).published.recent.page(params[:page])
end
```

### 3. **인증 시스템 구현** (PRD.md 참조)
- `has_secure_password` 사용
- SessionsController 생성
- 로그인/로그아웃 기능

### 4. **CRUD 기능 완성**
- 게시글 작성/수정/삭제
- 댓글 작성/삭제
- 좋아요 기능
- 북마크 기능

---

## 📝 문서 참조

프로젝트 구조 및 요구사항은 `.claude/` 디렉토리의 문서를 참조하세요:

- **PRD.md** - 제품 요구사항 (기능 명세)
- **DATABASE.md** - ERD 및 스키마 설계
- **API.md** - 라우팅 및 컨트롤러 설계
- **ARCHITECTURE.md** - 시스템 아키텍처
- **TASKS.md** - MVP 작업 목록 (4주 계획)

---

## ⚠️ 주의사항

1. **Tailwind CSS 빌드**
   - `./bin/dev`로 실행하면 Tailwind가 자동으로 빌드됩니다
   - CSS 변경 시 브라우저를 새로고침하세요

2. **샘플 데이터**
   - 현재 컨트롤러는 하드코딩된 샘플 데이터를 사용합니다
   - 실제 DB 연동 후 교체하세요

3. **라우팅**
   - 프로필 링크는 `/profiles/:id`로 연결됩니다
   - 아직 사용자 ID가 없으면 임시로 `/profiles/1` 사용

4. **아이콘**
   - SVG 아이콘은 `app/views/shared/icons/` 에 있습니다
   - 사용법: `<%= render partial: "shared/icons/home", locals: { css_class: "h-5 w-5" } %>`

---

## 🎉 완료!

프론트엔드가 성공적으로 통합되었습니다. `./bin/dev`를 실행하고 http://localhost:3000 에서 확인하세요!

문제가 발생하면 다음을 확인하세요:
1. Bundler 버전 (`bundle -v`)
2. Tailwind CSS 설치 (`rails tailwindcss:install`)
3. 서버 로그 확인
4. 브라우저 콘솔 확인

추가 질문이 있으면 `.claude/` 디렉토리의 문서를 참조하거나 질문해주세요!
