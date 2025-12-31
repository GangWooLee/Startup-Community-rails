# Testing Standards

> Agent OS 스타일 표준 규칙 - Minitest 기반 테스트 작성 시 준수해야 할 규칙들

## 1. 테스트 구조

### 디렉토리 구조
```
test/
├── controllers/         # 컨트롤러 테스트 (Integration)
├── models/              # 모델 테스트 (Unit)
├── system/              # E2E 테스트 (Capybara)
├── helpers/             # 헬퍼 테스트
├── jobs/                # 백그라운드 작업 테스트
├── services/            # 서비스 객체 테스트
├── mailers/             # 메일러 테스트
├── fixtures/            # 테스트 데이터
└── test_helper.rb       # 테스트 설정
```

### 테스트 파일 네이밍
```ruby
# 모델 테스트
test/models/user_test.rb
test/models/post_test.rb

# 컨트롤러 테스트
test/controllers/posts_controller_test.rb
test/controllers/sessions_controller_test.rb

# 시스템 테스트
test/system/login_test.rb
test/system/posts_test.rb

# 서비스 테스트
test/services/users/deletion_service_test.rb
```

## 2. 모델 테스트

### 기본 구조
```ruby
require "test_helper"

class UserTest < ActiveSupport::TestCase
  # Fixtures 사용 선언
  fixtures :users

  # Setup (각 테스트 전 실행)
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

  test "should require unique email" do
    duplicate = @user.dup
    duplicate.email = @user.email.upcase
    assert_not duplicate.valid?
  end

  test "should validate email format" do
    invalid_emails = ["invalid", "test@", "@test.com", "test@.com"]
    invalid_emails.each do |email|
      @user.email = email
      assert_not @user.valid?, "#{email} should be invalid"
    end
  end

  test "should validate password length" do
    @user.password = "short"
    assert_not @user.valid?
    assert_includes @user.errors[:password], "는 최소 8자 이상이어야 합니다"
  end

  # ===== Associations =====

  test "should have many posts" do
    assert_respond_to @user, :posts
  end

  test "should destroy dependent posts on user deletion" do
    @user.posts.create!(title: "Test", content: "Content")
    assert_difference "Post.count", -1 do
      @user.destroy
    end
  end

  # ===== Scopes =====

  test "recent scope orders by created_at desc" do
    old_user = User.create!(email: "old@test.com", name: "Old", password: "password123")
    old_user.update_column(:created_at, 1.day.ago)

    recent = User.recent.first
    assert_equal @user, recent
  end

  # ===== Instance Methods =====

  test "should authenticate with correct password" do
    assert @user.authenticate("password123")
  end

  test "should not authenticate with wrong password" do
    assert_not @user.authenticate("wrongpassword")
  end

  test "should generate remember token" do
    @user.remember
    assert_not_nil @user.remember_token
    assert_not_nil @user.remember_digest
  end

  # ===== Class Methods =====

  test "should find or create from OAuth" do
    auth = mock_oauth_hash("google_oauth2", "123", "test@example.com")
    result = User.from_omniauth(auth)

    assert result[:user].persisted?
    assert_equal "test@example.com", result[:user].email
  end

  private

  def mock_oauth_hash(provider, uid, email)
    OmniAuth::AuthHash.new(
      provider: provider,
      uid: uid,
      info: { email: email, name: "Test User" }
    )
  end
end
```

### 테스트 카테고리별 분류
```ruby
# 검증 테스트
test "validation: email presence" do
  # ...
end

# 연관관계 테스트
test "association: has_many posts" do
  # ...
end

# 콜백 테스트
test "callback: downcases email before save" do
  # ...
end

# 스코프 테스트
test "scope: recent returns ordered results" do
  # ...
end
```

## 3. 컨트롤러 테스트

### 기본 구조
```ruby
require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  fixtures :users, :posts

  setup do
    @user = users(:one)
    @post = posts(:one)
  end

  # ===== Index =====

  test "should get index" do
    get posts_url
    assert_response :success
    assert_select "h1", "커뮤니티"
  end

  test "should get index as JSON" do
    get posts_url, as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert json.is_a?(Array)
  end

  # ===== Show =====

  test "should show post" do
    get post_url(@post)
    assert_response :success
    assert_select "h1", @post.title
  end

  test "should return 404 for non-existent post" do
    get post_url(id: 999999)
    assert_response :not_found
  end

  # ===== Create (인증 필요) =====

  test "should redirect create when not logged in" do
    post posts_url, params: { post: { title: "Test", content: "Content" } }
    assert_redirected_to login_url
  end

  test "should create post when logged in" do
    log_in_as(@user)

    assert_difference "Post.count", 1 do
      post posts_url, params: {
        post: { title: "New Post", content: "New Content", category: "free" }
      }
    end

    assert_redirected_to post_url(Post.last)
    follow_redirect!
    assert_select ".flash-notice", "게시글이 작성되었습니다."
  end

  test "should not create post with invalid params" do
    log_in_as(@user)

    assert_no_difference "Post.count" do
      post posts_url, params: {
        post: { title: "", content: "" }
      }
    end

    assert_response :unprocessable_entity
    assert_select ".error-message"
  end

  # ===== Update =====

  test "should update own post" do
    log_in_as(@user)

    patch post_url(@post), params: {
      post: { title: "Updated Title" }
    }

    assert_redirected_to post_url(@post)
    @post.reload
    assert_equal "Updated Title", @post.title
  end

  test "should not update other user's post" do
    other_user = users(:two)
    log_in_as(other_user)

    patch post_url(@post), params: {
      post: { title: "Hacked" }
    }

    assert_redirected_to root_url
    @post.reload
    assert_not_equal "Hacked", @post.title
  end

  # ===== Delete =====

  test "should destroy own post" do
    log_in_as(@user)

    assert_difference "Post.count", -1 do
      delete post_url(@post)
    end

    assert_redirected_to posts_url
  end

  # ===== Turbo Stream =====

  test "should respond with turbo stream on create" do
    log_in_as(@user)

    post posts_url, params: {
      post: { title: "Test", content: "Content", category: "free" }
    }, as: :turbo_stream

    assert_response :success
    assert_match /turbo-stream/, response.body
  end

  private

  def log_in_as(user)
    post login_url, params: {
      email: user.email,
      password: "password123"
    }
  end
end
```

### 인증 테스트 헬퍼
```ruby
# test/test_helper.rb
class ActionDispatch::IntegrationTest
  def log_in_as(user, password: "password123", remember_me: "0")
    post login_path, params: {
      email: user.email,
      password: password,
      remember_me: remember_me
    }
  end

  def log_out
    delete logout_path
  end

  def is_logged_in?
    !session[:user_id].nil?
  end
end
```

## 4. 시스템 테스트 (E2E)

### 기본 구조
```ruby
require "application_system_test_case"

class LoginTest < ApplicationSystemTestCase
  fixtures :users

  setup do
    @user = users(:one)
  end

  test "visiting login page" do
    visit login_url
    assert_selector "h1", text: "로그인"
    assert_selector "input[type='email']"
    assert_selector "input[type='password']"
  end

  test "logging in with valid credentials" do
    visit login_url

    fill_in "이메일", with: @user.email
    fill_in "비밀번호", with: "password123"
    click_button "로그인"

    assert_text "환영합니다"
    assert_current_path community_path
  end

  test "logging in with invalid credentials" do
    visit login_url

    fill_in "이메일", with: @user.email
    fill_in "비밀번호", with: "wrongpassword"
    click_button "로그인"

    assert_text "이메일 또는 비밀번호가 올바르지 않습니다"
    assert_current_path login_path
  end

  test "remember me checkbox" do
    visit login_url

    fill_in "이메일", with: @user.email
    fill_in "비밀번호", with: "password123"
    check "로그인 상태 유지"
    click_button "로그인"

    # 쿠키 확인
    assert page.driver.browser.manage.cookie_named("user_id")
  end
end
```

### 채팅 시스템 테스트 (실시간)
```ruby
class ChatTest < ApplicationSystemTestCase
  include ActionCable::TestHelper

  fixtures :users, :chat_rooms

  test "sending a message updates both users" do
    user1 = users(:one)
    user2 = users(:two)
    chat_room = chat_rooms(:one)

    # 두 브라우저 세션에서 테스트
    using_session(:user1) do
      log_in_as(user1)
      visit chat_room_path(chat_room)
    end

    using_session(:user2) do
      log_in_as(user2)
      visit chat_room_path(chat_room)
    end

    # User1이 메시지 전송
    using_session(:user1) do
      fill_in "message_content", with: "Hello!"
      click_button "전송"
      assert_selector "[data-message-content='Hello!']"
    end

    # User2에게도 메시지가 표시되는지 확인
    using_session(:user2) do
      assert_selector "[data-message-content='Hello!']"
    end
  end
end
```

### JavaScript 상호작용 테스트
```ruby
test "modal opens and closes" do
  visit posts_path

  click_button "새 글 작성"
  assert_selector ".modal", visible: true

  click_button "취소"
  assert_no_selector ".modal", visible: true
end

test "live search shows results" do
  visit root_path

  fill_in "검색", with: "테스트"

  # Ajax 결과 대기
  assert_selector ".search-results", wait: 5
  assert_text "검색 결과"
end

test "infinite scroll loads more posts" do
  # 충분한 데이터 생성
  20.times { |i| Post.create!(title: "Post #{i}", content: "Content", user: @user) }

  visit posts_path

  # 초기 로드 확인
  assert_selector ".post-card", count: 10

  # 스크롤
  page.execute_script("window.scrollTo(0, document.body.scrollHeight)")

  # 추가 로드 확인
  assert_selector ".post-card", count: 20, wait: 5
end
```

## 5. 서비스 객체 테스트

### 기본 구조
```ruby
require "test_helper"

class Users::DeletionServiceTest < ActiveSupport::TestCase
  fixtures :users

  setup do
    @user = users(:one)
  end

  test "should delete user successfully" do
    service = Users::DeletionService.new(@user, reason: "테스트")
    result = service.call

    assert result
    assert @user.reload.deleted?
    assert_not_nil @user.deleted_at
  end

  test "should anonymize user data" do
    original_email = @user.email
    service = Users::DeletionService.new(@user)
    service.call

    @user.reload
    assert_not_equal original_email, @user.email
    assert_equal "탈퇴한 사용자", @user.name
  end

  test "should create deletion record" do
    assert_difference "UserDeletion.count", 1 do
      Users::DeletionService.new(@user, reason: "테스트 탈퇴").call
    end

    deletion = UserDeletion.last
    assert_equal @user.id, deletion.user_id
    assert_equal "테스트 탈퇴", deletion.reason
  end

  test "should destroy OAuth identities" do
    @user.oauth_identities.create!(provider: "google", uid: "123")

    assert_difference "OauthIdentity.count", -1 do
      Users::DeletionService.new(@user).call
    end
  end

  test "should fail with nil user" do
    service = Users::DeletionService.new(nil)
    result = service.call

    assert_not result
    assert_includes service.errors, "사용자를 찾을 수 없습니다"
  end

  test "should rollback on error" do
    # 트랜잭션 롤백 테스트
    User.any_instance.stubs(:update!).raises(ActiveRecord::RecordInvalid)

    original_email = @user.email
    service = Users::DeletionService.new(@user)
    result = service.call

    assert_not result
    @user.reload
    assert_equal original_email, @user.email
  end
end
```

## 6. 백그라운드 작업 테스트

### 기본 구조
```ruby
require "test_helper"

class AiAnalysisJobTest < ActiveJob::TestCase
  fixtures :users, :idea_analyses

  setup do
    @analysis = idea_analyses(:one)
  end

  test "should process analysis" do
    # Mock AI 서비스
    AI::Orchestrators::AnalysisOrchestrator.any_instance
      .stubs(:analyze)
      .returns({ summary: "Test result" })

    AiAnalysisJob.perform_now(@analysis.id)

    @analysis.reload
    assert_equal "completed", @analysis.status
    assert_equal "Test result", @analysis.analysis_result[:summary]
  end

  test "should enqueue job" do
    assert_enqueued_with(job: AiAnalysisJob, args: [@analysis.id]) do
      AiAnalysisJob.perform_later(@analysis.id)
    end
  end

  test "should retry on failure" do
    AI::Orchestrators::AnalysisOrchestrator.any_instance
      .stubs(:analyze)
      .raises(StandardError, "API Error")

    assert_raises(StandardError) do
      AiAnalysisJob.perform_now(@analysis.id)
    end

    # 재시도 설정 확인
    assert AiAnalysisJob.new.executions < 3
  end

  test "should discard on record not found" do
    assert_nothing_raised do
      AiAnalysisJob.perform_now(999999)
    end
  end
end
```

## 7. Fixtures 작성

### 기본 패턴
```yaml
# test/fixtures/users.yml
one:
  email: user1@example.com
  name: 테스트 사용자 1
  password_digest: <%= BCrypt::Password.create('password123') %>
  created_at: <%= Time.current %>
  updated_at: <%= Time.current %>

two:
  email: user2@example.com
  name: 테스트 사용자 2
  password_digest: <%= BCrypt::Password.create('password123') %>

admin:
  email: admin@example.com
  name: 관리자
  password_digest: <%= BCrypt::Password.create('password123') %>
  is_admin: true

deleted:
  email: deleted_123@deleted.local
  name: 탈퇴한 사용자
  deleted_at: <%= 1.day.ago %>
```

```yaml
# test/fixtures/posts.yml
one:
  title: 첫 번째 게시글
  content: 테스트 내용입니다.
  category: free
  user: one
  created_at: <%= Time.current %>

two:
  title: 두 번째 게시글
  content: 또 다른 테스트 내용
  category: question
  user: two

hiring:
  title: 개발자 구합니다
  content: React 개발자 모집
  category: hiring
  user: one
```

### 관계 설정
```yaml
# test/fixtures/comments.yml
one:
  content: 좋은 글이네요!
  user: two
  post: one

# test/fixtures/likes.yml
one:
  user: two
  likeable: one (Post)
```

## 8. 테스트 헬퍼

### test_helper.rb 설정
```ruby
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/autorun"

# Capybara 설정
require "capybara/rails"
require "capybara/minitest"

class ActiveSupport::TestCase
  # 병렬 테스트
  parallelize(workers: :number_of_processors)

  # Fixtures 로드
  fixtures :all

  # 공통 헬퍼 메서드
  def assert_logged_in
    assert session[:user_id].present?, "Expected user to be logged in"
  end

  def assert_not_logged_in
    assert_nil session[:user_id], "Expected user to not be logged in"
  end
end

class ActionDispatch::IntegrationTest
  include Capybara::DSL
  include Capybara::Minitest::Assertions

  def log_in_as(user, password: "password123")
    post login_path, params: { email: user.email, password: password }
  end

  def teardown
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end
end
```

### Custom Assertions
```ruby
# test/support/custom_assertions.rb
module CustomAssertions
  def assert_flash(type, message)
    assert_select ".flash-#{type}", text: message
  end

  def assert_validation_error(field, message)
    assert_select ".field-error[data-field='#{field}']", text: message
  end

  def assert_turbo_stream(action, target)
    assert_select "turbo-stream[action='#{action}'][target='#{target}']"
  end
end

class ActiveSupport::TestCase
  include CustomAssertions
end
```

## 9. 테스트 실행

### 명령어
```bash
# 전체 테스트
bin/rails test

# 특정 파일
bin/rails test test/models/user_test.rb

# 특정 테스트
bin/rails test test/models/user_test.rb:25

# 시스템 테스트
bin/rails test:system

# 병렬 실행
PARALLEL_WORKERS=4 bin/rails test

# 에셋 빌드 건너뛰기 (CI용)
SKIP_ASSET_BUILD=true bin/rails test

# 상세 출력
bin/rails test --verbose
```

### CI 설정 예시
```yaml
# .github/workflows/test.yml
test:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: ruby/setup-ruby@v1
      with:
        bundler-cache: true
    - run: bin/rails db:prepare
    - run: SKIP_ASSET_BUILD=true bin/rails test
    - run: bin/rails test:system
```

## 10. 테스트 커버리지 목표

| 영역 | 최소 커버리지 | 우선순위 |
|------|---------------|----------|
| 모델 (Validations) | 100% | 필수 |
| 모델 (Associations) | 100% | 필수 |
| 인증/인가 | 100% | 필수 |
| 결제 로직 | 100% | 필수 |
| 컨트롤러 (핵심) | 80% | 높음 |
| 서비스 객체 | 80% | 높음 |
| 시스템 테스트 | 60% | 중간 |
| 헬퍼 | 50% | 낮음 |

## 11. 금지 사항

```ruby
# ❌ 테스트에서 sleep 사용 금지
sleep 2
assert_text "결과"

# ✅ 올바른 대기
assert_text "결과", wait: 5

# ❌ 하드코딩된 ID
User.find(1)

# ✅ Fixture 사용
users(:one)

# ❌ 테스트 간 의존성
test "first" do
  @shared_data = create_data
end
test "second" do
  use(@shared_data)  # 실패 위험!
end

# ✅ 독립적인 테스트
test "second" do
  data = create_data  # 각 테스트에서 생성
  use(data)
end
```
