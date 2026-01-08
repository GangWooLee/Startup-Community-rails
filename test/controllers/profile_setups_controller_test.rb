# frozen_string_literal: true

require "test_helper"

class ProfileSetupsControllerTest < ActionDispatch::IntegrationTest
  fixtures :users

  TEST_PASSWORD = "test1234"

  setup do
    @user = users(:one)
    @user.update_columns(profile_completed: false, nickname: nil, is_anonymous: false)
  end

  # =========================================
  # Authentication Tests
  # =========================================

  test "GET /welcome requires login" do
    get profile_setup_path
    assert_redirected_to login_path
  end

  test "GET /welcome redirects if profile already completed" do
    @user.update_columns(profile_completed: true, nickname: "완료된닉네임")
    log_in_as(@user)

    get profile_setup_path
    assert_redirected_to community_path
  end

  test "GET /welcome shows form for incomplete profile user" do
    log_in_as(@user)

    get profile_setup_path
    assert_response :success
    assert_select "form"
  end

  # =========================================
  # Profile Update Tests
  # =========================================

  test "PATCH /welcome updates profile successfully" do
    log_in_as(@user)

    patch profile_setup_path, params: {
      user: { nickname: "멋진개발자", avatar_type: 2, is_anonymous: true }
    }

    assert_redirected_to community_path
    @user.reload
    assert @user.profile_completed?
    assert_equal "멋진개발자", @user.nickname
    assert_equal 2, @user.avatar_type
    assert @user.is_anonymous?
  end

  test "PATCH /welcome fails with short nickname (less than 2 chars)" do
    log_in_as(@user)

    patch profile_setup_path, params: {
      user: { nickname: "A", avatar_type: 0, is_anonymous: true }
    }

    assert_response :unprocessable_entity
    @user.reload
    assert_not @user.profile_completed?
  end

  test "PATCH /welcome fails with long nickname (more than 20 chars)" do
    log_in_as(@user)

    patch profile_setup_path, params: {
      user: { nickname: "A" * 21, avatar_type: 0, is_anonymous: true }
    }

    assert_response :unprocessable_entity
    @user.reload
    assert_not @user.profile_completed?
  end

  test "PATCH /welcome fails with duplicate nickname" do
    other_user = users(:two)
    other_user.update!(profile_completed: true, nickname: "중복닉네임")

    log_in_as(@user)

    patch profile_setup_path, params: {
      user: { nickname: "중복닉네임", avatar_type: 0, is_anonymous: true }
    }

    assert_response :unprocessable_entity
    @user.reload
    assert_not @user.profile_completed?
  end

  test "PATCH /welcome sets is_anonymous to false when not checked" do
    log_in_as(@user)

    patch profile_setup_path, params: {
      user: { nickname: "공개닉네임", avatar_type: 1, is_anonymous: false }
    }

    assert_redirected_to community_path
    @user.reload
    assert @user.profile_completed?
    assert_not @user.is_anonymous?
  end

  # =========================================
  # Nickname Regeneration Tests (AJAX)
  # =========================================

  test "POST /welcome/regenerate_nickname returns new nickname" do
    log_in_as(@user)

    post regenerate_nickname_profile_setup_path, as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert json["nickname"].present?
    assert_kind_of String, json["nickname"]
    assert json["nickname"].length >= 2
  end

  test "POST /welcome/regenerate_nickname requires login" do
    post regenerate_nickname_profile_setup_path, as: :json
    # 로그인 필요하므로 리다이렉트
    assert_response :redirect
  end

  private

  def log_in_as(user)
    post login_path, params: {
      email: user.email,
      password: TEST_PASSWORD
    }
  end
end
