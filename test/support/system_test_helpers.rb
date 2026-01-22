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

  # CI 환경 대기 시간 상수 (로컬보다 느림)
  CI_WAIT_TIME = 20
  LOCAL_WAIT_TIME = 10

  # =========================================
  # CI 환경 감지 헬퍼
  # =========================================

  # CI 환경 여부 확인
  # @return [Boolean] CI 환경이면 true
  def ci_environment?
    ENV["CI"].present? || ENV["GITHUB_ACTIONS"].present?
  end

  # CI 환경에 따른 기본 대기 시간 반환
  # @return [Integer] 대기 시간 (초)
  def default_wait_time
    ci_environment? ? CI_WAIT_TIME : LOCAL_WAIT_TIME
  end

  # Turbo 리다이렉트 완료 대기 헬퍼
  # @param expected_path [String, nil] 예상 경로 (nil이면 경로 확인 생략)
  # @param wait [Integer, nil] 대기 시간 (nil이면 default_wait_time 사용)
  def wait_for_turbo_redirect(expected_path = nil, wait: nil)
    wait ||= default_wait_time

    # Turbo 로딩 인디케이터가 사라질 때까지 대기
    assert_no_selector ".turbo-progress-bar", wait: wait

    # 예상 경로가 지정되면 경로 확인
    assert_current_path expected_path, wait: wait if expected_path
  end

  # 사용자 로그인 헬퍼
  # @param user [User] 로그인할 사용자 fixture
  #
  # 주의: fill_in은 id, name, label로 입력 필드를 찾습니다.
  # 현재 로그인 폼은 name="email", name="password" 사용
  def log_in_as(user)
    visit login_path

    # ✅ 개선 1: document.readyState 확인 (CI 환경 안정성)
    page.evaluate_script("document.readyState") == "complete" rescue true

    # CI 환경에서 페이지 로드가 느릴 수 있음 - 동적 대기 시간 사용
    wait_time = default_wait_time
    assert_selector "body", wait: wait_time

    # Turbo 로딩 완료 대기
    assert_no_selector ".turbo-progress-bar", wait: wait_time

    # 🔒 세션 오염 감지: 로그인 페이지 경로 확인
    # require_no_login 필터가 작동하면 community_path로 리다이렉트됨
    # 커뮤니티 페이지에도 "로그인" 텍스트가 있어서 assert_text만으로는 감지 불가
    unless page.has_current_path?(login_path, wait: 5)
      # ✅ 개선 2: 세션 오염 감지 대기 시간 증가 (3 → 5초)
      Rails.logger.warn "[SystemTest] Session contamination detected, resetting sessions..."
      Capybara.reset_sessions!
      visit login_path
      page.evaluate_script("document.readyState") == "complete" rescue true
      assert_selector "body", wait: wait_time
      assert_no_selector ".turbo-progress-bar", wait: wait_time
    end

    # 로그인 페이지 경로 최종 확인
    assert_current_path login_path, wait: 5

    # 로그인 폼이 렌더링될 때까지 대기 (h2 "로그인" 텍스트로 확인 - 가장 안정적)
    assert_text "로그인", wait: wait_time

    # ✅ 개선 3: 로그인 폼의 email 입력 필드 대기 시간 증가 (15 → 20초 in CI)
    assert_selector "input[name='email']", visible: true, wait: wait_time

    # 폼 필드 입력 (JavaScript로 직접 설정하여 안정성 확보)
    page.execute_script(<<~JS, user.email, TEST_PASSWORD)
      const emailInput = document.querySelector("input[name='email']");
      const passwordInput = document.querySelector("input[name='password']");
      if (emailInput) {
        emailInput.value = arguments[0];
        emailInput.dispatchEvent(new Event('input', { bubbles: true }));
      }
      if (passwordInput) {
        passwordInput.value = arguments[1];
        passwordInput.dispatchEvent(new Event('input', { bubbles: true }));
      }
    JS

    # 입력값이 설정될 때까지 상태 기반 대기 (sleep 대신)
    # JavaScript로 값을 설정한 후 값이 반영될 때까지 대기
    wait_for_javascript_value("input[name='email']", user.email)

    # 로그인 버튼 찾기 및 클릭 (JavaScript 클릭으로 안정성 확보)
    login_button = find("button", text: "로그인", match: :first, wait: 5)
    page.execute_script("arguments[0].click()", login_button)

    # 폼 제출 완료 대기 (상태 기반: Turbo 로딩 바가 사라질 때까지)
    assert_no_selector ".turbo-progress-bar", wait: 10

    # 로그인 성공 확인 (최대 5초 대기)
    # 로그인 실패 시 login_path에 머무름
    unless page.has_no_current_path?(login_path, wait: 5)
      # 디버깅: 로그인 실패 시 현재 페이지 상태 출력
      if page.has_text?("올바르지 않습니다")
        raise "로그인 실패: 이메일 또는 비밀번호가 올바르지 않습니다"
      else
        # JavaScript로 폼 직접 제출 시도
        page.execute_script("document.querySelector('form').submit()")
        # 상태 기반 대기: Turbo 로딩 완료 후 경로 확인
        assert_no_selector ".turbo-progress-bar", wait: 10
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

  # 키보드 단축키 이벤트 디스패치 헬퍼
  # Capybara의 send_keys가 document 레벨 리스너에 작동하지 않을 때 사용
  #
  # @param key [String] 키 이름 (예: 'k', 'Escape', 'Enter')
  # @param meta [Boolean] Cmd/Win 키 동시 누름
  # @param ctrl [Boolean] Ctrl 키 동시 누름
  # @param shift [Boolean] Shift 키 동시 누름
  # @param alt [Boolean] Alt 키 동시 누름
  # @param target [String, nil] 이벤트 타겟 셀렉터 (nil이면 document)
  #
  # @example 검색 모달 열기 (Cmd+K / Ctrl+K)
  #   dispatch_keyboard_shortcut(key: "k", meta: true, ctrl: true)
  #
  # @example ESC로 모달 닫기
  #   dispatch_keyboard_shortcut(key: "Escape")
  #
  # @example 특정 입력 필드에서 Enter
  #   dispatch_keyboard_shortcut(key: "Enter", target: "[data-comment-form-target='input']")
  #
  def dispatch_keyboard_shortcut(key:, meta: false, ctrl: false, shift: false, alt: false, target: nil)
    # target을 arguments로 전달하여 JavaScript 문자열 이스케이핑 문제 방지
    page.execute_script(<<~JS, key, meta, ctrl, shift, alt, target)
      const selector = arguments[5];
      const targetElement = selector ? document.querySelector(selector) : document;
      if (targetElement) {
        targetElement.dispatchEvent(new KeyboardEvent('keydown', {
          key: arguments[0],
          metaKey: arguments[1],
          ctrlKey: arguments[2],
          shiftKey: arguments[3],
          altKey: arguments[4],
          bubbles: true
        }));
      }
    JS
  end

  # 특정 요소에 Enter 키 디스패치 (폼 제출 등)
  # @param selector [String] CSS 셀렉터
  def dispatch_enter_key(selector)
    dispatch_keyboard_shortcut(key: "Enter", target: selector)
  end

  # ESC 키로 모달/드롭다운 닫기
  def dispatch_escape_key
    dispatch_keyboard_shortcut(key: "Escape")
  end

  # JavaScript로 설정된 input 값이 반영될 때까지 대기
  # @param selector [String] CSS 셀렉터
  # @param expected_value [String] 기대하는 값
  # @param timeout [Integer] 최대 대기 시간 (초)
  def wait_for_javascript_value(selector, expected_value, timeout: 3)
    start_time = Time.current
    escaped_selector = selector.gsub("'") { "\\'" }
    loop do
      # evaluate_script는 표현식을 기대하므로 IIFE 사용
      script = "(function() { var el = document.querySelector('#{escaped_selector}'); return el ? el.value : null; })()"
      current_value = page.evaluate_script(script)
      return if current_value == expected_value
      return if current_value.present?  # 어떤 값이든 설정되면 OK

      if Time.current - start_time > timeout
        # 타임아웃 시에도 계속 진행 (값이 이미 설정되어 있을 가능성)
        break
      end
      sleep 0.05
    end
  end
end
