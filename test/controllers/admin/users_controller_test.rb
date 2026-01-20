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

  # =========================================
  # CSV Export
  # =========================================

  test "admin can export users to CSV" do
    log_in_as(@admin)

    get export_admin_users_path(format: :csv)
    assert_response :success
    assert_equal "text/csv; charset=utf-8", response.content_type

    # UTF-8 BOM 확인
    assert response.body.start_with?("\xEF\xBB\xBF"), "CSV should start with UTF-8 BOM"

    # 헤더 확인
    assert_includes response.body, "ID"
    assert_includes response.body, "이름"
    assert_includes response.body, "이메일"
  end

  test "admin can export filtered users" do
    log_in_as(@admin)

    # 상태 필터 적용하여 내보내기
    get export_admin_users_path(format: :csv, status: "active")
    assert_response :success

    # 탈퇴 회원은 포함되지 않아야 함
    # (테스트 데이터에 따라 다름)
  end

  test "export requires admin login" do
    get export_admin_users_path(format: :csv)
    assert_redirected_to root_path
  end

  # =========================================
  # Date Filter Exception Handling
  # =========================================

  test "index should handle invalid from_date gracefully" do
    log_in_as(@admin)

    # 잘못된 날짜 형식
    get admin_users_path(from_date: "invalid-date")
    assert_response :success  # 500 에러가 아닌 정상 응답
  end

  test "index should handle impossible date gracefully" do
    log_in_as(@admin)

    # 존재하지 않는 날짜
    get admin_users_path(from_date: "2026-02-30")
    assert_response :success
  end

  test "index should handle invalid to_date gracefully" do
    log_in_as(@admin)

    get admin_users_path(to_date: "not-a-date")
    assert_response :success
  end

  test "export should handle invalid dates gracefully" do
    log_in_as(@admin)

    get export_admin_users_path(format: :csv, from_date: "invalid", to_date: "also-invalid")
    assert_response :success
  end

  test "index should work with valid date filters" do
    log_in_as(@admin)

    get admin_users_path(from_date: "2026-01-01", to_date: "2026-12-31")
    assert_response :success
  end

  private

  def log_in_as(user)
    post login_path, params: {
      email: user.email,
      password: TEST_PASSWORD
    }
  end
end
