# System Architecture

## 문서 정보
- **프로젝트**: Startup Community Platform
- **업데이트**: 2025-11-25

---

## 1. 아키텍처 개요

### 1.1 시스템 구조
```
┌─────────────────────────────────────────┐
│         Client (Browser)                │
│  ┌─────────────────────────────────┐   │
│  │   Hotwire (Turbo + Stimulus)    │   │
│  └─────────────────────────────────┘   │
└──────────────┬──────────────────────────┘
               │ HTTP/WebSocket
┌──────────────▼──────────────────────────┐
│         Rails Application               │
│  ┌──────────┬──────────┬──────────┐    │
│  │Controllers│ Models  │  Jobs    │    │
│  └──────────┴──────────┴──────────┘    │
└──────────────┬──────────────────────────┘
               │
    ┌──────────┼──────────┐
    │          │          │
┌───▼───┐  ┌──▼───┐  ┌──▼────┐
│SQLite │  │Redis │  │Storage│
│  DB   │  │Cache │  │ Files │
└───────┘  └──────┘  └───────┘
```

### 1.2 기술 스택 레이어

#### Presentation Layer
- **View Engine**: ERB Templates
- **JS Framework**: Stimulus (Hotwire)
- **Real-time**: Turbo Streams
- **Styling**: [CSS 프레임워크 - 프로젝트에 맞게 선택]

#### Application Layer
- **Framework**: Rails 8.1.1
- **Language**: Ruby 3.4.7
- **API**: REST (JSON)

#### Data Layer
- **Primary DB**: SQLite3 (dev) / PostgreSQL (prod)
- **Cache**: Solid Cache (SQLite)
- **Queue**: Solid Queue (SQLite)
- **Cable**: Solid Cable (SQLite)

#### Infrastructure Layer
- **Web Server**: Puma
- **Container**: Docker
- **Deployment**: Kamal
- **Reverse Proxy**: Thruster

---

## 2. 데이터베이스 설계

### 2.1 ERD (Entity Relationship Diagram)

프로젝트의 상세 ERD는 `DATABASE.md` 참조.

**핵심 테이블**:
- `users` - 사용자 계정
- `posts` - 커뮤니티 게시글
- `comments` - 댓글
- `job_posts` - 구인 공고
- `talent_listings` - 구직 정보
- `likes` - 좋아요 (polymorphic)
- `bookmarks` - 스크랩 (polymorphic)

**주요 관계**:
```
User (1) ─── (N) Posts
User (1) ─── (N) JobPosts
User (1) ─── (N) TalentListings
User (1) ─── (N) Comments
Post (1) ─── (N) Comments
Post (1) ─── (N) Likes (polymorphic)
Post/JobPost/TalentListing (1) ─── (N) Bookmarks (polymorphic)
```

### 2.2 주요 도메인 모델

#### User (사용자)
- 인증 정보 (email, password_digest)
- 프로필 정보 (name, role_title, bio, avatar)
- 커뮤니티 활동 (posts, comments, likes)
- 외주 관련 (job_posts, talent_listings)
- 스크랩 (bookmarks)

#### Post (커뮤니티 게시글)
- 제목, 내용, 상태 (draft/published/archived)
- 조회수, 좋아요 수, 댓글 수 (counter_cache)
- 작성자 연결 (belongs_to :user)

#### JobPost (구인 공고)
- 제목, 설명, 카테고리, 프로젝트 타입, 예산
- 상태 (open/closed/filled)
- 조회수

#### TalentListing (구직 정보)
- 제목, 설명, 카테고리, 프로젝트 타입, 희망 시급
- 상태 (available/unavailable)
- 조회수

### 2.3 인덱스 전략
```ruby
# 검색 성능 최적화
add_index :users, :email, unique: true
add_index :posts, :user_id
add_index :posts, [:user_id, :created_at]
```

---

## 3. API 설계

### 3.1 RESTful 리소스

상세 라우팅 설계는 `API.md` 참조.

**핵심 리소스**:
- **Posts** (커뮤니티) - CRUD + 댓글, 좋아요
- **Profiles** (프로필) - 사용자별 Posts/JobPosts/TalentListings 탭
- **JobPosts** (구인) - CRUD + 필터링 (카테고리, 타입, 상태)
- **TalentListings** (구직) - CRUD + 필터링
- **My Page** (마이페이지) - 프로필 관리, 스크랩 관리

**인증**:
```
GET/POST  /signup    # 회원가입
GET/POST  /login     # 로그인
DELETE    /logout    # 로그아웃
```

**URL 구조 예시**:
```
/posts                        # 커뮤니티 홈
/posts/:id                    # 게시글 상세
/profiles/:id                 # 프로필 (기본: Posts 탭)
/profiles/:id/job_posts       # 프로필 - Job Posts 탭
/job_posts                    # 구인 공고 목록
/talent_listings              # 구직 정보 목록
/my/bookmarks                 # 내 스크랩
```

### 3.2 응답 형식
```json
{
  "status": "success|error",
  "data": { ... },
  "message": "optional message",
  "errors": []
}
```

---

## 4. 보안 아키텍처

### 4.1 인증 (Authentication)
- **방식**: Session-based (has_secure_password)
- **대안**: JWT (API 전용 시)
- **소셜 로그인**: [OAuth 제공자]

### 4.2 권한 (Authorization)
- **방식**: Role-based Access Control (RBAC)
- **라이브러리**: Pundit / CanCanCan (선택)
- **역할**: user, admin, [custom roles]

### 4.3 데이터 보호
- **전송**: HTTPS (TLS 1.3)
- **저장**: bcrypt password hashing
- **민감정보**: Rails credentials (encrypted)

### 4.4 보안 헤더
```ruby
# config/application.rb
config.force_ssl = true
config.action_dispatch.default_headers.merge!(
  'X-Frame-Options' => 'DENY',
  'X-Content-Type-Options' => 'nosniff',
  'X-XSS-Protection' => '1; mode=block'
)
```

---

## 5. 성능 최적화

### 5.1 캐싱 전략

#### Fragment Caching
```erb
<% cache @user do %>
  <%= render @user %>
<% end %>
```

#### Query Caching
```ruby
# N+1 방지
@posts = Post.includes(:user).all
```

#### Page Caching
- Turbo Drive로 자동 처리
- Solid Cache로 DB 쿼리 캐싱

### 5.2 데이터베이스 최적화
- **인덱싱**: 외래키, 검색 컬럼
- **Pagination**: Kaminari / Pagy
- **Eager Loading**: includes, joins
- **Counter Cache**: 카운트 최적화

### 5.3 Asset 최적화
- **JS**: Import Maps (no bundler)
- **CSS**: Propshaft (fingerprinting)
- **Images**: ImageMagick (resize, compress)

---

## 6. 확장성 전략

### 6.1 수평 확장
```
┌─────────────────────────────────┐
│      Load Balancer              │
└───┬─────────┬─────────┬─────────┘
    │         │         │
┌───▼──┐  ┌──▼───┐  ┌──▼───┐
│App 1 │  │App 2 │  │App 3 │
└───┬──┘  └──┬───┘  └──┬───┘
    └─────────┼─────────┘
         ┌────▼────┐
         │   DB    │
         └─────────┘
```

### 6.2 마이크로서비스 전환 고려사항
- **모놀리스 우선**: MVP는 모놀리식
- **도메인 분리**: 추후 서비스 분리 가능 구조
- **API Gateway**: 필요 시 추가

---

## 7. 모니터링 & 로깅

### 7.1 로깅
```ruby
# config/environments/production.rb
config.log_level = :info
config.log_tags = [:request_id]
```

### 7.2 모니터링 (추후 추가)
- **APM**: [New Relic / DataDog]
- **Error Tracking**: [Sentry / Rollbar]
- **Uptime**: [UptimeRobot / Pingdom]

---

## 8. 배포 전략

### 8.1 환경
- **Development**: 로컬 (SQLite)
- **Staging**: Docker (PostgreSQL)
- **Production**: Kamal + Docker

### 8.2 CI/CD
```yaml
# .github/workflows/ci.yml
- Lint (Rubocop)
- Test (Minitest)
- Security Scan (Brakeman)
- Deploy (Kamal)
```

### 8.3 롤백 전략
- Docker 이미지 버전 관리
- DB 마이그레이션 롤백 가능하게 작성

---

## 9. 의존성 관리

### 9.1 핵심 Gem
```ruby
gem "rails", "~> 8.1.1"
gem "sqlite3", ">= 2.1"         # DB
gem "puma", ">= 5.0"            # Web Server
gem "turbo-rails"               # Hotwire
gem "stimulus-rails"            # JS
gem "solid_cache"               # Cache
gem "solid_queue"               # Jobs
gem "image_processing"          # Images
```

### 9.2 개발/테스트 Gem
```ruby
group :development, :test do
  gem "debug"
  gem "rubocop-rails-omakase"
  gem "brakeman"
end
```

---

## 10. 마이그레이션 경로

### 10.1 프로덕션 DB 전환
```
SQLite (개발) → PostgreSQL (프로덕션)

변경 사항:
- database.yml 수정
- PostgreSQL gem 추가
- 환경변수 설정
```

### 10.2 파일 스토리지
```
로컬 → Active Storage + S3/GCS

변경 사항:
- storage.yml 설정
- aws-sdk-s3 gem 추가
```

---

## 참고자료

- Rails Guides: https://guides.rubyonrails.org
- Hotwire: https://hotwired.dev
- Kamal: https://kamal-deploy.org
