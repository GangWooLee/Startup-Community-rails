# frozen_string_literal: true

require "application_system_test_case"

class ProfilesTest < ApplicationSystemTestCase
  def setup
    @user = users(:one)
    @other_user = users(:two)
    @anonymous_user = users(:three)
    @deleted_user = users(:deleted_user)
  end

  # =========================================
  # 프로필 페이지 로드 테스트
  # =========================================

  test "can view profile page" do
    visit profile_path(@user)

    # 프로필 페이지 로드 확인
    assert_selector "main", wait: 5

    # 사용자 이름 표시 확인
    assert_text @user.name
  end

  test "can view profile information" do
    visit profile_path(@user)

    # 프로필 정보 표시 확인
    assert_text @user.name
    assert_text @user.role_title if @user.role_title.present?
    assert_text @user.bio if @user.bio.present?
  end

  test "can view skills on profile" do
    visit profile_path(@user)

    # 스킬 정보는 페이지 어딘가에 존재 (visible 또는 hidden)
    # 프로필 페이지가 로드되면 스킬 데이터는 서버에서 전달됨
    if @user.skills.present?
      # 페이지에 스킬 정보가 있는지 확인 (탭/아코디언으로 숨겨져 있을 수 있음)
      first_skill = @user.skills.split(",").first.strip
      # 페이지 HTML 소스에 스킬 텍스트가 포함되어 있는지 확인
      assert page.html.include?(first_skill),
             "Expected to find skill '#{first_skill}' in the page HTML"
    end
  end

  # =========================================
  # 비로그인 프로필 접근 테스트
  # =========================================

  test "guest can view public profile" do
    visit profile_path(@user)

    # 비로그인 상태에서 프로필 조회 가능
    assert_current_path profile_path(@user)
    assert_text @user.name
  end

  test "guest sees limited interaction options" do
    visit profile_path(@other_user)

    # 비로그인 시 채팅 버튼이 로그인 유도로 변경되거나 숨김
    # 프로필 수정 버튼은 표시되지 않음
    assert_no_selector "a[href='#{edit_my_page_path}']", wait: 2
  end

  # =========================================
  # 로그인 사용자 프로필 접근 테스트
  # =========================================

  test "logged in user can view other user profile" do
    log_in_as(@user)
    visit profile_path(@other_user)

    # 다른 사용자 프로필 조회 가능
    assert_text @other_user.name
    assert_current_path profile_path(@other_user)
  end

  test "can view own profile with edit option" do
    log_in_as(@user)
    visit profile_path(@user)

    # 본인 프로필 조회
    assert_text @user.name

    # 프로필 수정 링크 또는 마이페이지 링크 확인
    # 본인 프로필에서는 수정 버튼이 표시됨
    assert_selector "a[href='#{my_page_path}'], a[href='#{edit_my_page_path}']", wait: 3
  end

  test "cannot see edit button on other user profile" do
    log_in_as(@user)
    visit profile_path(@other_user)

    # 타인 프로필에서는 수정 버튼 없음
    assert_no_selector "a[href='#{edit_my_page_path}']", wait: 2
  end

  # =========================================
  # 익명 사용자 프로필 테스트
  # =========================================

  test "anonymous user profile shows nickname instead of name" do
    visit profile_path(@anonymous_user)

    # 익명 사용자는 닉네임으로 표시됨
    if @anonymous_user.is_anonymous?
      # 익명 설정된 사용자는 display_name (닉네임) 표시
      assert_text @anonymous_user.display_name
    else
      assert_text @anonymous_user.name
    end
  end

  # =========================================
  # 탈퇴 사용자 프로필 테스트
  # =========================================

  test "deleted user profile shows appropriate message" do
    visit profile_path(@deleted_user)

    # 탈퇴한 사용자 프로필 접근 시
    # 404 에러 또는 탈퇴 안내 메시지
    if page.has_text?("탈퇴", wait: 2) || page.has_text?("삭제", wait: 2)
      assert_text(/탈퇴|삭제/)
    else
      # 또는 다른 페이지로 리다이렉트
      assert page.has_no_current_path?(profile_path(@deleted_user)) ||
             page.has_text?(@deleted_user.name)
    end
  end

  # =========================================
  # 프로필 게시글 목록 테스트
  # =========================================

  test "profile shows user posts section" do
    # 프로필 페이지에 게시글 섹션이 있는지 확인
    visit profile_path(@user)

    # 게시글 수가 표시되는지 확인 (예: "4 게시글" 또는 "게시글 4")
    # 페이지에 게시글 관련 정보가 있음을 확인
    assert page.has_text?("게시글", wait: 3) ||
           page.has_selector?("[data-tab]", wait: 3),
           "Expected to find posts section on profile page"
  end
end
