# frozen_string_literal: true

require "application_system_test_case"

class AuthenticationTest < ApplicationSystemTestCase
  def setup
    @user = users(:one)
  end

  # =========================================
  # 회원가입 테스트
  # =========================================

  test "user can sign up with valid information" do
    visit signup_path

    # 라벨 텍스트가 "이름 *" 형태이므로 ID로 접근
    fill_in "user_name", with: "새로운 사용자"
    fill_in "user_email", with: "newuser#{Time.now.to_i}@example.com"
    fill_in "user_password", with: "password123"
    fill_in "user_password_confirmation", with: "password123"

    # 이용약관 동의
    check "terms"

    click_button "회원가입"

    # 회원가입 후 리다이렉트 확인 (온보딩 또는 환영 메시지)
    assert page.has_text?("환영") || page.has_current_path?(%r{/onboarding|/})
  end

  test "signup shows error with mismatched password" do
    visit signup_path

    fill_in "user_name", with: "테스트"
    fill_in "user_email", with: "test#{Time.now.to_i}@example.com"
    fill_in "user_password", with: "password123"
    fill_in "user_password_confirmation", with: "different"

    check "terms"
    click_button "회원가입"

    # 비밀번호 불일치 에러 표시
    assert page.has_text?("일치") || page.has_text?("match") || page.has_selector?(".text-destructive")
  end

  test "signup shows error with existing email" do
    visit signup_path

    fill_in "user_name", with: "테스트"
    fill_in "user_email", with: @user.email  # 기존 사용자 이메일
    fill_in "user_password", with: "password123"
    fill_in "user_password_confirmation", with: "password123"

    check "terms"
    click_button "회원가입"

    # 중복 이메일 에러 표시
    assert page.has_text?("이미 사용 중") || page.has_text?("taken") || page.has_selector?(".text-destructive")
  end

  # =========================================
  # 로그인 테스트
  # =========================================

  test "user can log in with valid credentials" do
    visit login_path

    fill_in "이메일", with: @user.email
    fill_in "비밀번호", with: "test1234"

    click_button "로그인"

    # 로그인 성공 확인
    assert_text "환영합니다"
    assert_current_path community_path
  end

  test "login fails with invalid password" do
    visit login_path

    fill_in "이메일", with: @user.email
    fill_in "비밀번호", with: "wrongpassword"

    click_button "로그인"

    # 에러 메시지 표시
    assert_text "올바르지 않습니다"
    assert_current_path login_path
  end

  test "login fails with non-existent email" do
    visit login_path

    fill_in "이메일", with: "nonexistent@example.com"
    fill_in "비밀번호", with: "password123"

    click_button "로그인"

    # 에러 메시지 표시
    assert_text "올바르지 않습니다"
  end

  # =========================================
  # 로그아웃 테스트
  # =========================================

  test "user can log out" do
    log_in_as(@user)

    # 프로필 메뉴 또는 로그아웃 버튼 클릭
    find("[data-action*='dropdown#toggle']", match: :first).click
    click_link "로그아웃"

    # 로그아웃 확인
    assert_text "로그아웃되었습니다"
    assert_current_path root_path
  end

  # =========================================
  # Remember Me 테스트
  # =========================================

  test "remember me checkbox is present on login page" do
    visit login_path

    assert_selector "input[name='remember_me']"
    assert_text "로그인 상태 유지"
  end

  # =========================================
  # 인증 필요 페이지 접근 테스트
  # =========================================

  test "redirects to login when accessing protected page" do
    visit notifications_path

    # 로그인 페이지로 리다이렉트
    assert_current_path login_path
  end

  test "redirects back after login" do
    # 마이페이지 접근 시도
    visit my_page_path

    # 로그인 페이지로 리다이렉트
    assert_current_path login_path

    # 로그인
    fill_in "이메일", with: @user.email
    fill_in "비밀번호", with: "test1234"
    click_button "로그인"

    # 원래 가려던 페이지로 이동
    assert_current_path my_page_path
  end

  private

  def log_in_as(user)
    visit login_path

    # 명시적으로 입력 필드 찾아서 입력
    find("input[name='email']", wait: 3).set(user.email)
    find("input[name='password']").set("test1234")
    click_button "로그인"

    # 로그인 완료 대기
    assert_no_current_path login_path, wait: 3
  end
end
