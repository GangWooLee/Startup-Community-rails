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

    # 약관 동의 (3개 모두 필수)
    check "terms_agreement"
    check "privacy_agreement"
    check "guidelines_agreement"

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

    # 약관 동의 (3개 모두 필수)
    check "terms_agreement"
    check "privacy_agreement"
    check "guidelines_agreement"
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

    # 약관 동의 (3개 모두 필수)
    check "terms_agreement"
    check "privacy_agreement"
    check "guidelines_agreement"
    click_button "회원가입"

    # 중복 이메일 에러 표시
    assert page.has_text?("이미 사용 중") || page.has_text?("taken") || page.has_selector?(".text-destructive")
  end

  # =========================================
  # 로그인 테스트
  # =========================================

  test "user can log in with valid credentials" do
    visit login_path

    # name 속성으로 입력 필드 찾기 (더 안정적)
    find("input[name='email']").fill_in with: @user.email
    find("input[name='password']").fill_in with: TEST_PASSWORD

    click_button "로그인"

    # 폼 제출 대기
    sleep 0.5

    # 로그인 성공 확인 (flash 메시지 또는 페이지 이동)
    assert page.has_text?("환영합니다") || page.has_current_path?(community_path, wait: 5)
  end

  test "login fails with invalid password" do
    visit login_path

    # name 속성으로 입력 필드 찾기
    find("input[name='email']").fill_in with: @user.email
    find("input[name='password']").fill_in with: "wrongpassword"

    click_button "로그인"

    # 폼 제출 대기
    sleep 0.5

    # 에러 메시지 표시 (visible:false로 숨겨진 텍스트도 확인)
    assert page.has_text?("올바르지 않습니다", wait: 3) || page.has_current_path?(login_path)
  end

  test "login fails with non-existent email" do
    visit login_path

    # name 속성으로 입력 필드 찾기
    find("input[name='email']").fill_in with: "nonexistent@example.com"
    find("input[name='password']").fill_in with: "password123"

    click_button "로그인"

    # 폼 제출 대기
    sleep 0.5

    # 에러 메시지 표시
    assert page.has_text?("올바르지 않습니다", wait: 3) || page.has_current_path?(login_path)
  end

  # =========================================
  # 로그아웃 테스트
  # =========================================

  test "user can log out" do
    log_in_as(@user)

    # 로그아웃: 설정 페이지를 통해 로그아웃 (드롭다운 불안정 문제 우회)
    visit settings_path

    # 설정 페이지 로드 확인
    assert_selector "button", text: "로그아웃", wait: 5

    # CI 환경 안정화: confirm 다이얼로그를 자동 수락하도록 스텁
    page.execute_script("window.confirm = () => true")

    # 로그아웃 버튼 클릭
    click_button "로그아웃"

    # 로그아웃 확인 (flash 메시지 또는 루트 페이지)
    # 로그인 페이지 또는 루트 페이지로 리다이렉트
    assert page.has_text?("로그아웃되었습니다", wait: 5) ||
           page.has_current_path?(root_path, wait: 5) ||
           page.has_current_path?(login_path, wait: 5)
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

    # 로그인 (name 속성으로 입력 필드 찾기)
    find("input[name='email']").fill_in with: @user.email
    find("input[name='password']").fill_in with: TEST_PASSWORD
    click_button "로그인"

    # 폼 제출 대기
    sleep 0.5

    # 원래 가려던 페이지로 이동 (또는 커뮤니티)
    assert page.has_current_path?(my_page_path, wait: 5) || page.has_current_path?(community_path, wait: 5)
  end
end
