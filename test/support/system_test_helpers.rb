# frozen_string_literal: true

# System Test 공통 헬퍼 모듈
# 모든 System Test에서 공유되는 헬퍼 메서드 정의
#
# 사용법:
#   class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
#     include SystemTestHelpers
#   end
#
module SystemTestHelpers
  # 테스트용 비밀번호 상수
  TEST_PASSWORD = "test1234"

  # 사용자 로그인 헬퍼
  # @param user [User] 로그인할 사용자 fixture
  #
  # 주의: fill_in은 id, name, label로 입력 필드를 찾습니다.
  # 현재 로그인 폼은 name="email", name="password" 사용
  def log_in_as(user)
    visit login_path

    # 로그인 폼의 email 입력 필드가 보일 때까지 대기
    assert_selector "input[name='email']", visible: true, wait: 5

    # 폼 필드 입력 (name 속성으로 찾기)
    find("input[name='email']", visible: true).fill_in with: user.email
    find("input[name='password']").fill_in with: TEST_PASSWORD

    # 로그인 버튼 찾기 및 클릭
    login_button = find("button", text: "로그인", match: :first)
    login_button.click

    # 폼 제출 완료 대기 (페이지 전환 또는 에러 메시지)
    sleep 0.5

    # 로그인 성공 확인 (최대 5초 대기)
    # 로그인 실패 시 login_path에 머무름
    unless page.has_no_current_path?(login_path, wait: 5)
      # 디버깅: 로그인 실패 시 현재 페이지 상태 출력
      if page.has_text?("올바르지 않습니다")
        raise "로그인 실패: 이메일 또는 비밀번호가 올바르지 않습니다"
      else
        # JavaScript로 폼 직접 제출 시도
        page.execute_script("document.querySelector('form').submit()")
        sleep 1
        assert_no_current_path login_path, wait: 5
      end
    end

    # 추가 검증: 로그인 실패 메시지가 없는지 확인
    assert_no_text "이메일 또는 비밀번호가 올바르지 않습니다."
  end

  # 회원가입 헬퍼
  # @param email [String] 이메일
  # @param password [String] 비밀번호
  # @param name [String] 사용자 이름
  # @param agree_terms [Boolean] 약관 동의 여부 (기본: true)
  #
  # 주의: 회원가입 폼에는 3개의 약관 체크박스가 있음
  # - terms_agreement (이용약관)
  # - privacy_agreement (개인정보 처리방침)
  # - guidelines_agreement (커뮤니티 가이드라인)
  def sign_up_as(email:, password:, name:, agree_terms: true)
    visit signup_path

    # 회원가입 폼의 name 입력 필드가 보일 때까지 대기
    assert_selector "input[name='user[name]']", visible: true, wait: 5

    fill_in "user[name]", with: name
    fill_in "user[email]", with: email
    fill_in "user[password]", with: password
    fill_in "user[password_confirmation]", with: password

    # 약관 동의 체크 (3개 모두 필수)
    if agree_terms
      check "terms_agreement"
      check "privacy_agreement"
      check "guidelines_agreement"
    end

    click_button "회원가입"
  end

  # 로그아웃 헬퍼
  def log_out
    click_button "로그아웃" if page.has_button?("로그아웃")
  end

  # 로그인 상태 확인 헬퍼
  # @return [Boolean] 로그인 상태 여부
  def logged_in?
    page.has_link?("마이페이지") || page.has_button?("로그아웃")
  end

  # 특정 경로에 있지 않음을 확인하는 헬퍼
  # Capybara 기본 assert_no_current_path의 wrapper
  # @param path [String] 확인할 경로
  # @param wait [Integer] 최대 대기 시간 (초)
  def assert_not_on(path, wait: 5)
    assert_no_current_path path, wait: wait
  end

  # Flash 메시지 확인 헬퍼
  # @param message [String] 확인할 메시지 (부분 일치)
  def assert_flash_message(message)
    assert_selector ".flash, [role='alert']", text: message, wait: 3
  end

  # 모달이 열렸는지 확인
  # @param modal_id [String] 모달 ID (선택)
  def assert_modal_open(modal_id = nil)
    if modal_id
      assert_selector "##{modal_id}[aria-hidden='false'], ##{modal_id}:not(.hidden)", wait: 3
    else
      assert_selector "[role='dialog']:not(.hidden), .modal:not(.hidden)", wait: 3
    end
  end

  # 모달이 닫혔는지 확인
  def assert_modal_closed
    assert_no_selector "[role='dialog']:not(.hidden), .modal:not(.hidden)", wait: 3
  end

  # 페이지 로드 완료 대기
  # Turbo/Stimulus 환경에서 유용
  def wait_for_page_load
    # Turbo 로딩 인디케이터가 사라질 때까지 대기
    assert_no_selector ".turbo-progress-bar", wait: 10
  end

  # 특정 요소가 나타날 때까지 대기 후 클릭
  # @param selector [String] CSS 셀렉터
  # @param wait [Integer] 최대 대기 시간
  def click_when_visible(selector, wait: 5)
    find(selector, wait: wait).click
  end

  # 디버그용: 현재 페이지 스크린샷 저장
  def debug_screenshot(name = "debug")
    page.save_screenshot("tmp/screenshots/#{name}_#{Time.current.to_i}.png")
  end
end
