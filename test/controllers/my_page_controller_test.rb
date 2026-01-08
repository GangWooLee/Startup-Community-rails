# frozen_string_literal: true

require "test_helper"

class MyPageControllerTest < ActionDispatch::IntegrationTest
  fixtures :users

  TEST_PASSWORD = "test1234"

  setup do
    @user = users(:one)
    @user.update_columns(profile_completed: true, nickname: "테스트닉네임", is_anonymous: false, avatar_type: 0)
  end

  # =========================================
  # Authentication Tests
  # =========================================

  test "GET /my requires login" do
    get my_page_path
    assert_redirected_to login_path
  end

  test "GET /my shows page for logged in user" do
    log_in_as(@user)
    get my_page_path
    assert_response :success
  end

  # =========================================
  # Anonymous Settings Update Tests
  # =========================================

  test "PATCH /my updates anonymous settings successfully" do
    log_in_as(@user)

    patch my_page_path, params: {
      user: { is_anonymous: true, nickname: "새닉네임", avatar_type: 3 }
    }

    assert_redirected_to my_page_path
    @user.reload
    assert @user.is_anonymous?
    assert_equal "새닉네임", @user.nickname
    assert_equal 3, @user.avatar_type
  end

  test "PATCH /my can switch from anonymous to real name" do
    @user.update!(is_anonymous: true, nickname: "익명닉네임")
    log_in_as(@user)

    patch my_page_path, params: {
      user: { is_anonymous: false }
    }

    assert_redirected_to my_page_path
    @user.reload
    assert_not @user.is_anonymous?
  end

  test "PATCH /my can change nickname while remaining anonymous" do
    @user.update!(is_anonymous: true, nickname: "원래닉네임")
    log_in_as(@user)

    patch my_page_path, params: {
      user: { nickname: "변경된닉네임" }
    }

    assert_redirected_to my_page_path
    @user.reload
    assert_equal "변경된닉네임", @user.nickname
  end

  test "PATCH /my fails with duplicate nickname" do
    other_user = users(:two)
    other_user.update!(profile_completed: true, nickname: "이미있는닉네임")

    log_in_as(@user)

    patch my_page_path, params: {
      user: { nickname: "이미있는닉네임" }
    }

    assert_response :unprocessable_entity
  end

  test "PATCH /my updates avatar_type" do
    log_in_as(@user)

    patch my_page_path, params: {
      user: { avatar_type: 2 }
    }

    assert_redirected_to my_page_path
    @user.reload
    assert_equal 2, @user.avatar_type
  end

  private

  def log_in_as(user)
    post login_path, params: {
      email: user.email,
      password: TEST_PASSWORD
    }
  end
end
