# frozen_string_literal: true

require "test_helper"

class FollowTest < ActiveSupport::TestCase
  def setup
    @user1 = users(:one)
    @user2 = users(:two)
  end

  test "valid follow" do
    follow = Follow.new(follower: @user1, followed: @user2)
    assert follow.valid?
  end

  test "cannot follow self" do
    follow = Follow.new(follower: @user1, followed: @user1)
    assert_not follow.valid?
    assert_includes follow.errors[:followed_id], "자신을 팔로우할 수 없습니다"
  end

  test "unique follow relationship" do
    Follow.create!(follower: @user1, followed: @user2)
    duplicate = Follow.new(follower: @user1, followed: @user2)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:follower_id], "이미 팔로우 중입니다"
  end

  test "user following? method" do
    assert_not @user1.following?(@user2)
    @user1.follow(@user2)
    assert @user1.following?(@user2)
  end

  test "user follow method" do
    assert_difference "@user1.following.count", 1 do
      @user1.follow(@user2)
    end
  end

  test "user unfollow method" do
    @user1.follow(@user2)
    assert_difference "@user1.following.count", -1 do
      @user1.unfollow(@user2)
    end
  end

  test "user toggle_follow! method" do
    # Toggle on
    result = @user1.toggle_follow!(@user2)
    assert result
    assert @user1.following?(@user2)

    # Toggle off
    result = @user1.toggle_follow!(@user2)
    assert_not result
    assert_not @user1.following?(@user2)
  end

  test "counter cache updates" do
    assert_equal 0, @user2.followers_count

    @user1.follow(@user2)
    @user2.reload
    assert_equal 1, @user2.followers_count

    @user1.reload
    assert_equal 1, @user1.following_count
  end
end
