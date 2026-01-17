# frozen_string_literal: true

require "test_helper"

class LikeableTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @other_user = users(:two)
    @post = posts(:one)
  end

  # =========================================
  # liked_by? 메서드 테스트
  # =========================================

  test "liked_by? returns false when user is nil" do
    assert_not @post.liked_by?(nil)
  end

  test "liked_by? returns false when user has not liked" do
    @post.likes.where(user: @user).destroy_all

    assert_not @post.liked_by?(@user)
  end

  test "liked_by? returns true when user has liked" do
    @post.likes.find_or_create_by!(user: @user)

    assert @post.liked_by?(@user)
  end

  # =========================================
  # toggle_like! 메서드 테스트
  # =========================================

  test "toggle_like! returns nil when user is nil" do
    result = @post.toggle_like!(nil)

    assert_nil result
  end

  test "toggle_like! adds like when not liked" do
    @post.likes.where(user: @user).destroy_all
    initial_count = @post.likes.count

    result = @post.toggle_like!(@user)

    assert_equal true, result
    assert_equal initial_count + 1, @post.likes.count
    assert @post.liked_by?(@user)
  end

  test "toggle_like! removes like when already liked" do
    @post.likes.find_or_create_by!(user: @user)
    initial_count = @post.likes.count

    result = @post.toggle_like!(@user)

    assert_equal false, result
    assert_equal initial_count - 1, @post.likes.count
    assert_not @post.liked_by?(@user)
  end

  test "toggle_like! is idempotent for rapid calls" do
    @post.likes.where(user: @user).destroy_all

    # 첫 번째 토글 - 좋아요 추가
    @post.toggle_like!(@user)
    assert @post.liked_by?(@user)

    # 두 번째 토글 - 좋아요 제거
    @post.toggle_like!(@user)
    assert_not @post.liked_by?(@user)
  end

  # =========================================
  # likes association 테스트
  # =========================================

  test "post has many likes" do
    assert_respond_to @post, :likes
  end

  test "destroying post destroys associated likes" do
    @post.likes.find_or_create_by!(user: @user)
    like_id = @post.likes.last.id

    @post.destroy

    assert_nil Like.find_by(id: like_id)
  end
end
