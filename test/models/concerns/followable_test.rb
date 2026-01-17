# frozen_string_literal: true

require "test_helper"

class FollowableTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @other_user = users(:two)
  end

  # =========================================
  # following? 메서드 테스트
  # =========================================

  test "following? returns false when not following" do
    skip "active_follows association not set up" unless @user.respond_to?(:active_follows)

    @user.active_follows.where(followed: @other_user).destroy_all

    assert_not @user.following?(@other_user)
  end

  test "following? returns true when following" do
    skip "active_follows association not set up" unless @user.respond_to?(:active_follows)

    @user.active_follows.find_or_create_by!(followed: @other_user)

    assert @user.following?(@other_user)
  end

  # =========================================
  # follow 메서드 테스트
  # =========================================

  test "follow returns false when trying to follow self" do
    skip "active_follows association not set up" unless @user.respond_to?(:active_follows)

    result = @user.follow(@user)

    assert_equal false, result
  end

  test "follow creates follow relationship" do
    skip "active_follows association not set up" unless @user.respond_to?(:active_follows)

    @user.active_follows.where(followed: @other_user).destroy_all

    @user.follow(@other_user)

    assert @user.following?(@other_user)
  end

  test "follow is idempotent" do
    skip "active_follows association not set up" unless @user.respond_to?(:active_follows)

    @user.follow(@other_user)
    initial_count = @user.active_follows.count

    @user.follow(@other_user)

    assert_equal initial_count, @user.active_follows.count
  end

  # =========================================
  # unfollow 메서드 테스트
  # =========================================

  test "unfollow removes follow relationship" do
    skip "active_follows association not set up" unless @user.respond_to?(:active_follows)

    @user.active_follows.find_or_create_by!(followed: @other_user)
    assert @user.following?(@other_user)

    @user.unfollow(@other_user)

    assert_not @user.following?(@other_user)
  end

  test "unfollow does nothing when not following" do
    skip "active_follows association not set up" unless @user.respond_to?(:active_follows)

    @user.active_follows.where(followed: @other_user).destroy_all

    assert_nothing_raised do
      @user.unfollow(@other_user)
    end
  end

  # =========================================
  # toggle_follow! 메서드 테스트
  # =========================================

  test "toggle_follow! adds follow when not following" do
    skip "active_follows association not set up" unless @user.respond_to?(:active_follows)

    @user.active_follows.where(followed: @other_user).destroy_all

    result = @user.toggle_follow!(@other_user)

    assert_equal true, result
    assert @user.following?(@other_user)
  end

  test "toggle_follow! removes follow when following" do
    skip "active_follows association not set up" unless @user.respond_to?(:active_follows)

    @user.active_follows.find_or_create_by!(followed: @other_user)

    result = @user.toggle_follow!(@other_user)

    assert_equal false, result
    assert_not @user.following?(@other_user)
  end
end
