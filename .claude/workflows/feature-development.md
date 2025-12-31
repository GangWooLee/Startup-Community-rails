# Feature Development Workflow

> Agent OS 스타일 워크플로우 - 새 기능 개발 시 따라야 할 단계별 프로세스

## 워크플로우 개요

```
┌─────────────────────────────────────────────────────────────────┐
│  1. 요구사항 분석  →  2. 설계  →  3. 구현  →  4. 테스트  →  5. 리뷰  │
└─────────────────────────────────────────────────────────────────┘
```

## Phase 1: 요구사항 분석

### 1.1 기능 정의
```markdown
## 기능명: [기능 이름]

### 목적
- 이 기능이 해결하는 문제는 무엇인가?
- 사용자에게 어떤 가치를 제공하는가?

### 사용자 스토리
- As a [사용자 유형], I want to [행동], so that [목적]

### 수락 기준 (Acceptance Criteria)
- [ ] 기준 1
- [ ] 기준 2
- [ ] 기준 3

### 제약 조건
- 기술적 제약
- 비즈니스 제약
- 시간 제약
```

### 1.2 기존 코드베이스 분석
```bash
# 관련 파일 탐색
# 1. 라우팅 확인
cat config/routes.rb | grep -i "[관련 키워드]"

# 2. 관련 모델 확인
ls app/models/

# 3. 관련 컨트롤러 확인
ls app/controllers/

# 4. 관련 뷰 확인
ls app/views/

# 5. 테스트 확인
ls test/models/ test/controllers/
```

### 1.3 영향 범위 파악
```markdown
### 영향받는 파일들
- 모델: app/models/xxx.rb
- 컨트롤러: app/controllers/xxx_controller.rb
- 뷰: app/views/xxx/
- Stimulus: app/javascript/controllers/xxx_controller.js
- 테스트: test/models/xxx_test.rb

### 의존성
- 이 기능이 의존하는 기존 기능
- 이 기능에 의존하게 될 기능

### 잠재적 사이드 이펙트
- 기존 기능에 미치는 영향
- 성능 영향
- 보안 고려사항
```

## Phase 2: 설계

### 2.1 데이터 모델 설계
```ruby
# ERD 스케치
# posts
#   - id: integer (PK)
#   - user_id: integer (FK -> users)
#   - title: string (NOT NULL, max 100)
#   - content: text (NOT NULL)
#   - category: string (NOT NULL, default: 'free')
#   - created_at, updated_at: timestamps

# 마이그레이션 작성
class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :content, null: false
      t.string :category, null: false, default: "free"

      t.timestamps
    end

    add_index :posts, [:user_id, :created_at]
    add_index :posts, :category
  end
end
```

### 2.2 API 설계
```markdown
### Endpoints

#### GET /posts
- 목적: 게시글 목록 조회
- 파라미터: page, category, q (검색어)
- 응답: 200 OK + JSON/HTML

#### POST /posts
- 목적: 새 게시글 작성
- 인증: 필수
- 파라미터: title, content, category
- 응답: 201 Created / 422 Unprocessable Entity

#### PATCH /posts/:id
- 목적: 게시글 수정
- 인증: 필수 (본인만)
- 파라미터: title, content, category
- 응답: 200 OK / 403 Forbidden / 422 Unprocessable Entity
```

### 2.3 UI 설계 (Design OS 방식)
```markdown
### 컴포넌트 명세

#### PostCard
- 위치: app/views/posts/_post_card.html.erb
- Props:
  - post: Post 객체
  - show_author: boolean (default: true)
- 디자인:
  - 카드 스타일: bg-white rounded-xl shadow-sm p-6
  - 제목: text-lg font-semibold
  - 내용: text-gray-600 text-sm line-clamp-3
  - 메타: text-xs text-gray-400

#### PostForm
- 위치: app/views/posts/_form.html.erb
- 필드: title (input), content (textarea), category (select)
- 버튼: 저장 (primary), 취소 (secondary)
- Validation 표시: 인라인 에러 메시지
```

### 2.4 Stimulus 컨트롤러 설계
```markdown
### post_form_controller.js
- Targets: form, submit, title, content
- Values: maxLength (number)
- Actions:
  - validate: 실시간 유효성 검사
  - submit: 폼 제출 처리
  - countCharacters: 글자 수 표시
```

## Phase 3: 구현

### 3.1 구현 순서 (권장)
```
1. 마이그레이션 작성 및 실행
2. 모델 작성 (+ 테스트)
3. 라우팅 설정
4. 컨트롤러 작성 (+ 테스트)
5. 뷰 작성
6. Stimulus 컨트롤러 작성
7. 시스템 테스트
8. 리팩토링
```

### 3.2 TDD 방식 (권장)
```ruby
# 1. 실패하는 테스트 작성
test "should create post with valid attributes" do
  log_in_as(users(:one))

  assert_difference "Post.count", 1 do
    post posts_url, params: {
      post: { title: "Test", content: "Content", category: "free" }
    }
  end

  assert_redirected_to post_url(Post.last)
end

# 2. 테스트를 통과하는 최소 코드 작성
def create
  @post = current_user.posts.build(post_params)

  if @post.save
    redirect_to @post
  else
    render :new, status: :unprocessable_entity
  end
end

# 3. 리팩토링
```

### 3.3 체크리스트
```markdown
#### 모델
- [ ] Validations 추가
- [ ] Associations 설정
- [ ] Scopes 정의
- [ ] Callbacks (최소화)
- [ ] 테스트 작성

#### 컨트롤러
- [ ] Strong Parameters 설정
- [ ] before_action 설정 (인증, 권한)
- [ ] 에러 핸들링
- [ ] N+1 방지 (includes)
- [ ] Turbo Stream 지원
- [ ] 테스트 작성

#### 뷰
- [ ] 반응형 디자인
- [ ] 접근성 (aria-*)
- [ ] Flash 메시지
- [ ] 에러 표시
- [ ] 로딩 상태

#### JavaScript
- [ ] Stimulus 컨트롤러 등록
- [ ] Turbo 호환성
- [ ] 에러 처리
```

## Phase 4: 테스트

### 4.1 테스트 작성 순서
```
1. 모델 테스트 (Validations, Associations)
2. 컨트롤러 테스트 (CRUD, 인증, 권한)
3. 서비스 테스트 (복잡한 로직)
4. 시스템 테스트 (E2E)
```

### 4.2 테스트 실행
```bash
# 전체 테스트
bin/rails test

# 관련 테스트만
bin/rails test test/models/post_test.rb
bin/rails test test/controllers/posts_controller_test.rb

# 시스템 테스트
bin/rails test:system

# 커버리지 확인
COVERAGE=true bin/rails test
```

### 4.3 수동 테스트 체크리스트
```markdown
#### 기능 테스트
- [ ] 정상 동작 (Happy Path)
- [ ] 에러 케이스 (잘못된 입력)
- [ ] Edge Case (빈 데이터, 최대 길이)
- [ ] 인증 없이 접근 시도
- [ ] 다른 사용자 데이터 접근 시도

#### 브라우저 테스트
- [ ] Chrome (최신)
- [ ] Safari (최신)
- [ ] 모바일 (iOS Safari, Android Chrome)

#### 반응형 테스트
- [ ] 모바일 (320px ~ 640px)
- [ ] 태블릿 (768px ~ 1024px)
- [ ] 데스크톱 (1024px+)
```

## Phase 5: 코드 리뷰

### 5.1 셀프 리뷰 체크리스트
```markdown
#### 코드 품질
- [ ] 코딩 컨벤션 준수
- [ ] 중복 코드 없음
- [ ] 명확한 변수/메서드 이름
- [ ] 적절한 주석 (필요한 경우만)

#### 보안
- [ ] SQL Injection 방지
- [ ] XSS 방지
- [ ] CSRF 토큰 사용
- [ ] Strong Parameters 사용
- [ ] 권한 검증

#### 성능
- [ ] N+1 쿼리 없음
- [ ] 적절한 인덱스
- [ ] 불필요한 쿼리 없음
- [ ] 캐싱 고려

#### 테스트
- [ ] 핵심 기능 테스트 있음
- [ ] Edge Case 테스트 있음
- [ ] 모든 테스트 통과
```

### 5.2 커밋 및 PR
```bash
# 브랜치 생성
git checkout -b feature/post-crud

# 커밋 (기능별로 분리)
git add app/models/post.rb test/models/post_test.rb
git commit -m "[feat] Post 모델 및 테스트 추가"

git add app/controllers/posts_controller.rb config/routes.rb
git commit -m "[feat] PostsController CRUD 구현"

git add app/views/posts/
git commit -m "[feat] Post 뷰 템플릿 추가"

# PR 생성
gh pr create --title "[feat] 게시글 CRUD 기능" --body "..."
```

## 예시: Remember Me 기능 구현

### 요구사항
```markdown
## 기능명: Remember Me (로그인 상태 유지)

### 목적
- 사용자가 브라우저를 닫아도 로그인 상태 유지
- 재방문 시 자동 로그인

### 수락 기준
- [ ] 로그인 페이지에 "로그인 상태 유지" 체크박스 있음
- [ ] 체크 시 20년 유효 쿠키 생성
- [ ] 미체크 시 세션 쿠키만 사용
- [ ] 로그아웃 시 쿠키 삭제
```

### 구현 계획
```markdown
1. 마이그레이션: users 테이블에 remember_digest 컬럼 추가
2. 모델: remember, forget, authenticated? 메서드 추가
3. 컨트롤러: remember_me 파라미터 처리
4. 뷰: 체크박스 UI (이미 존재)
5. 테스트: 쿠키 생성/삭제 테스트
```

### 구현 결과
```ruby
# Migration
add_column :users, :remember_digest, :string

# User Model
def remember
  self.remember_token = SecureRandom.urlsafe_base64
  update_column(:remember_digest, BCrypt::Password.create(remember_token))
end

def forget
  update_column(:remember_digest, nil)
end

def authenticated?(remember_token)
  return false if remember_digest.nil?
  BCrypt::Password.new(remember_digest).is_password?(remember_token)
end

# SessionsController
if params[:remember_me] == "1"
  remember(user)
else
  forget(user)
end
```

## 빠른 참조 명령어

```bash
# 마이그레이션 생성
bin/rails generate migration AddFieldToTable field:type

# 마이그레이션 실행
bin/rails db:migrate

# 테스트 실행
bin/rails test

# 서버 시작
bin/rails server

# 콘솔 (디버깅)
bin/rails console

# 라우팅 확인
bin/rails routes | grep posts
```
