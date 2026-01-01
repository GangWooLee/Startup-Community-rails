# frozen_string_literal: true

require "test_helper"

class CommentTest < ActiveSupport::TestCase
  # =========================================
  # Fixtures & Setup
  # =========================================

  def setup
    @user = users(:one)
    @other_user = users(:two)
    @post = posts(:one)
    @comment = comments(:one)
    @reply = comments(:reply_to_one)
  end

  # =========================================
  # Validations
  # =========================================

  test "should be valid with valid attributes" do
    comment = Comment.new(
      user: @user,
      post: @post,
      content: "좋은 글이네요!"
    )
    assert comment.valid?
  end

  test "should require content" do
    comment = Comment.new(user: @user, post: @post)
    assert_not comment.valid?
    assert_validation_error comment, :content
  end

  test "should require user" do
    comment = Comment.new(post: @post, content: "댓글")
    assert_not comment.valid?
    assert_validation_error comment, :user
  end

  test "should require post" do
    comment = Comment.new(user: @user, content: "댓글")
    assert_not comment.valid?
    assert_validation_error comment, :post
  end

  test "should validate content length" do
    comment = Comment.new(user: @user, post: @post, content: "A" * 1001)
    assert_not comment.valid?
    assert_validation_error comment, :content
  end

  test "should allow content up to 1000 characters" do
    comment = Comment.new(user: @user, post: @post, content: "A" * 1000)
    assert comment.valid?
  end

  # =========================================
  # Associations
  # =========================================

  test "should belong to user" do
    assert_respond_to @comment, :user
    assert_kind_of User, @comment.user
  end

  test "should belong to post" do
    assert_respond_to @comment, :post
    assert_kind_of Post, @comment.post
  end

  test "should have optional parent" do
    assert_respond_to @comment, :parent
    assert_nil @comment.parent

    assert_not_nil @reply.parent
    assert_kind_of Comment, @reply.parent
  end

  test "should have many replies" do
    assert_respond_to @comment, :replies
    assert_kind_of ActiveRecord::Associations::CollectionProxy, @comment.replies
  end

  test "should have many notifications" do
    assert_respond_to @comment, :notifications
  end

  test "should destroy replies when destroyed" do
    parent_comment = Comment.create!(user: @user, post: @post, content: "부모 댓글")
    child_comment = Comment.create!(user: @other_user, post: @post, content: "자식 댓글", parent: parent_comment)

    assert_difference "Comment.count", -2 do
      parent_comment.destroy
    end
  end

  # =========================================
  # Reply Validations
  # =========================================

  test "should validate parent belongs to same post" do
    other_post = posts(:two)
    parent_comment = Comment.create!(user: @user, post: other_post, content: "다른 게시글 댓글")

    reply = Comment.new(
      user: @user,
      post: @post,
      content: "대댓글",
      parent: parent_comment
    )
    assert_not reply.valid?
    assert_validation_error reply, :parent
  end

  test "should validate parent depth limit" do
    # 최상위 댓글 생성
    root_comment = Comment.create!(user: @user, post: @post, content: "최상위 댓글")

    # 대댓글 생성 (depth = 1)
    reply = Comment.create!(user: @other_user, post: @post, content: "대댓글", parent: root_comment)

    # 대대댓글 시도 (depth = 2, MAX_DEPTH = 1이므로 실패해야 함)
    deep_reply = Comment.new(user: @user, post: @post, content: "대대댓글", parent: reply)
    assert_not deep_reply.valid?
    assert_validation_error deep_reply, :parent
  end

  test "should not allow self as parent" do
    @comment.parent_id = @comment.id
    assert_not @comment.valid?
    assert_validation_error @comment, :parent
  end

  # =========================================
  # Scopes
  # =========================================

  test "recent scope should order by created_at desc" do
    recent_comments = Comment.recent
    if recent_comments.size > 1
      recent_comments.each_cons(2) do |a, b|
        assert a.created_at >= b.created_at
      end
    end
  end

  test "oldest scope should order by created_at asc" do
    oldest_comments = Comment.oldest
    if oldest_comments.size > 1
      oldest_comments.each_cons(2) do |a, b|
        assert a.created_at <= b.created_at
      end
    end
  end

  test "root_comments scope should only return comments without parent" do
    root_comments = Comment.root_comments
    root_comments.each do |comment|
      assert_nil comment.parent_id
    end
  end

  # =========================================
  # Instance Methods
  # =========================================

  test "reply? should return true for replies" do
    assert @reply.reply?
    assert_not @comment.reply?
  end

  test "root? should return true for root comments" do
    assert @comment.root?
    assert_not @reply.root?
  end

  test "depth should return 0 for root comments" do
    assert_equal 0, @comment.depth
  end

  test "depth should return 1 for direct replies" do
    assert_equal 1, @reply.depth
  end

  # =========================================
  # Counter Cache
  # =========================================

  test "should increment post comments_count on create" do
    post = Post.create!(user: @user, title: "테스트", content: "내용", category: :free, status: :published)
    initial_count = post.comments_count

    Comment.create!(user: @other_user, post: post, content: "댓글입니다")

    assert_equal initial_count + 1, post.reload.comments_count
  end

  test "should increment parent replies_count on create" do
    parent = Comment.create!(user: @user, post: @post, content: "부모 댓글")
    initial_count = parent.replies_count || 0

    Comment.create!(user: @other_user, post: @post, content: "대댓글", parent: parent)

    assert_equal initial_count + 1, parent.reload.replies_count
  end

  # =========================================
  # Notifications
  # =========================================

  test "should create notification for post author on comment" do
    other_post = Post.create!(user: @other_user, title: "테스트", content: "내용", category: :free, status: :published)

    assert_difference "Notification.count", 1 do
      Comment.create!(user: @user, post: other_post, content: "댓글입니다")
    end

    notification = Notification.last
    assert_equal @other_user, notification.recipient
    assert_equal @user, notification.actor
    assert_equal "comment", notification.action
  end

  test "should create notification for parent comment author on reply" do
    parent = Comment.create!(user: @other_user, post: @post, content: "부모 댓글")

    assert_difference "Notification.count", 1 do
      Comment.create!(user: @user, post: @post, content: "대댓글", parent: parent)
    end

    notification = Notification.last
    assert_equal @other_user, notification.recipient
    assert_equal @user, notification.actor
    assert_equal "reply", notification.action
  end

  test "should not create notification for own comment" do
    my_post = Post.create!(user: @user, title: "내 글", content: "내용", category: :free, status: :published)

    assert_no_difference "Notification.count" do
      Comment.create!(user: @user, post: my_post, content: "내 글에 내가 댓글")
    end
  end

  test "should not create notification for own reply" do
    my_comment = Comment.create!(user: @user, post: @post, content: "내 댓글")

    assert_no_difference "Notification.count" do
      Comment.create!(user: @user, post: @post, content: "내 댓글에 내가 대댓글", parent: my_comment)
    end
  end

  # =========================================
  # Likeable Concern
  # =========================================

  test "should include Likeable concern" do
    assert Comment.included_modules.include?(Likeable)
  end

  test "should respond to likes" do
    assert_respond_to @comment, :likes
  end

  test "should respond to liked_by?" do
    assert_respond_to @comment, :liked_by?
  end

  # =========================================
  # Constants
  # =========================================

  test "should have MAX_DEPTH constant" do
    assert_equal 1, Comment::MAX_DEPTH
  end
end
