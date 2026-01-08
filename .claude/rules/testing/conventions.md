---
paths: test/**/*.rb
---

# 테스트 규칙 (Minitest)

## 테스트 파일 구조

```ruby
require "test_helper"

class UserTest < ActiveSupport::TestCase
  fixtures :users

  setup do
    @user = users(:one)
  end

  # ===== Validations =====
  test "should be valid with valid attributes" do
    assert @user.valid?
  end

  test "should require email" do
    @user.email = nil
    assert_not @user.valid?
    assert_includes @user.errors[:email], "can't be blank"
  end

  # ===== Associations =====
  test "should have many posts" do
    assert_respond_to @user, :posts
  end

  # ===== Scopes =====
  test "recent scope orders by created_at desc" do
    # ...
  end
end
```

## 네이밍 규칙

```ruby
# 파일명
test/models/user_test.rb
test/controllers/posts_controller_test.rb
test/services/users/deletion_service_test.rb

# 테스트 메서드명 (한글 가능)
test "should validate presence of title" do
test "로그인 후 리다이렉트" do
```

## Fixture 규칙

```yaml
# test/fixtures/users.yml
one:
  email: user1@example.com
  name: 테스트 사용자 1
  password_digest: <%= BCrypt::Password.create('password123', cost: 4) %>

# cost: 4 사용 - 테스트 속도 향상 (기본 12 대비 ~1000배 빠름)
```

## 컨트롤러 테스트

```ruby
class PostsControllerTest < ActionDispatch::IntegrationTest
  # 인증 필요 테스트
  test "should redirect create when not logged in" do
    post posts_url, params: { post: { title: "Test" } }
    assert_redirected_to login_url
  end

  # 인증 후 테스트
  test "should create post when logged in" do
    log_in_as(@user)

    assert_difference "Post.count", 1 do
      post posts_url, params: { post: { title: "New", content: "Content" } }
    end
  end

  private

  def log_in_as(user)
    post login_path, params: { email: user.email, password: "password123" }
  end
end
```

## 금지 패턴

```ruby
# ❌ sleep 사용 금지
sleep 2
assert_text "결과"

# ✅ wait 옵션 사용
assert_text "결과", wait: 5

# ❌ 하드코딩된 ID
User.find(1)

# ✅ Fixture 사용
users(:one)

# ❌ 테스트 간 의존성
test "first" do
  @shared = create_data
end
test "second" do
  use(@shared)  # 실패 위험!
end

# ✅ 독립적인 테스트
test "second" do
  data = create_data
  use(data)
end
```

## 커버리지 목표

| 영역 | 최소 커버리지 |
|------|-------------|
| 모델 Validations | 100% |
| 모델 Associations | 100% |
| 인증/인가 | 100% |
| 결제 로직 | 100% |
| 컨트롤러 (핵심) | 80% |
| 서비스 객체 | 80% |

## 테스트 실행

```bash
# 전체 테스트
bin/rails test

# 특정 파일
bin/rails test test/models/user_test.rb

# 에셋 빌드 건너뛰기 (CI용)
SKIP_ASSET_BUILD=true bin/rails test
```
