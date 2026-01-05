# frozen_string_literal: true

require "test_helper"

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:one)
    @other_user = users(:two)
    @notification = notifications(:comment_notification)
    @read_notification = notifications(:like_notification)
  end

  # =========================================
  # Authentication Tests
  # =========================================

  test "should redirect to login when not authenticated" do
    get notifications_path
    assert_redirected_to login_path
  end

  # =========================================
  # Index Action Tests
  # =========================================

  test "should get index when logged in" do
    log_in_as(@user)
    get notifications_path
    assert_response :success
    assert_select "title", /알림/
  end

  test "index should show user notifications" do
    log_in_as(@user)
    get notifications_path
    assert_response :success
    # User one의 알림이 표시되어야 함
    assert_includes assigns(:notifications), @notification
  end

  test "index should not show other users notifications" do
    log_in_as(@other_user)
    get notifications_path
    assert_response :success
    # User one의 알림은 보이지 않아야 함
    assert_not_includes assigns(:notifications), @notification
  end

  # =========================================
  # Show Action Tests (Read & Redirect)
  # =========================================

  test "should mark notification as read and redirect" do
    log_in_as(@user)
    assert_nil @notification.read_at

    get notification_path(@notification)

    @notification.reload
    assert_not_nil @notification.read_at
    assert_redirected_to @notification.target_path
  end

  test "should not access other users notification" do
    log_in_as(@other_user)
    get notification_path(@notification)
    # 다른 사용자의 알림에 접근 시 404 반환
    assert_response :not_found
  end

  # =========================================
  # Mark All Read Tests
  # =========================================

  test "should mark all notifications as read" do
    log_in_as(@user)
    assert @user.notifications.unread.exists?

    post mark_all_read_notifications_path

    @user.notifications.each do |notification|
      notification.reload
      assert notification.read?
    end
  end

  test "mark_all_read responds to turbo_stream" do
    log_in_as(@user)

    post mark_all_read_notifications_path, as: :turbo_stream
    assert_response :success
  end

  test "mark_all_read responds to html" do
    log_in_as(@user)

    post mark_all_read_notifications_path
    assert_redirected_to notifications_path
    follow_redirect!
    assert_select "div", /모든 알림을 읽음/
  end

  # =========================================
  # Destroy Action Tests
  # =========================================

  test "should destroy notification" do
    log_in_as(@user)

    assert_difference("Notification.count", -1) do
      delete notification_path(@notification)
    end

    assert_redirected_to notifications_path
  end

  test "destroy responds to turbo_stream" do
    log_in_as(@user)

    delete notification_path(@notification), as: :turbo_stream
    assert_response :success
  end

  test "should not destroy other users notification" do
    log_in_as(@other_user)

    assert_no_difference("Notification.count") do
      delete notification_path(@notification)
    end
    # 다른 사용자의 알림 삭제 시 404 반환
    assert_response :not_found
  end

  # =========================================
  # Dropdown Action Tests
  # =========================================

  test "should get dropdown partial" do
    log_in_as(@user)
    get dropdown_notifications_path, xhr: true
    assert_response :success
  end

  # test_helper.rb의 log_in_as 메서드를 사용합니다
end
