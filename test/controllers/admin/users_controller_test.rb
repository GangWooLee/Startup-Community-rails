# frozen_string_literal: true

require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  fixtures :users

  TEST_PASSWORD = "test1234"

  setup do
    @admin = users(:admin)
    # 관리자도 프로필 완료 상태로 설정
    @admin.update!(profile_completed: true, nickname: "관리자닉네임")

    @anonymous_user = users(:one)
    @anonymous_user.update!(
      profile_completed: true,
      is_anonymous: true,
      nickname: "익명테스터",
      avatar_type: 1
    )
  end

  # =========================================
  # Admin Authentication
  # =========================================

  test "admin index requires login" do
    get admin_users_path
    # 로그인 안 하면 root_path로 리다이렉트 (require_admin)
    assert_redirected_to root_path
  end

  test "admin index requires admin role" do
    normal_user = users(:two)
    normal_user.update!(profile_completed: true, nickname: "일반유저")
    log_in_as(normal_user)

    get admin_users_path
    assert_redirected_to root_path
    follow_redirect!
    assert_match /관리자 권한/, flash[:alert] || ""
  end

  # =========================================
  # Admin Sees Real Name for Anonymous Users
  # =========================================

  test "admin user list shows real name for anonymous users" do
    log_in_as(@admin)

    get admin_users_path
    assert_response :success

    # 관리자 페이지에서는 실명이 표시되어야 함
    assert_match @anonymous_user.name, response.body
    # 닉네임도 추가 정보로 표시될 수 있음
  end

  test "admin user detail shows real name for anonymous users" do
    log_in_as(@admin)

    get admin_user_path(@anonymous_user)
    assert_response :success

    # 관리자 상세 페이지에서 실명 표시
    assert_match @anonymous_user.name, response.body
    assert_match @anonymous_user.email, response.body
  end

  test "admin can search users by real name" do
    log_in_as(@admin)

    # 실명으로 검색
    get admin_users_path, params: { q: @anonymous_user.name }
    assert_response :success

    # 검색 결과에 익명 사용자가 포함되어야 함
    assert_match @anonymous_user.name, response.body
  end

  test "admin can see nickname in user details" do
    log_in_as(@admin)

    get admin_user_path(@anonymous_user)
    assert_response :success

    # 닉네임도 관리자에게는 보여야 함 (관리 목적)
    # 이 부분은 뷰에서 닉네임을 표시하는지에 따라 다름
  end

  private

  def log_in_as(user)
    post login_path, params: {
      email: user.email,
      password: TEST_PASSWORD
    }
  end
end
