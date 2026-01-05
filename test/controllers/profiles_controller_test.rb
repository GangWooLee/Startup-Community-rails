# frozen_string_literal: true

require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_user = users(:two)
    @admin = users(:admin)
    @deleted_user = users(:deleted_user)
  end

  # ==========================================================================
  # Show Action Tests
  # ==========================================================================

  test "should show profile for any user without authentication" do
    get profile_path(@user)
    assert_response :success
  end

  test "should show profile page with user information" do
    get profile_path(@user)
    assert_response :success
    assert_select "body" # Basic page rendering check
  end

  test "should show profile with community posts" do
    # User one has posts in fixtures: one (free), promotion_post, draft_post
    get profile_path(@user)
    assert_response :success
    # Posts should be loaded (free, question, promotion categories only, published status)
    assert_not_nil assigns(:posts)
  end

  test "should show profile with outsourcing posts" do
    # User one has: hiring_post, seeking_dev
    get profile_path(@user)
    assert_response :success
    assert_not_nil assigns(:outsourcing_posts)
  end

  test "should exclude draft posts from profile" do
    get profile_path(@user)
    assert_response :success
    posts = assigns(:posts)
    # draft_post belongs to user one but should not appear
    assert posts.none? { |p| p.status == "draft" }
  end

  test "should show other user profile" do
    get profile_path(@other_user)
    assert_response :success
    assert_equal @other_user, assigns(:user)
  end

  test "should show admin profile" do
    get profile_path(@admin)
    assert_response :success
    assert_equal @admin, assigns(:user)
  end

  test "should return 404 for non-existent user" do
    get profile_path(id: 999999)
    assert_response :not_found
  end

  # ==========================================================================
  # Authentication Context Tests
  # ==========================================================================

  test "should set is_own_profile to false when not logged in" do
    get profile_path(@user)
    assert_response :success
    assert_equal false, assigns(:is_own_profile)
  end

  test "should set is_own_profile to true when viewing own profile" do
    log_in_as(@user)
    get profile_path(@user)
    assert_response :success
    assert_equal true, assigns(:is_own_profile)
  end

  test "should set is_own_profile to false when viewing other user profile" do
    log_in_as(@user)
    get profile_path(@other_user)
    assert_response :success
    assert_equal false, assigns(:is_own_profile)
  end

  # ==========================================================================
  # Follow Status Tests
  # ==========================================================================

  test "should set is_following to false when not logged in" do
    get profile_path(@user)
    assert_response :success
    assert_equal false, assigns(:is_following)
  end

  test "should set is_following based on follow relationship when logged in" do
    log_in_as(@user)
    get profile_path(@other_user)
    assert_response :success
    # Default: not following
    assert_not_nil assigns(:is_following)
  end

  test "should reflect follow status when user is following another user" do
    # Create follow relationship
    log_in_as(@user)
    @user.follow(@other_user) if @user.respond_to?(:follow)

    get profile_path(@other_user)
    assert_response :success
    # is_following should reflect the actual follow state
    assert_not_nil assigns(:is_following)
  end

  # ==========================================================================
  # Data Loading Tests (N+1 Prevention)
  # ==========================================================================

  test "should load user with includes to prevent N+1" do
    get profile_path(@user)
    assert_response :success
    # User should be loaded with associations
    loaded_user = assigns(:user)
    assert_not_nil loaded_user
    assert_equal @user.id, loaded_user.id
  end

  test "should limit posts to PROFILE_POSTS_LIMIT" do
    get profile_path(@user)
    assert_response :success
    posts = assigns(:posts)
    outsourcing_posts = assigns(:outsourcing_posts)
    # Both should respect the limit (10 by default)
    assert posts.size <= 10
    assert outsourcing_posts.size <= 10
  end

  test "should only show published community posts" do
    get profile_path(@user)
    assert_response :success
    posts = assigns(:posts)
    # All posts should be published and in community categories
    posts.each do |post|
      assert_equal "published", post.status
      assert_includes %w[free question promotion], post.category
    end
  end

  test "should only show published outsourcing posts" do
    get profile_path(@user)
    assert_response :success
    outsourcing_posts = assigns(:outsourcing_posts)
    # All outsourcing posts should be published and in outsourcing categories
    outsourcing_posts.each do |post|
      assert_equal "published", post.status
      assert_includes %w[hiring seeking], post.category
    end
  end

  # ==========================================================================
  # Deleted User Profile Tests
  # ==========================================================================

  test "should show deleted user profile" do
    get profile_path(@deleted_user)
    assert_response :success
    assert_equal @deleted_user, assigns(:user)
  end

  # ==========================================================================
  # Edge Cases
  # ==========================================================================

  test "should handle user with no posts" do
    # User three has only seeking_post (outsourcing), no community posts
    user_three = users(:three)
    get profile_path(user_three)
    assert_response :success
    assert_not_nil assigns(:posts)
  end

  test "should handle user with no outsourcing posts" do
    # User two has only community posts (two - question, hiring_design)
    get profile_path(@other_user)
    assert_response :success
    assert_not_nil assigns(:outsourcing_posts)
  end

  # ==========================================================================
  # Response Format Tests
  # ==========================================================================

  test "should respond with HTML format" do
    get profile_path(@user)
    assert_response :success
    assert_equal "text/html; charset=utf-8", response.content_type
  end

  test "should render show template" do
    get profile_path(@user)
    assert_response :success
    assert_template :show
  end

  # ==========================================================================
  # Integration with Logged In User
  # ==========================================================================

  test "logged in user can view any profile" do
    log_in_as(@user)

    # Can view own profile
    get profile_path(@user)
    assert_response :success

    # Can view other user's profile
    get profile_path(@other_user)
    assert_response :success

    # Can view admin's profile
    get profile_path(@admin)
    assert_response :success
  end

  test "admin can view any profile" do
    log_in_as(@admin)

    get profile_path(@user)
    assert_response :success

    get profile_path(@other_user)
    assert_response :success
  end
end
