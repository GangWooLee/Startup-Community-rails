# frozen_string_literal: true

require "application_system_test_case"

class ReportsTest < ApplicationSystemTestCase
  def setup
    @user = users(:one)
    @other_user = users(:two)
    @post = posts(:two)  # user :two의 게시글
  end

  # =========================================
  # 게시글 신고하기 (Task #4)
  # =========================================

  test "can report post from post detail page" do
    log_in_as(@user)
    visit post_path(@post)

    # 더보기 버튼 클릭 (data-testid로 특정)
    within("[data-testid='post-actions-dropdown']") do
      toggle_button = find("button[data-action*='dropdown#toggle']")
      sleep 0.5  # Stimulus 컨트롤러 연결 대기 (CI 환경용)
      page.execute_script("arguments[0].click()", toggle_button)
    end

    # CI 환경에서 드롭다운 메뉴가 나타날 때까지 충분히 대기
    assert_selector "[data-dropdown-target='menu']", visible: true, wait: 10

    # 신고하기 버튼 확인 및 클릭
    within("[data-dropdown-target='menu']") do
      assert_selector "button", text: "신고하기"
      report_button = find("button", text: "신고하기")
      page.execute_script("arguments[0].click()", report_button)
    end

    # 모달 열림 확인 (CI 환경에서 충분한 대기 시간)
    assert_selector "#report-modal", visible: true, wait: 10

    # 신고 대상 정보 확인
    within("#report-modal") do
      assert_selector "[data-report-modal-target='targetLabel']"

      # 신고 사유 선택 (CI 환경에서 요소 클릭 차단 방지를 위해 JavaScript 사용)
      spam_radio = find("input[type='radio'][value='spam']")
      page.execute_script("arguments[0].click()", spam_radio)

      # 상세 설명 입력
      fill_in "report[description]", with: "테스트 신고입니다."

      # 신고하기 버튼 클릭 (JavaScript로 실행하여 Turbo 폼 제출 보장)
      submit_btn = find("button[data-report-modal-target='submitBtn']")
      page.execute_script("arguments[0].click()", submit_btn)
    end

    # 신고 완료 확인 (Turbo Stream 응답 대기)
    assert_text "신고 접수 완료", wait: 10

    # 확인 버튼 클릭하여 모달 닫기 (JavaScript로 실행)
    within("#report-modal") do
      confirm_btn = find("button", text: "확인")
      page.execute_script("arguments[0].click()", confirm_btn)
    end

    # 모달 닫힘 확인
    assert_no_selector "#report-modal", visible: true, wait: 5
  end

  test "report button not shown for own post" do
    log_in_as(@user)
    own_post = posts(:one)  # user :one의 게시글
    visit post_path(own_post)

    # 수정 버튼만 보이고 신고하기 버튼은 없어야 함
    assert_selector "a", text: "수정"
    assert_no_selector "button[data-action*='report-modal#open']"
  end

  test "report button not shown when not logged in" do
    visit post_path(@post)

    # 신고 버튼이 없어야 함
    assert_no_selector "button[data-action*='report-modal#open']"
  end

  # =========================================
  # 사용자 프로필 액션
  # =========================================

  test "profile dropdown opens correctly" do
    log_in_as(@user)
    visit profile_path(@other_user)

    # 더보기 버튼 클릭 - JavaScript로 직접 실행 (Stimulus 타이밍 이슈 회피)
    within("[data-testid='profile-actions-dropdown']") do
      toggle_button = find("button[data-action*='dropdown#toggle']")
      sleep 0.5  # Stimulus 컨트롤러 연결 대기 (CI 환경용)
      # JavaScript로 직접 클릭 이벤트 발생
      page.execute_script("arguments[0].click()", toggle_button)
    end

    # 드롭다운 메뉴가 열림 확인 (CI 환경 타이밍 이슈 대응)
    assert_selector "[data-dropdown-target='menu']", visible: true, wait: 10

    # 프로필 링크 복사 버튼 확인
    assert_text "프로필 링크 복사", wait: 3
  end

  test "profile dropdown not shown on own profile" do
    log_in_as(@user)
    visit profile_path(@user)

    # 자신의 프로필에는 더보기 드롭다운이 없어야 함
    assert_no_selector "[data-testid='profile-actions-dropdown']"
  end

  # =========================================
  # 모달 UI 테스트
  # =========================================

  test "report modal can be closed with close button" do
    log_in_as(@user)
    visit post_path(@post)

    # 더보기 → 신고하기 (data-testid로 특정)
    within("[data-testid='post-actions-dropdown']") do
      toggle_button = find("button[data-action*='dropdown#toggle']")
      sleep 0.5  # Stimulus 컨트롤러 연결 대기 (CI 환경용)
      page.execute_script("arguments[0].click()", toggle_button)
    end
    # CI 환경에서 드롭다운 메뉴가 나타날 때까지 충분히 대기
    assert_selector "[data-dropdown-target='menu']", visible: true, wait: 10
    within("[data-dropdown-target='menu']") do
      report_button = find("button", text: "신고하기")
      page.execute_script("arguments[0].click()", report_button)
    end

    # 모달 열림 확인 (CI 환경에서 충분한 대기 시간)
    assert_selector "#report-modal", visible: true, wait: 10

    # 닫기 버튼 클릭
    within("#report-modal") do
      find("button[data-action='click->report-modal#close']", match: :first).click
    end

    # 모달 닫힘 확인
    assert_no_selector "#report-modal", visible: true, wait: 5
  end

  test "report modal can be closed with escape key" do
    log_in_as(@user)
    visit post_path(@post)

    # 더보기 → 신고하기 (data-testid로 특정)
    within("[data-testid='post-actions-dropdown']") do
      toggle_button = find("button[data-action*='dropdown#toggle']")
      sleep 0.5  # Stimulus 컨트롤러 연결 대기 (CI 환경용)
      page.execute_script("arguments[0].click()", toggle_button)
    end
    # CI 환경에서 드롭다운 메뉴가 나타날 때까지 충분히 대기
    assert_selector "[data-dropdown-target='menu']", visible: true, wait: 10
    within("[data-dropdown-target='menu']") do
      report_btn = find("button", text: "신고하기")
      page.execute_script("arguments[0].click()", report_btn)
    end

    assert_selector "#report-modal", visible: true, wait: 5

    # ESC 키로 닫기 (JavaScript로 키 이벤트 발생)
    page.execute_script("document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', code: 'Escape', keyCode: 27, which: 27, bubbles: true }))")

    # 모달 닫힘 확인
    assert_no_selector "#report-modal", visible: true, wait: 5
  end

  test "report modal shows all reason options" do
    log_in_as(@user)
    visit post_path(@post)

    # 더보기 → 신고하기 (data-testid로 특정)
    within("[data-testid='post-actions-dropdown']") do
      toggle_button = find("button[data-action*='dropdown#toggle']")
      sleep 0.5  # Stimulus 컨트롤러 연결 대기 (CI 환경용)
      page.execute_script("arguments[0].click()", toggle_button)
    end
    # CI 환경에서 드롭다운 메뉴가 나타날 때까지 충분히 대기
    assert_selector "[data-dropdown-target='menu']", visible: true, wait: 10
    within("[data-dropdown-target='menu']") do
      find("button", text: "신고하기").click
    end

    # 모든 신고 사유 옵션 확인
    within("#report-modal") do
      assert_selector "input[type='radio'][value='spam']"
      assert_selector "input[type='radio'][value='inappropriate']"
      assert_selector "input[type='radio'][value='harassment']"
      assert_selector "input[type='radio'][value='scam']"
      assert_selector "input[type='radio'][value='other']"
    end
  end
end
