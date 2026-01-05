# frozen_string_literal: true

require "test_helper"

class FollowsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:one)
    @other_user = users(:two)
    @third_user = users(:three)
  end

  # =========================================
  # Authentication Tests
  # =========================================

  test "should redirect to login when not authenticated" do
    post follow_profile_path(@other_user)
    assert_redirected_to login_path
  end

  test "should require login for follow toggle" do
    assert_no_difference("Follow.count") do
      post follow_profile_path(@other_user)
    end
    assert_redirected_to login_path
  end

  # =========================================
  # Toggle Action Tests - Follow
  # =========================================

  test "should create follow when not following" do
    log_in_as(@user)

    assert_difference("Follow.count", 1) do
      post follow_profile_path(@other_user)
    end

    assert @user.following?(@other_user)
  end

  test "should respond with turbo_stream when following" do
    log_in_as(@user)

    post follow_profile_path(@other_user), as: :turbo_stream
    assert_response :success
    assert_match /turbo-stream/, response.content_type
    assert_match /follow-button-#{@other_user.id}/, response.body
  end

  test "should redirect when following via html" do
    log_in_as(@user)

    post follow_profile_path(@other_user)
    assert_response :redirect
  end

  test "should create notification when following" do
    log_in_as(@user)

    assert_difference("Notification.count", 1) do
      post follow_profile_path(@other_user)
    end

    notification = Notification.last
    assert_equal @other_user, notification.recipient
    assert_equal @user, notification.actor
    assert_equal "follow", notification.action
  end

  test "should update follower counter cache when following" do
    log_in_as(@user)

    initial_followers_count = @other_user.followers_count.to_i
    initial_following_count = @user.following_count.to_i

    post follow_profile_path(@other_user)

    @other_user.reload
    @user.reload

    assert_equal initial_followers_count + 1, @other_user.followers_count
    assert_equal initial_following_count + 1, @user.following_count
  end

  # =========================================
  # Toggle Action Tests - Unfollow
  # =========================================

  test "should destroy follow when already following" do
    log_in_as(@user)
    @user.follow(@other_user)

    assert @user.following?(@other_user)

    assert_difference("Follow.count", -1) do
      post follow_profile_path(@other_user)
    end

    assert_not @user.following?(@other_user)
  end

  test "should respond with turbo_stream when unfollowing" do
    log_in_as(@user)
    @user.follow(@other_user)

    post follow_profile_path(@other_user), as: :turbo_stream
    assert_response :success
    assert_match /turbo-stream/, response.content_type
    assert_match /follow-button-#{@other_user.id}/, response.body
  end

  test "should redirect when unfollowing via html" do
    log_in_as(@user)
    @user.follow(@other_user)

    post follow_profile_path(@other_user)
    assert_response :redirect
  end

  test "should update follower counter cache when unfollowing" do
    log_in_as(@user)
    @user.follow(@other_user)
    @other_user.reload
    @user.reload

    initial_followers_count = @other_user.followers_count
    initial_following_count = @user.following_count

    post follow_profile_path(@other_user)

    @other_user.reload
    @user.reload

    assert_equal initial_followers_count - 1, @other_user.followers_count
    assert_equal initial_following_count - 1, @user.following_count
  end

  # =========================================
  # Toggle Behavior Tests
  # =========================================

  test "should toggle follow state correctly on consecutive calls" do
    log_in_as(@user)

    # First call: follow
    post follow_profile_path(@other_user)
    assert @user.following?(@other_user)

    # Second call: unfollow
    post follow_profile_path(@other_user)
    assert_not @user.following?(@other_user)

    # Third call: follow again
    post follow_profile_path(@other_user)
    assert @user.following?(@other_user)
  end

  # =========================================
  # Edge Case Tests
  # =========================================

  test "should not allow following self" do
    log_in_as(@user)

    assert_no_difference("Follow.count") do
      post follow_profile_path(@user)
    end
  end

  test "should handle non-existent user gracefully" do
    log_in_as(@user)

    # In test environment, RecordNotFound is raised directly
    # In production, it would be caught and return 404
    begin
      post follow_profile_path(id: 999999)
      # If we get here, the exception was caught by Rails error handling
      assert_response :not_found
    rescue ActiveRecord::RecordNotFound
      # Expected behavior in development/test environment
      assert true
    end
  end

  test "should follow different users independently" do
    log_in_as(@user)

    # Follow first user
    post follow_profile_path(@other_user)
    assert @user.following?(@other_user)

    # Follow second user
    post follow_profile_path(@third_user)
    assert @user.following?(@third_user)

    # Both should be followed
    assert @user.following?(@other_user)
    assert @user.following?(@third_user)
    assert_equal 2, @user.following.count
  end

  # =========================================
  # Turbo Stream Response Content Tests
  # =========================================

  test "turbo_stream response should replace follow button with following state" do
    log_in_as(@user)

    post follow_profile_path(@other_user), as: :turbo_stream

    assert_response :success
    assert_match /action="replace"/, response.body
    assert_match /target="follow-button-#{@other_user.id}"/, response.body
  end

  test "turbo_stream response should replace follow button with unfollowing state" do
    log_in_as(@user)
    @user.follow(@other_user)

    post follow_profile_path(@other_user), as: :turbo_stream

    assert_response :success
    assert_match /action="replace"/, response.body
    assert_match /target="follow-button-#{@other_user.id}"/, response.body
  end

  # =========================================
  # Concurrent Request Tests
  # =========================================

  test "should handle duplicate follow attempts gracefully" do
    log_in_as(@user)

    # Create follow directly
    @user.follow(@other_user)

    # Try to follow again via controller (should unfollow due to toggle)
    assert_difference("Follow.count", -1) do
      post follow_profile_path(@other_user)
    end
  end
end
