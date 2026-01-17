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

  # =========================================
  # AI 분석 기록 페이지 Tests
  # =========================================

  test "GET /my/idea_analyses requires login" do
    get my_idea_analyses_path
    assert_redirected_to login_path
  end

  test "GET /my/idea_analyses shows AI usage history for logged in user" do
    log_in_as(@user)
    get my_idea_analyses_path
    assert_response :success
  end

  test "GET /my/idea_analyses displays usage logs based on AiUsageLog" do
    log_in_as(@user)

    # user one의 로그 생성 (분석 결과 있음)
    analysis = IdeaAnalysis.create!(
      user: @user,
      idea: "테스트 아이디어",
      analysis_result: { summary: "테스트 요약" },
      score: 80
    )

    # 연관된 사용 로그 생성
    usage_log = AiUsageLog.create!(
      user: @user,
      idea_analysis: analysis,
      idea_summary: "테스트 아이디어",
      status: :completed,
      score: 80,
      is_real_analysis: true
    )

    get my_idea_analyses_path
    assert_response :success
    assert_select "p", /테스트 아이디어/
  end

  test "GET /my/idea_analyses shows expired logs without analysis link" do
    log_in_as(@user)

    # 분석 결과가 삭제된 로그 (idea_analysis_id가 NULL)
    expired_log = AiUsageLog.create!(
      user: @user,
      idea_analysis: nil,
      idea_summary: "만료된 분석 아이디어",
      status: :completed,
      score: 65,
      is_real_analysis: true
    )

    get my_idea_analyses_path
    assert_response :success
    # 만료된 분석은 표시되지만 클릭 불가
    assert_select "p", /만료된 분석 아이디어/
    # 만료 메시지 표시
    assert_select "p", /7일 경과로 상세 결과가 삭제되었습니다/
  end

  test "GET /my/idea_analyses shows only current user's logs" do
    log_in_as(@user)

    # 다른 유저의 로그
    other_user = users(:two)
    other_user.update_columns(profile_completed: true)
    other_log = AiUsageLog.create!(
      user: other_user,
      idea_summary: "다른 유저의 아이디어",
      status: :completed,
      score: 90
    )

    get my_idea_analyses_path
    assert_response :success
    # 다른 유저의 아이디어는 표시되지 않음
    assert_select "p", { text: /다른 유저의 아이디어/, count: 0 }
  end

  private

  def log_in_as(user)
    post login_path, params: {
      email: user.email,
      password: TEST_PASSWORD
    }
  end
end
