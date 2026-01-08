# frozen_string_literal: true

require "test_helper"

class PostTest < ActiveSupport::TestCase
  # =========================================
  # Fixtures & Setup
  # =========================================

  def setup
    @user = users(:one)
    @admin = users(:admin)
    @free_post = posts(:one)
    @question_post = posts(:two)
    @hiring_post = posts(:hiring_post)
    @seeking_post = posts(:seeking_post)
  end

  # =========================================
  # Validations
  # =========================================

  test "should be valid with valid attributes for community post" do
    post = Post.new(
      user: @user,
      title: "테스트 게시글",
      content: "이것은 테스트 내용입니다.",
      category: :free,
      status: :published
    )
    assert post.valid?
  end

  test "should require title" do
    post = Post.new(user: @user, content: "내용", category: :free)
    assert_not post.valid?
    assert_validation_error post, :title
  end

  test "should require content" do
    post = Post.new(user: @user, title: "제목", category: :free)
    assert_not post.valid?
    assert_validation_error post, :content
  end

  test "should validate title length" do
    post = Post.new(user: @user, title: "A" * 256, content: "내용", category: :free)
    assert_not post.valid?
    assert_validation_error post, :title
  end

  test "should require user" do
    post = Post.new(title: "제목", content: "내용", category: :free)
    assert_not post.valid?
    assert_validation_error post, :user
  end

  # =========================================
  # Outsourcing Validations (Hiring)
  # =========================================

  test "should require service_type for hiring posts" do
    post = Post.new(
      user: @user,
      title: "개발자 구인",
      content: "Rails 개발자를 찾습니다",
      category: :hiring,
      status: :published
    )
    assert_not post.valid?
    assert_validation_error post, :service_type
  end

  test "should allow optional work_type for hiring posts" do
    post = Post.new(
      user: @user,
      title: "개발자 구인",
      content: "Rails 개발자를 찾습니다",
      category: :hiring,
      service_type: "development",
      status: :published
    )
    # work_type은 선택적 필드로 변경됨
    assert post.valid?, "Post should be valid without work_type: #{post.errors.full_messages}"
  end

  test "should be valid with all required fields for hiring posts" do
    post = Post.new(
      user: @user,
      title: "개발자 구인",
      content: "Rails 개발자를 찾습니다",
      category: :hiring,
      service_type: "development",
      work_type: "remote",
      status: :published
    )
    assert post.valid?
  end

  # =========================================
  # Outsourcing Validations (Seeking)
  # =========================================

  test "should require service_type for seeking posts" do
    post = Post.new(
      user: @user,
      title: "Rails 개발합니다",
      content: "풀스택 개발 경험 5년",
      category: :seeking,
      status: :published
    )
    assert_not post.valid?
    assert_validation_error post, :service_type
  end

  test "should validate portfolio_url format for seeking posts" do
    post = Post.new(
      user: @user,
      title: "Rails 개발합니다",
      content: "풀스택 개발 경험 5년",
      category: :seeking,
      service_type: "development",
      portfolio_url: "invalid-url",
      status: :published
    )
    assert_not post.valid?
    assert_validation_error post, :portfolio_url
  end

  test "should allow blank portfolio_url for seeking posts" do
    post = Post.new(
      user: @user,
      title: "Rails 개발합니다",
      content: "풀스택 개발 경험 5년",
      category: :seeking,
      service_type: "development",
      portfolio_url: "",
      status: :published
    )
    assert post.valid?
  end

  test "should accept valid portfolio_url for seeking posts" do
    post = Post.new(
      user: @user,
      title: "Rails 개발합니다",
      content: "풀스택 개발 경험 5년",
      category: :seeking,
      service_type: "development",
      portfolio_url: "https://github.com/username",
      status: :published
    )
    assert post.valid?
  end

  # =========================================
  # Price Validation
  # =========================================

  test "should validate price is non-negative" do
    post = Post.new(
      user: @user,
      title: "개발자 구인",
      content: "Rails 개발자를 찾습니다",
      category: :hiring,
      service_type: "development",
      work_type: "remote",
      price: -1000,
      status: :published
    )
    assert_not post.valid?
    assert_validation_error post, :price
  end

  test "should allow nil price" do
    post = Post.new(
      user: @user,
      title: "개발자 구인",
      content: "Rails 개발자를 찾습니다",
      category: :hiring,
      service_type: "development",
      work_type: "remote",
      price: nil,
      status: :published
    )
    assert post.valid?
  end

  # =========================================
  # Associations
  # =========================================

  test "should have many comments" do
    assert_respond_to @free_post, :comments
    assert_kind_of ActiveRecord::Associations::CollectionProxy, @free_post.comments
  end

  test "should have many orders" do
    assert_respond_to @free_post, :orders
  end

  test "should have many notifications" do
    assert_respond_to @free_post, :notifications
  end

  test "should belong to user" do
    assert_respond_to @free_post, :user
    assert_kind_of User, @free_post.user
  end

  test "should destroy comments when destroyed" do
    post = Post.create!(
      user: @user,
      title: "삭제될 글",
      content: "테스트",
      category: :free,
      status: :published
    )
    comment = post.comments.create!(user: @admin, content: "댓글입니다")

    assert_difference "Comment.count", -1 do
      post.destroy
    end
  end

  # =========================================
  # Enums
  # =========================================

  test "should have status enum" do
    assert_equal({ "draft" => 0, "published" => 1, "archived" => 2 }, Post.statuses)
  end

  test "should have category enum" do
    expected = {
      "free" => 0,
      "question" => 1,
      "promotion" => 2,
      "hiring" => 3,
      "seeking" => 4
    }
    assert_equal expected, Post.categories
  end

  test "should default to draft status" do
    post = Post.new
    assert post.draft?
  end

  test "should default to free category" do
    post = Post.new
    assert post.free?
  end

  # =========================================
  # Scopes
  # =========================================

  test "published scope should only include published posts" do
    published_posts = Post.published
    published_posts.each do |post|
      assert post.published?
    end
  end

  test "recent scope should order by created_at desc" do
    recent_posts = Post.recent.limit(5)
    if recent_posts.size > 1
      recent_posts.each_cons(2) do |a, b|
        assert a.created_at >= b.created_at
      end
    end
  end

  test "community scope should include free, question, promotion posts" do
    community_posts = Post.community
    community_posts.each do |post|
      assert post.community?
    end
  end

  test "outsourcing scope should include hiring, seeking posts" do
    outsourcing_posts = Post.outsourcing
    outsourcing_posts.each do |post|
      assert post.outsourcing?
    end
  end

  test "by_category scope should filter by category" do
    free_posts = Post.by_category(:free)
    free_posts.each do |post|
      assert post.free?
    end
  end

  # =========================================
  # Instance Methods
  # =========================================

  test "outsourcing? should return true for hiring and seeking posts" do
    assert @hiring_post.outsourcing?
    assert @seeking_post.outsourcing?
    assert_not @free_post.outsourcing?
  end

  test "community? should return true for free, question, promotion posts" do
    assert @free_post.community?
    assert @question_post.community?
    assert_not @hiring_post.community?
  end

  test "category_label should return correct label" do
    assert_equal "자유", @free_post.category_label
    assert_equal "질문", @question_post.category_label
    # hiring/seeking은 UI에서 Makers/Projects로 표시
    assert_equal "Makers", @hiring_post.category_label
    assert_equal "Projects", @seeking_post.category_label
  end

  test "increment_views! should increase views_count" do
    initial_views = @free_post.views_count
    @free_post.increment_views!
    assert_equal initial_views + 1, @free_post.reload.views_count
  end

  # =========================================
  # Price Display Methods
  # =========================================

  test "price_display should return formatted price" do
    post = Post.new(price: 1000000)
    assert_equal "1,000,000원", post.price_display
  end

  test "price_display should return 협의 for negotiable or nil price" do
    post = Post.new(price: nil)
    assert_equal "협의", post.price_display

    post.price = 0
    assert_equal "협의", post.price_display

    post.price = 100
    post.price_negotiable = true
    assert_equal "협의", post.price_display
  end

  test "skills_array should split skills string" do
    post = Post.new(skills: "Ruby, Rails, JavaScript")
    assert_equal [ "Ruby", "Rails", "JavaScript" ], post.skills_array
  end

  test "skills_array should return empty array for blank skills" do
    post = Post.new(skills: nil)
    assert_equal [], post.skills_array
  end

  # =========================================
  # Payment Related Methods
  # =========================================

  test "payable? should return true for outsourcing with price" do
    @hiring_post.price = 100000
    assert @hiring_post.payable?
  end

  test "payable? should return false for community posts" do
    @free_post.price = 100000
    assert_not @free_post.payable?
  end

  test "payable? should return false for posts without price" do
    @hiring_post.price = nil
    assert_not @hiring_post.payable?
  end

  test "owned_by? should return true for post owner" do
    assert @free_post.owned_by?(@free_post.user)
  end

  test "owned_by? should return false for other users" do
    assert_not @free_post.owned_by?(@admin)
  end

  test "owned_by? should return false for nil user" do
    assert_not @free_post.owned_by?(nil)
  end

  # =========================================
  # Content Snippet Method
  # =========================================

  test "content_snippet should truncate long content" do
    post = Post.new(content: "A" * 200)
    snippet = post.content_snippet(nil, max_length: 50)
    assert snippet.length <= 53  # 50 + "..." 허용
  end

  test "content_snippet should highlight query location" do
    post = Post.new(content: "This is a test post with Rails keyword in the middle of the content")
    snippet = post.content_snippet("Rails")
    assert_includes snippet, "Rails"
  end

  # =========================================
  # Work Type Label Methods
  # =========================================

  test "work_type_label should return Korean label" do
    @hiring_post.work_type = "remote"
    assert_equal "재택(원격)", @hiring_post.work_type_label

    @hiring_post.work_type = "onsite"
    assert_equal "오프라인(상주)", @hiring_post.work_type_label
  end

  test "service_type_label should return Korean label" do
    @hiring_post.service_type = "development"
    assert_equal "개발", @hiring_post.service_type_label

    @hiring_post.service_type = "design"
    assert_equal "디자인", @hiring_post.service_type_label
  end

  # =========================================
  # Availability Methods
  # =========================================

  test "availability_label should return correct label" do
    post = Post.new(available_now: true)
    assert_equal "작업 가능", post.availability_label

    post.available_now = false
    assert_equal "작업 불가", post.availability_label
  end

  test "availability_color_class should return correct class" do
    post = Post.new(available_now: true)
    assert_includes post.availability_color_class, "green"

    post.available_now = false
    assert_includes post.availability_color_class, "gray"
  end

  # =========================================
  # Constants
  # =========================================

  test "should have MAX_IMAGES constant" do
    assert_equal 5, Post::MAX_IMAGES
  end

  test "should have MAX_IMAGE_SIZE constant" do
    assert_equal 5.megabytes, Post::MAX_IMAGE_SIZE
  end

  test "should have SERVICE_TYPES constant" do
    assert_includes Post::SERVICE_TYPES.keys, "development"
    assert_includes Post::SERVICE_TYPES.keys, "design"
  end

  test "should have WORK_TYPES constant" do
    assert_includes Post::WORK_TYPES.keys, "remote"
    assert_includes Post::WORK_TYPES.keys, "onsite"
  end
end
