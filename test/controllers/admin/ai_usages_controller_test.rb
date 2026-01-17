require "test_helper"

class Admin::AiUsagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @user = users(:one)
    # Sign in as admin (fixture password is 'test1234')
    post login_path, params: { email: @admin.email, password: "test1234" }
  end

  test "should update bonus credits" do
    original_bonus = @user.ai_bonus_credits

    patch update_bonus_admin_ai_usage_path(@user), params: { bonus: 10 }

    assert_redirected_to admin_ai_usage_path(@user)
    @user.reload
    assert_equal 10, @user.ai_bonus_credits
    assert_includes flash[:notice], "보너스 크레딧이 10개로 설정"

    # Cleanup
    @user.update!(ai_bonus_credits: original_bonus)
  end

  test "should set remaining by calculating bonus" do
    # Reset to known state
    @user.update!(ai_bonus_credits: 0, ai_analysis_limit: 5)

    patch set_remaining_admin_ai_usage_path(@user), params: { remaining: 20 }

    assert_redirected_to admin_ai_usage_path(@user)
    @user.reload

    # With limit=5, used=0, remaining=20 needs bonus=15
    expected_bonus = 20 - (5 - @user.idea_analyses.count)
    assert_equal expected_bonus, @user.ai_bonus_credits
    assert_equal 20, @user.ai_analyses_remaining

    # Cleanup
    @user.update!(ai_bonus_credits: 0)
  end

  test "should update limit" do
    patch update_limit_admin_ai_usage_path(@user), params: { limit: 50 }

    assert_redirected_to admin_ai_usage_path(@user)
    @user.reload
    assert_equal 50, @user.ai_analysis_limit

    # Cleanup
    @user.update!(ai_analysis_limit: nil)
  end

  test "should reset limit to default when set to 0" do
    @user.update!(ai_analysis_limit: 50)

    patch update_limit_admin_ai_usage_path(@user), params: { limit: 0 }

    assert_redirected_to admin_ai_usage_path(@user)
    @user.reload
    assert_nil @user.ai_analysis_limit
  end

  test "bonus credits should affect remaining count" do
    @user.update!(ai_bonus_credits: 0, ai_analysis_limit: 5)
    base_remaining = @user.ai_analyses_remaining

    @user.update!(ai_bonus_credits: 10)
    assert_equal base_remaining + 10, @user.ai_analyses_remaining

    # Cleanup
    @user.update!(ai_bonus_credits: 0)
  end

  # === 날짜 필터 및 사용 이력 테스트 ===

  test "should get index with top users view by default" do
    get admin_ai_usages_path

    assert_response :success
    assert_select "h2", /Top 사용자/
  end

  test "should get index with history view" do
    get admin_ai_usages_path(view: "history")

    assert_response :success
    assert_select "h2", /사용 이력/
  end

  test "should filter statistics by date range" do
    # 오늘 날짜로 필터링
    today = Date.current.to_s

    get admin_ai_usages_path(from_date: today, to_date: today)

    assert_response :success
    # 날짜 필터 표시 확인
    assert_select "span.text-primary", /필터된 분석/
  end

  test "should maintain filters when switching tabs" do
    today = Date.current.to_s

    get admin_ai_usages_path(from_date: today, to_date: today, view: "history")

    assert_response :success
    assert_select "input[name='from_date'][value='#{today}']"
    assert_select "input[name='to_date'][value='#{today}']"
  end

  test "history view should paginate results" do
    get admin_ai_usages_path(view: "history", page: 1)

    assert_response :success
    # 사용 이력 테이블 표시 확인
    assert_select "h2", /사용 이력/
  end

  test "history view should search by user name or email" do
    get admin_ai_usages_path(view: "history", q: @user.email)

    assert_response :success
  end

  # === 잘못된 날짜 형식 에러 처리 테스트 ===

  test "invalid date format in index does not cause 500 error" do
    # 잘못된 날짜 형식으로 요청
    get admin_ai_usages_path(from_date: "invalid-date", to_date: "also-invalid")

    # 500 에러가 아닌 정상 응답
    assert_response :success
    # 에러 메시지 표시 확인
    assert_match(/잘못된 날짜 형식/, response.body)
  end

  test "invalid date format in export does not cause 500 error" do
    # 잘못된 날짜 형식으로 CSV 내보내기 요청
    get export_admin_ai_usages_path(format: :csv, from_date: "not-a-date")

    # 500 에러가 아닌 정상 응답 (CSV 반환)
    assert_response :success
    assert_equal "text/csv; charset=utf-8", response.content_type
  end
end
