# Windows 환경 개발 가이드

Windows에서 WSL2 Ubuntu를 사용하여 Rails 프로젝트를 실행하는 방법입니다.

---

## Step 1: WSL2 + Ubuntu 설치

Windows에서 Linux 환경을 사용하기 위해 WSL2와 Ubuntu를 설치합니다.

### 1-1. WSL2 활성화

PowerShell을 **관리자 권한**으로 실행하고 아래 명령어를 입력합니다:

```powershell
wsl --install
```

설치가 완료되면 **컴퓨터를 재시작**합니다.

### 1-2. Ubuntu 설치

1. Microsoft Store에서 **Ubuntu** 검색
2. Ubuntu (또는 Ubuntu 22.04 LTS) 설치
3. 설치 후 Ubuntu 실행
4. 사용자 이름과 비밀번호 설정

---

## Step 2: Rails 환경 설정

Ubuntu 터미널에서 Ruby와 Rails를 설치합니다.

아래 링크의 가이드를 따라 설치를 진행하세요:

**https://rails.insomenia.com/install_ruby_on_rails**

위 가이드에서 다음 항목들이 설치됩니다:
- Ruby (rbenv 사용)
- Rails
- 필수 라이브러리들

---

## Step 3: 프로젝트 클론 및 설정

Ubuntu 터미널에서 아래 명령어를 순서대로 실행합니다:

```bash
# 1. 프로젝트 클론
git clone https://github.com/GangWooLee/Startup-Community-rails.git

# 2. 프로젝트 디렉토리로 이동
cd Startup-Community-rails

# 3. Gem 의존성 설치
bundle install

# 4. 데이터베이스 생성 및 마이그레이션
rails db:create db:migrate
```

---

## Step 4: 서버 실행

```bash
rails server
```

서버가 실행되면 브라우저에서 접속:

**http://localhost:3000**

서버를 종료하려면 터미널에서 `Ctrl + C`를 누릅니다.

---

## Step 5: 테스트 데이터 생성

페이지에 데이터가 없다면, 테스트 데이터를 생성합니다:

```bash
rails db:seed
```

### 테스트 계정 정보

| 계정 | 이메일 | 비밀번호 |
|------|--------|----------|
| 관리자 | admin@startup.com | password |
| 사용자1 | user0@startup.com | password |
| 사용자2 | user1@startup.com | password |
| ... | ... | ... |
| 사용자10 | user9@startup.com | password |

---

## 현재 구현된 페이지

### 1. 커뮤니티 홈 (/)
- **URL**: `http://localhost:3000/`
- **파일**: `app/views/posts/index.html.erb`
- **기능**:
  - 게시글 카드 리스트
  - 작성자 프로필 링크
  - 좋아요, 댓글, 공유, 북마크 버튼
  - 플로팅 액션 버튼
  - 하단 내비게이션

### 2. 게시글 상세 (/posts/:id)
- **URL**: `http://localhost:3000/posts/1`
- **파일**: `app/views/posts/show.html.erb`
- **기능**:
  - 게시글 상세 내용
  - 작성자 정보
  - 댓글 목록

### 3. 프로필 페이지 (/profiles/:id)
- **URL**: `http://localhost:3000/profiles/1`
- **파일**: `app/views/profiles/show.html.erb`
- **기능**:
  - 프로필 정보
  - 연락처 정보
  - 스킬 태그
  - 탭 UI (커뮤니티 글 / 외주 공고)

### 4. 외주 마켓플레이스 (/job_posts)
- **URL**: `http://localhost:3000/job_posts`
- **파일**: `app/views/job_posts/index.html.erb`
- **기능**:
  - 구인/구직 탭
  - 공고 카드 리스트

### 5. 외주 공고 상세 (/job_posts/:id)
- **URL**: `http://localhost:3000/job_posts/1`
- **파일**: `app/views/job_posts/show.html.erb`
- **기능**:
  - 공고 상세 정보
  - 지원 버튼
  - 공유 기능

### 6. 마이페이지 (/my_page)
- **URL**: `http://localhost:3000/my_page`
- **파일**: `app/views/my_page/show.html.erb`
- **기능**:
  - 프로필 카드
  - 내가 쓴 글
  - 스크랩한 글

### 7. 로그인/회원가입
- **로그인**: `http://localhost:3000/login` → `app/views/sessions/new.html.erb`
- **회원가입**: `http://localhost:3000/signup` → `app/views/users/new.html.erb`

---

## 프로젝트 파일 구조

### 화면(View) 파일 위치
```
app/views/
├── layouts/
│   └── application.html.erb       # 모든 페이지의 기본 레이아웃
├── posts/
│   ├── index.html.erb             # 커뮤니티 홈 (루트 페이지)
│   └── show.html.erb              # 게시글 상세
├── job_posts/
│   ├── index.html.erb             # 외주 마켓플레이스
│   └── show.html.erb              # 외주 공고 상세
├── profiles/
│   └── show.html.erb              # 프로필 페이지
├── my_page/
│   └── show.html.erb              # 마이페이지
├── sessions/
│   └── new.html.erb               # 로그인 페이지
├── users/
│   └── new.html.erb               # 회원가입 페이지
└── shared/
    ├── _bottom_nav.html.erb       # 하단 네비게이션 바
    └── icons/                     # 아이콘 SVG 파일들
```

### 비즈니스 로직(Controller) 파일 위치
```
app/controllers/
├── posts_controller.rb            # 게시글 관련
├── job_posts_controller.rb        # 외주 공고 관련
├── profiles_controller.rb         # 프로필 관련
├── my_page_controller.rb          # 마이페이지 관련
├── sessions_controller.rb         # 로그인/로그아웃
└── users_controller.rb            # 회원가입
```

### 데이터 모델(Model) 파일 위치
```
app/models/
├── user.rb                        # 사용자
├── post.rb                        # 게시글
├── job_post.rb                    # 외주 공고
├── comment.rb                     # 댓글
└── profile.rb                     # 프로필
```

### 라우팅 설정
- **파일**: `config/routes.rb`
- URL과 컨트롤러를 연결하는 설정 파일

---

## 문제 해결

### Q: `bundle install`에서 에러가 발생해요
```bash
# 필수 라이브러리 설치 후 다시 시도
sudo apt-get update
sudo apt-get install -y build-essential libssl-dev libreadline-dev zlib1g-dev
bundle install
```

### Q: 데이터베이스 에러가 발생해요
```bash
# 데이터베이스 재생성
rails db:drop db:create db:migrate db:seed
```

### Q: 서버가 이미 실행 중이라고 나와요
```bash
# 기존 서버 프로세스 종료
kill -9 $(lsof -t -i:3000)
rails server
```

### Q: 페이지에 데이터가 없어요
```bash
rails db:seed
```

---

## 빠른 참조

| 명령어 | 설명 |
|--------|------|
| `rails server` | 서버 실행 |
| `rails db:seed` | 테스트 데이터 생성 |
| `rails db:migrate` | 데이터베이스 마이그레이션 |
| `rails console` | Rails 콘솔 실행 |
| `bundle install` | Gem 의존성 설치 |
