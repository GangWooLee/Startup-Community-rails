---
name: community-expert
description: 커뮤니티 시스템 전문가 - 게시글, 댓글, 대댓글, 좋아요, 스크랩, Turbo Stream
triggers:
  - 게시글
  - 댓글
  - 좋아요
  - 스크랩
  - post
  - comment
  - like
  - bookmark
  - 커뮤니티
related_skills:
  - rails-resource
  - test-gen
---

# Community Expert (커뮤니티 전문가)

## 🎯 역할

커뮤니티 기능의 모든 측면을 담당합니다:
- 게시글 CRUD (카테고리별, 이미지 첨부)
- 댓글 및 대댓글 (nested comments)
- 좋아요/스크랩 (Polymorphic)
- 실시간 업데이트 (Turbo Stream)
- 알림 연동

---

## 📁 담당 파일

### Controllers
```
app/controllers/posts_controller.rb           # 게시글 CRUD
app/controllers/comments_controller.rb        # 댓글/대댓글
app/controllers/likes_controller.rb           # 좋아요 토글
app/controllers/bookmarks_controller.rb       # 스크랩 토글
```

### Models
```
app/models/post.rb                            # 게시글
app/models/comment.rb                         # 댓글
app/models/like.rb                            # 좋아요 (Polymorphic)
app/models/bookmark.rb                        # 스크랩 (Polymorphic)

# Concerns
app/models/concerns/likeable.rb               # 좋아요 가능 Concern
app/models/concerns/bookmarkable.rb           # 스크랩 가능 Concern
app/models/concerns/commentable.rb            # 댓글 가능 Concern
```

### JavaScript (Stimulus)
```
app/javascript/controllers/like_button_controller.js      # 좋아요 버튼
app/javascript/controllers/bookmark_button_controller.js  # 스크랩 버튼
app/javascript/controllers/comment_form_controller.js     # 댓글 폼
app/javascript/controllers/post_form_controller.js        # 게시글 폼
app/javascript/controllers/image_upload_controller.js     # 이미지 업로드
```

### Views
```
app/views/posts/
├── index.html.erb           # 게시글 목록
├── show.html.erb            # 게시글 상세
├── new.html.erb             # 게시글 작성
├── edit.html.erb            # 게시글 수정
├── _post.html.erb           # 게시글 카드
├── _form.html.erb           # 게시글 폼
└── _show_community.html.erb # 커뮤니티용 상세

app/views/comments/
├── _comment.html.erb        # 댓글 컴포넌트
├── _form.html.erb           # 댓글 폼
└── _replies.html.erb        # 대댓글 목록

app/views/likes/
└── _button.html.erb         # 좋아요 버튼

app/views/bookmarks/
└── _button.html.erb         # 스크랩 버튼
```

### Tests
```
test/controllers/posts_controller_test.rb
test/controllers/comments_controller_test.rb
test/controllers/likes_controller_test.rb
test/controllers/bookmarks_controller_test.rb
test/models/post_test.rb
test/models/comment_test.rb
test/models/like_test.rb
test/system/posts_test.rb
test/system/comments_test.rb
```

---

## 🔧 핵심 패턴

### 1. Counter Cache (좋아요/댓글 수)

```ruby
# Like 모델
belongs_to :likeable, polymorphic: true, counter_cache: true

# Post 모델 - likes_count 자동 관리
has_many :likes, as: :likeable, dependent: :destroy

# 수동 업데이트 시 (Race Condition 방지)
Post.where(id: post_id).update_all("likes_count = likes_count + 1")
```

### 2. Polymorphic Associations

```ruby
# Like - 게시글/댓글 모두 좋아요 가능
belongs_to :likeable, polymorphic: true
# likeable_type: "Post" or "Comment"
# likeable_id: 대상 ID

# 사용법
@post.likes
@comment.likes
```

### 3. N+1 방지 패턴

```ruby
# ❌ N+1 발생
@posts = Post.all
# view에서 post.user.name 호출 시 N+1

# ✅ includes 사용
@posts = Post.includes(:user, :likes, comments: :user)
             .order(created_at: :desc)
             .page(params[:page])
```

### 4. Turbo Stream 실시간 업데이트

```ruby
# 좋아요 토글 후 카운터 업데이트
respond_to do |format|
  format.turbo_stream do
    render turbo_stream: turbo_stream.replace(
      dom_id(@post, :likes_count),
      partial: "posts/likes_count",
      locals: { post: @post }
    )
  end
end
```

### 5. 대댓글 구조 (Self-referential)

```ruby
# Comment 모델
belongs_to :parent, class_name: "Comment", optional: true
has_many :replies, class_name: "Comment", foreign_key: :parent_id

# 최상위 댓글만 조회
scope :root_comments, -> { where(parent_id: nil) }
```

### 6. 카테고리별 조회

```ruby
# Post 모델
CATEGORIES = %w[free promo qna insight job].freeze
validates :category, inclusion: { in: CATEGORIES }

scope :by_category, ->(cat) { where(category: cat) if cat.present? }
```

---

## ⚠️ 주의사항

### 금지 패턴

| 패턴 | 문제 | 대안 |
|------|------|------|
| `Post.all` | 페이지네이션 없음 | `Post.page(params[:page])` |
| `post.likes.count` 반복 | N+1 쿼리 | `likes_count` 컬럼 사용 |
| `current_user.liked?(post)` 반복 | N+1 쿼리 | `includes(:likes)` + Ruby 체크 |
| 인라인 `onclick` | blur 시 재검색 | `onmousedown` 사용 |

### 좋아요 체크 최적화

```ruby
# ❌ N+1 발생
posts.each do |post|
  post.likes.exists?(user: current_user)  # 매번 쿼리
end

# ✅ 미리 로드 후 Ruby로 체크
@liked_post_ids = current_user.likes
                              .where(likeable_type: "Post")
                              .pluck(:likeable_id)
                              .to_set

# View에서
@liked_post_ids.include?(post.id)
```

### 비로그인 사용자 처리

```ruby
# PostsController#index
session[:browsing_community] = true if params[:browse] == "true"

# 온보딩 리다이렉트 조건
def redirect_to_onboarding
  return if logged_in?
  return if session[:browsing_community]  # 세션 체크 필수!
  redirect_to root_path
end
```

---

## ✅ 체크리스트

### 게시글 수정 시
- [ ] N+1 쿼리 확인 (includes 사용)
- [ ] 페이지네이션 적용 확인
- [ ] 카테고리 필터 동작 확인
- [ ] 이미지 첨부 동작 확인

### 댓글 수정 시
- [ ] 대댓글 구조 확인 (parent_id)
- [ ] 알림 생성 연동 확인
- [ ] Turbo Stream 타겟 ID 확인
- [ ] 삭제 시 대댓글 처리 확인

### 좋아요/스크랩 수정 시
- [ ] Counter cache 동작 확인
- [ ] Polymorphic 타입 확인
- [ ] Race Condition 방지 확인
- [ ] 토글 UI 업데이트 확인

### 테스트 작성 시
- [ ] 로그인/비로그인 케이스 분리
- [ ] 권한 체크 테스트
- [ ] Turbo Stream 응답 테스트
- [ ] Counter cache 정합성 테스트

---

## 📊 데이터 모델

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│    User     │     │    Post     │     │   Comment   │
├─────────────┤     ├─────────────┤     ├─────────────┤
│ id          │◄────│ user_id     │◄────│ user_id     │
│ name        │     │ title       │     │ post_id     │
│ email       │     │ content     │     │ parent_id   │──┐
└─────────────┘     │ category    │     │ content     │  │
                    │ likes_count │     │ likes_count │  │
                    │ comments_cnt│     └─────────────┘  │
                    └─────────────┘            ▲         │
                           ▲                   │         │
                           │                   └─────────┘
                    ┌──────┴──────┐           (대댓글)
                    │             │
              ┌─────┴─────┐ ┌─────┴─────┐
              │   Like    │ │ Bookmark  │
              ├───────────┤ ├───────────┤
              │ user_id   │ │ user_id   │
              │ likeable_ │ │ bookmarkab│
              │   type    │ │   le_type │
              │ likeable_ │ │ bookmarkab│
              │   id      │ │   le_id   │
              └───────────┘ └───────────┘
                (Polymorphic)
```

---

## 🐛 CI 테스트 트러블슈팅

### 상태 오염 방지 (빈도: 5%)

**문제**: 테스트 간 데이터 충돌로 인한 간헐적 실패

```ruby
# ❌ 하드코딩 - 다른 테스트와 충돌 가능
post = Post.create!(title: "테스트 게시글", user: @user)

# ✅ 유니크 데이터 - SecureRandom 사용
unique_title = "Post #{SecureRandom.hex(4)}"
post = Post.create!(title: unique_title, user: @user)

# ✅ Fixture 사용 시에도 유니크 값 추가
test "creates post with unique title" do
  unique_suffix = SecureRandom.hex(4)
  post = posts(:one)
  post.update!(title: "#{post.title}_#{unique_suffix}")
end
```

**원칙**: 테스트 데이터는 항상 `SecureRandom.hex(4)` 등으로 유니크하게 생성

### Turbo Stream 테스트 패턴

**응답 검증**:
```ruby
# Turbo Stream 응답 검증
test "like creates turbo stream response" do
  sign_in @user

  post likes_path, params: { likeable_type: "Post", likeable_id: @post.id },
       headers: { "Accept" => "text/vnd.turbo-stream.html" }

  assert_response :success
  assert_match "turbo-stream", response.body
  assert_turbo_stream action: "replace", target: dom_id(@post, :likes_count)
end
```

**System Test에서 Turbo Stream 대기**:
```ruby
# ❌ 즉시 확인 - Turbo Stream 완료 전 실패 가능
click_button "좋아요"
assert_text "1"

# ✅ Turbo Stream 완료 대기
click_button "좋아요"
assert_selector "#likes_count_post_#{@post.id}", text: "1", wait: 3
```

### Stale Element 방지 (Turbo Stream 후)

```ruby
# ❌ 캐싱된 요소 - DOM 변경 후 실패
posts = all(".post-card")
posts.each { |p| p.find(".like-button").click }  # StaleElementError!

# ✅ JavaScript로 매번 새로 찾기
page.execute_script(<<~JS)
  document.querySelectorAll('.post-card').forEach(card => {
    const likeBtn = card.querySelector('.like-button');
    if (likeBtn) likeBtn.click();
  });
JS

# ✅ Ruby에서 반복마다 새로 찾기
all(".post-card").count.times do |i|
  find(".post-card:nth-child(#{i + 1}) .like-button").click
  sleep 0.3  # Turbo Stream 대기
end
```

### Polymorphic Association 테스트

```ruby
# test/models/like_test.rb
class LikeTest < ActiveSupport::TestCase
  test "like can belong to post" do
    like = Like.create!(user: users(:one), likeable: posts(:one))

    assert_equal "Post", like.likeable_type
    assert_equal posts(:one).id, like.likeable_id
    assert_includes posts(:one).likes, like
  end

  test "like can belong to comment" do
    like = Like.create!(user: users(:one), likeable: comments(:one))

    assert_equal "Comment", like.likeable_type
    assert_equal comments(:one).id, like.likeable_id
  end

  test "counter cache increments on create" do
    post = posts(:one)
    initial_count = post.likes_count

    Like.create!(user: users(:two), likeable: post)
    post.reload

    assert_equal initial_count + 1, post.likes_count
  end

  test "counter cache decrements on destroy" do
    like = likes(:post_like_one)
    post = like.likeable
    initial_count = post.likes_count

    like.destroy
    post.reload

    assert_equal initial_count - 1, post.likes_count
  end
end
```

### 권한 테스트 패턴

```ruby
test "cannot edit other user's post" do
  other_user = User.create!(name: "Other", email: "other@test.com", password: "password")
  other_post = Post.create!(title: "Other's post", content: "Content", user: other_user)

  sign_in @user  # 다른 사용자로 로그인

  patch post_path(other_post), params: { post: { title: "Hacked!" } }

  assert_response :redirect
  assert_equal "Other's post", other_post.reload.title  # 변경 안 됨
end
```

---

## 🔗 연계 스킬

| 스킬 | 사용 시점 |
|------|----------|
| `rails-resource` | 새 모델/컨트롤러 생성 |
| `test-gen` | 테스트 자동 생성 |

---

## 📚 참조 문서

- [CLAUDE.md - 프로젝트 특화 규칙](../../CLAUDE.md#프로젝트-특화-규칙-중요)
- [standards/rails-backend.md](../../standards/rails-backend.md)
- [rules/backend/rails-anti-patterns.md](../../rules/backend/rails-anti-patterns.md)
- [rules/testing/ci-troubleshooting.md](../../rules/testing/ci-troubleshooting.md)
