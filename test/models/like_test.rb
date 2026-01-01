# frozen_string_literal: true

require "test_helper"

class LikeTest < ActiveSupport::TestCase
  # =========================================
  # Fixtures & Setup
  # =========================================

  def setup
    @user = users(:one)
    @other_user = users(:two)
    @third_user = users(:three)
    @post = posts(:one)
    @comment = comments(:one)
    @post_like = likes(:post_like_one)
  end

  # =========================================
  # Validations
  # =========================================

  test "should be valid with valid attributes for post" do
    # users(:three)는 이미 posts(:one)에 좋아요를 눌렀으므로 다른 게시글 사용
    other_post = posts(:two)
    like = Like.new(user: @user, likeable: other_post)
    assert like.valid?
  end

  test "should be valid with valid attributes for comment" do
    # 다른 댓글에 좋아요
    other_comment = comments(:two)
    like = Like.new(user: @other_user, likeable: other_comment)
    assert like.valid?
  end

  test "should require user" do
    like = Like.new(likeable: @post)
    assert_not like.valid?
    assert_validation_error like, :user
  end

  test "should require likeable" do
    like = Like.new(user: @user)
    assert_not like.valid?
    assert_validation_error like, :likeable
  end

  test "should validate likeable_type inclusion" do
    like = Like.new(user: @user)
    like.likeable_type = "User"  # User는 VALID_LIKEABLE_TYPES에 없음
    like.likeable_id = @user.id
    assert_not like.valid?
    assert_validation_error like, :likeable_type
  end

  test "should allow Post as likeable_type" do
    other_post = posts(:two)
    like = Like.new(user: @user, likeable: other_post)
    assert like.valid?
  end

  test "should allow Comment as likeable_type" do
    other_comment = comments(:two)
    like = Like.new(user: @other_user, likeable: other_comment)
    assert like.valid?
  end

  test "should prevent duplicate likes" do
    # @other_user 가 이미 @post에 좋아요 (post_like_one fixture)
    duplicate_like = Like.new(user: @other_user, likeable: @post)
    assert_not duplicate_like.valid?
    assert_validation_error duplicate_like, :user_id
  end

  # =========================================
  # Associations
  # =========================================

  test "should belong to user" do
    assert_respond_to @post_like, :user
    assert_kind_of User, @post_like.user
  end

  test "should belong to likeable polymorphic" do
    assert_respond_to @post_like, :likeable
    assert_kind_of Post, @post_like.likeable
  end

  test "should have many notifications" do
    assert_respond_to @post_like, :notifications
  end

  # =========================================
  # Counter Cache
  # =========================================

  test "should increment post likes_count on create" do
    new_post = Post.create!(
      user: @user,
      title: "테스트",
      content: "내용",
      category: :free,
      status: :published
    )
    initial_count = new_post.likes_count

    Like.create!(user: @other_user, likeable: new_post)

    assert_equal initial_count + 1, new_post.reload.likes_count
  end

  test "should decrement post likes_count on destroy" do
    new_post = Post.create!(
      user: @user,
      title: "테스트",
      content: "내용",
      category: :free,
      status: :published
    )
    like = Like.create!(user: @other_user, likeable: new_post)

    assert_difference -> { new_post.reload.likes_count }, -1 do
      like.destroy
    end
  end

  test "should increment comment likes_count on create" do
    new_comment = Comment.create!(user: @user, post: @post, content: "댓글")
    initial_count = new_comment.likes_count

    Like.create!(user: @other_user, likeable: new_comment)

    assert_equal initial_count + 1, new_comment.reload.likes_count
  end

  # =========================================
  # Notifications
  # =========================================

  test "should create notification for post owner on like" do
    new_post = Post.create!(
      user: @other_user,
      title: "테스트",
      content: "내용",
      category: :free,
      status: :published
    )

    assert_difference "Notification.count", 1 do
      Like.create!(user: @user, likeable: new_post)
    end

    notification = Notification.last
    assert_equal @other_user, notification.recipient
    assert_equal @user, notification.actor
    assert_equal "like", notification.action
  end

  test "should create notification for comment owner on like" do
    new_comment = Comment.create!(user: @other_user, post: @post, content: "댓글")

    assert_difference "Notification.count", 1 do
      Like.create!(user: @user, likeable: new_comment)
    end

    notification = Notification.last
    assert_equal @other_user, notification.recipient
    assert_equal @user, notification.actor
    assert_equal "like", notification.action
  end

  test "should not create notification for own like" do
    new_post = Post.create!(
      user: @user,
      title: "내 글",
      content: "내용",
      category: :free,
      status: :published
    )

    assert_no_difference "Notification.count" do
      Like.create!(user: @user, likeable: new_post)
    end
  end

  # =========================================
  # Constants
  # =========================================

  test "should have VALID_LIKEABLE_TYPES constant" do
    assert_includes Like::VALID_LIKEABLE_TYPES, "Post"
    assert_includes Like::VALID_LIKEABLE_TYPES, "Comment"
  end
end
