require "test_helper"

class NotificationTest < ActiveSupport::TestCase
  setup do
    @user1 = users(:one)
    @user2 = users(:two)
    @post = posts(:one)
  end

  test "should create notification with valid attributes" do
    notification = Notification.new(
      recipient: @user1,
      actor: @user2,
      action: "comment",
      notifiable: @post
    )
    assert notification.valid?
    assert notification.save
  end

  test "should require recipient" do
    notification = Notification.new(
      actor: @user2,
      action: "comment",
      notifiable: @post
    )
    assert_not notification.valid?
  end

  test "should require actor" do
    notification = Notification.new(
      recipient: @user1,
      action: "comment",
      notifiable: @post
    )
    assert_not notification.valid?
  end

  test "should require action" do
    notification = Notification.new(
      recipient: @user1,
      actor: @user2,
      notifiable: @post
    )
    assert_not notification.valid?
  end

  test "should validate action is in allowed list" do
    notification = Notification.new(
      recipient: @user1,
      actor: @user2,
      action: "invalid_action",
      notifiable: @post
    )
    assert_not notification.valid?
    assert_includes notification.errors[:action], "is not included in the list"
  end

  test "unread scope returns only unread notifications" do
    unread = Notification.create!(
      recipient: @user1,
      actor: @user2,
      action: "comment",
      notifiable: @post
    )
    read = Notification.create!(
      recipient: @user1,
      actor: @user2,
      action: "like",
      notifiable: @post,
      read_at: Time.current
    )

    unread_notifications = Notification.unread
    assert_includes unread_notifications, unread
    assert_not_includes unread_notifications, read
  end

  test "mark_as_read! updates read_at" do
    notification = Notification.create!(
      recipient: @user1,
      actor: @user2,
      action: "comment",
      notifiable: @post
    )

    assert_nil notification.read_at
    notification.mark_as_read!
    assert_not_nil notification.read_at
    assert notification.read?
  end

  test "message returns correct text for each action" do
    notification = Notification.new(
      recipient: @user1,
      actor: @user2,
      action: "comment",
      notifiable: @post
    )
    assert_match @user2.name, notification.message
    assert_match "댓글", notification.message

    notification.action = "like"
    assert_match "좋아합니다", notification.message

    notification.action = "reply"
    assert_match "답글", notification.message
  end

  test "target_path returns correct path for Post" do
    notification = Notification.create!(
      recipient: @user1,
      actor: @user2,
      action: "comment",
      notifiable: @post
    )
    assert_equal "/posts/#{@post.id}", notification.target_path
  end
end
