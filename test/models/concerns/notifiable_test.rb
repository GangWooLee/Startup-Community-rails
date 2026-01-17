# frozen_string_literal: true

require "test_helper"

class NotifiableTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @other_user = users(:two)
  end

  # =========================================
  # unread_notifications_count 메서드 테스트
  # =========================================

  test "unread_notifications_count returns zero when no notifications" do
    @user.notifications.destroy_all

    assert_equal 0, @user.unread_notifications_count
  end

  test "unread_notifications_count returns count of unread notifications" do
    @user.notifications.destroy_all
    post = posts(:one)

    # 읽지 않은 알림 생성 (유효한 action 값 사용)
    @user.notifications.create!(
      notifiable: post,
      action: "comment",
      actor: @other_user,
      read_at: nil
    )
    @user.notifications.create!(
      notifiable: post,
      action: "like",
      actor: @other_user,
      read_at: nil
    )
    # 읽은 알림
    @user.notifications.create!(
      notifiable: post,
      action: "reply",
      actor: @other_user,
      read_at: Time.current
    )

    assert_equal 2, @user.unread_notifications_count
  end

  # =========================================
  # has_unread_notifications? 메서드 테스트
  # =========================================

  test "has_unread_notifications? returns false when no notifications" do
    @user.notifications.destroy_all

    assert_not @user.has_unread_notifications?
  end

  test "has_unread_notifications? returns false when all read" do
    @user.notifications.destroy_all
    post = posts(:one)
    @user.notifications.create!(
      notifiable: post,
      action: "comment",
      actor: @other_user,
      read_at: Time.current
    )

    assert_not @user.has_unread_notifications?
  end

  test "has_unread_notifications? returns true when unread exists" do
    @user.notifications.destroy_all
    post = posts(:one)
    @user.notifications.create!(
      notifiable: post,
      action: "comment",
      actor: @other_user,
      read_at: nil
    )

    assert @user.has_unread_notifications?
  end
end
