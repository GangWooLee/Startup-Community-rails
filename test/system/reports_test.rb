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

    # 더보기 버튼 클릭
    find("button[data-action*='dropdown#toggle']").click

    # 신고하기 버튼 확인 및 클릭
    within("[data-dropdown-target='menu']") do
      assert_selector "button", text: "신고하기"
      find("button", text: "신고하기").click
    end

    # 모달 열림 확인
    assert_selector "#report-modal", visible: true

    # 신고 대상 정보 확인
    within("#report-modal") do
      assert_selector "[data-report-modal-target='targetLabel']"

      # 신고 사유 선택
      choose "스팸"

      # 상세 설명 입력
      fill_in "report[description]", with: "테스트 신고입니다."

      # 신고하기 버튼 클릭
      click_button "신고하기"
    end

    # 신고 완료 확인 (페이지 리다이렉트 또는 성공 메시지)
    # Turbo가 리다이렉트하거나 성공 모달을 보여줌
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
  # 사용자 프로필 신고하기
  # =========================================

  test "can report user from profile page" do
    log_in_as(@user)
    visit profile_path(@other_user)

    # 더보기 버튼 클릭
    find("button[data-action*='dropdown#toggle']").click

    # 신고하기 버튼 확인
    within("[data-dropdown-target='menu']") do
      assert_selector "button", text: "신고하기"
    end
  end

  test "report button not shown on own profile" do
    log_in_as(@user)
    visit profile_path(@user)

    # 자신의 프로필에는 신고 버튼이 없어야 함
    assert_no_selector "button[data-action*='report-modal#open']"
  end

  # =========================================
  # 모달 UI 테스트
  # =========================================

  test "report modal can be closed with close button" do
    log_in_as(@user)
    visit post_path(@post)

    # 더보기 → 신고하기
    find("button[data-action*='dropdown#toggle']").click
    within("[data-dropdown-target='menu']") do
      find("button", text: "신고하기").click
    end

    assert_selector "#report-modal", visible: true

    # 닫기 버튼 클릭
    within("#report-modal") do
      find("button[data-action='click->report-modal#close']", match: :first).click
    end

    # 모달 닫힘 확인
    assert_no_selector "#report-modal", visible: true
  end

  test "report modal can be closed by clicking overlay" do
    log_in_as(@user)
    visit post_path(@post)

    # 더보기 → 신고하기
    find("button[data-action*='dropdown#toggle']").click
    within("[data-dropdown-target='menu']") do
      find("button", text: "신고하기").click
    end

    assert_selector "#report-modal", visible: true

    # 오버레이 클릭 (배경)
    find(".fixed.inset-0.bg-gray-500", match: :first).click

    # 모달 닫힘 확인
    assert_no_selector "#report-modal", visible: true
  end

  test "report modal shows all reason options" do
    log_in_as(@user)
    visit post_path(@post)

    # 더보기 → 신고하기
    find("button[data-action*='dropdown#toggle']").click
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

  private

  def log_in_as(user)
    visit login_path
    fill_in "이메일", with: user.email
    fill_in "비밀번호", with: "password"
    click_button "로그인"
    assert_current_path root_path
  end
end
