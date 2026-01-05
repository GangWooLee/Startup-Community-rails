# frozen_string_literal: true

require "test_helper"

class LikesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_user = users(:two)
    @post = posts(:one)
    @unliked_post = posts(:two) # user two likes post one, but not post two
  end

  # =========================================
  # Authentication Tests
  # =========================================

  test "should redirect to login when not authenticated (HTML)" do
    post like_post_path(@post)
    assert_redirected_to login_path
    assert_equal "로그인이 필요합니다.", flash[:alert]
  end

  test "should return unauthorized when not authenticated (JSON)" do
    post like_post_path(@post), as: :json
    assert_response :unauthorized
    json_response = JSON.parse(response.body)
    assert_equal "로그인이 필요합니다.", json_response["error"]
  end

  test "should not create like when not authenticated" do
    assert_no_difference("Like.count") do
      post like_post_path(@post)
    end
  end

  # =========================================
  # Toggle Like Action Tests - Like (Create)
  # =========================================

  test "should create like when not liked" do
    log_in_as(@user)

    assert_difference("Like.count", 1) do
      post like_post_path(@unliked_post)
    end

    assert @unliked_post.liked_by?(@user)
  end

  test "should respond with turbo_stream when liking" do
    log_in_as(@user)

    post like_post_path(@unliked_post), as: :turbo_stream
    assert_response :success
    assert_match(/turbo-stream/, response.content_type)
    assert_match(/like-button-#{@unliked_post.id}/, response.body)
    assert_match(/replace/, response.body)
  end

  test "should redirect back when liking via HTML" do
    log_in_as(@user)

    post like_post_path(@unliked_post)
    assert_response :redirect
  end

  test "should respond with JSON when liking" do
    log_in_as(@user)

    post like_post_path(@unliked_post), as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    assert json_response["liked"]
    assert_not_nil json_response["likes_count"]
  end

  test "should update likes counter cache when liking" do
    log_in_as(@user)

    initial_count = @unliked_post.likes_count.to_i

    post like_post_path(@unliked_post), as: :json

    @unliked_post.reload
    assert_equal initial_count + 1, @unliked_post.likes_count
  end

  # =========================================
  # Toggle Like Action Tests - Unlike (Delete)
  # =========================================

  test "should destroy like when already liked" do
    log_in_as(@other_user)
    # other_user already likes post one via fixture

    assert @post.liked_by?(@other_user)

    assert_difference("Like.count", -1) do
      post like_post_path(@post)
    end

    assert_not @post.liked_by?(@other_user)
  end

  test "should respond with turbo_stream when unliking" do
    log_in_as(@other_user)

    post like_post_path(@post), as: :turbo_stream
    assert_response :success
    assert_match(/turbo-stream/, response.content_type)
    assert_match(/like-button-#{@post.id}/, response.body)
  end

  test "should respond with JSON when unliking" do
    log_in_as(@other_user)

    post like_post_path(@post), as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_not json_response["liked"]
  end

  test "should update likes counter cache when unliking" do
    log_in_as(@other_user)

    initial_count = @post.likes_count

    post like_post_path(@post), as: :json

    @post.reload
    assert_equal initial_count - 1, @post.likes_count
  end

  # =========================================
  # Toggle Behavior Tests
  # =========================================

  test "should toggle like state correctly on consecutive calls" do
    log_in_as(@user)

    # First call: like
    post like_post_path(@unliked_post), as: :json
    assert @unliked_post.reload.liked_by?(@user)

    # Second call: unlike
    post like_post_path(@unliked_post), as: :json
    assert_not @unliked_post.reload.liked_by?(@user)

    # Third call: like again
    post like_post_path(@unliked_post), as: :json
    assert @unliked_post.reload.liked_by?(@user)
  end

  # =========================================
  # Edge Cases (rescue_from handles RecordNotFound in non-dev environments)
  # =========================================

  test "should return 404 for non-existent post" do
    log_in_as(@user)

    post like_post_path(id: 999999)
    assert_response :not_found
  end

  test "should like own post" do
    log_in_as(@user)
    # Post one belongs to user one

    assert_difference("Like.count", 1) do
      post like_post_path(@post)
    end

    assert @post.liked_by?(@user)
  end

  test "should like different posts independently" do
    log_in_as(@user)

    post like_post_path(@post), as: :json
    post like_post_path(@unliked_post), as: :json

    assert @post.reload.liked_by?(@user)
    assert @unliked_post.reload.liked_by?(@user)
  end

  # =========================================
  # Response Content Tests
  # =========================================

  test "turbo_stream response contains partial with correct locals" do
    log_in_as(@user)

    post like_post_path(@unliked_post), as: :turbo_stream

    assert_response :success
    # Should contain the like button partial
    assert_match(/action="replace"/, response.body)
    assert_match(/target="like-button-#{@unliked_post.id}"/, response.body)
  end

  test "json response contains all required fields" do
    log_in_as(@user)

    post like_post_path(@unliked_post), as: :json

    json_response = JSON.parse(response.body)
    assert json_response.key?("liked")
    assert json_response.key?("likes_count")
  end
end
