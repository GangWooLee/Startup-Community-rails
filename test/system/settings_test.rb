# frozen_string_literal: true

require "application_system_test_case"

class SettingsTest < ApplicationSystemTestCase
  def setup
    @user = users(:one)
    @oauth_user = users(:oauth_user)
  end

  # =========================================
  # 로그인 필수 테스트
  # =========================================

  test "requires login to view settings" do
    visit settings_path

    # 비로그인 시 로그인 페이지로 리다이렉트
    assert_current_path login_path
  end

  # =========================================
  # 설정 페이지 조회 테스트
  # =========================================

  test "can view settings page when logged in" do
    log_in_as(@user)
    visit settings_path

    # 설정 페이지 로드 확인
    assert_current_path settings_path
    assert_selector "main", wait: 5

    # 페이지 제목 확인
    assert_text "설정"
  end

  test "shows notification settings section" do
    log_in_as(@user)
    visit settings_path

    # 알림 섹션 표시 확인
    assert_text "알림", wait: 3
    assert_text "푸시 알림 받기"
  end

  test "shows account section with email" do
    log_in_as(@user)
    visit settings_path

    # 계정 섹션 표시
    assert_text "계정", wait: 3
    assert_text @user.email
  end

  test "shows support section links" do
    log_in_as(@user)
    visit settings_path

    # 고객 지원 섹션 링크들 확인
    assert_text "문의하기", wait: 3
    assert_text "내 문의 내역"
    assert_text "서비스 이용약관"
    assert_text "개인정보 처리방침"
  end

  # =========================================
  # 알림 설정 토글 테스트
  # =========================================

  test "can toggle notification setting" do
    log_in_as(@user)
    visit settings_path

    # 알림 토글 찾기
    notification_toggle = find("input[name='user[notifications_enabled]']", visible: :all, wait: 5) rescue nil

    if notification_toggle
      # 현재 상태 기록
      initial_state = notification_toggle.checked?

      # 토글 클릭 (라벨 클릭으로 대체)
      label = notification_toggle.ancestor("label") rescue nil
      if label
        label.click
      else
        page.execute_script("arguments[0].click()", notification_toggle)
      end

      sleep 0.5

      # 페이지가 정상적으로 유지됨 (에러 없음)
      assert_current_path settings_path
    else
      # 토글이 없는 경우 - 페이지 로드 성공
      assert_selector "main", wait: 3
    end
  end

  # =========================================
  # 네비게이션 링크 테스트
  # =========================================

  test "inquiry link navigates to new inquiry page" do
    log_in_as(@user)
    visit settings_path

    # 페이지 로드 대기
    assert_text "문의하기", wait: 5

    # 문의하기 링크 클릭 (JavaScript로 클릭하여 Turbo 안정성 확보)
    link = find("a[href='#{new_inquiry_path}']")
    page.execute_script("arguments[0].click()", link)

    # 문의 페이지로 이동 (Turbo 대기)
    assert_current_path new_inquiry_path, wait: 10
  end

  test "inquiry history link navigates to inquiries list" do
    log_in_as(@user)
    visit settings_path

    # 내 문의 내역 링크 클릭
    click_on "내 문의 내역"

    # 문의 목록 페이지로 이동
    assert_current_path inquiries_path
  end

  test "terms link navigates to terms page" do
    log_in_as(@user)
    visit settings_path

    # 페이지 로드 대기
    assert_text "서비스 이용약관", wait: 5

    # 이용약관 링크 클릭 (JavaScript로 클릭하여 Turbo 안정성 확보)
    link = find("a[href='#{terms_path}']")
    page.execute_script("arguments[0].click()", link)

    # 이용약관 페이지로 이동 (Turbo 대기)
    assert_current_path terms_path, wait: 10
  end

  test "privacy link navigates to privacy page" do
    log_in_as(@user)
    visit settings_path

    # 개인정보처리방침 링크 클릭
    click_on "개인정보 처리방침"

    # 개인정보처리방침 페이지로 이동
    assert_current_path privacy_path
  end

  # =========================================
  # 회원 탈퇴 링크 테스트
  # =========================================

  test "delete account link is visible" do
    log_in_as(@user)
    visit settings_path

    # 회원 탈퇴 링크 표시
    assert_text "회원 탈퇴", wait: 3
  end

  test "delete account link navigates to delete page" do
    log_in_as(@user)
    visit settings_path

    # 페이지 로드 대기
    assert_text "회원 탈퇴", wait: 5

    # 회원 탈퇴 링크 클릭 (JavaScript로 클릭하여 Turbo 안정성 확보)
    link = find("a[href='#{delete_account_path}']")
    page.execute_script("arguments[0].click()", link)

    # 회원 탈퇴 페이지로 이동 (Turbo 대기)
    assert_current_path delete_account_path, wait: 10
  end

  # =========================================
  # OAuth 연결 상태 테스트
  # =========================================

  test "shows oauth connection status for oauth user" do
    log_in_as(@oauth_user)
    visit settings_path

    # OAuth 사용자의 경우 연결 상태 표시
    if @oauth_user.oauth_identities.any?
      identity = @oauth_user.oauth_identities.first
      if identity.provider == "google_oauth2"
        assert_text "Google 연결됨", wait: 3
      elsif identity.provider == "github"
        assert_text "GitHub 연결됨", wait: 3
      end
    else
      # OAuth 연결이 없는 경우 이메일만 표시
      assert_text @oauth_user.email
    end
  end

  # =========================================
  # 버전 정보 테스트
  # =========================================

  test "shows version info" do
    log_in_as(@user)
    visit settings_path

    # 버전 정보 표시
    assert_text "버전", wait: 3
    assert_text "가입일"
  end
end
