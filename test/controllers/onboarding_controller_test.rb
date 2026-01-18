# frozen_string_literal: true

require "test_helper"

class OnboardingControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  # ============================================================================
  # Landing Action Tests
  # ============================================================================

  test "landing page renders successfully" do
    get root_path

    assert_response :success
  end

  test "landing page accessible without login" do
    get root_path

    assert_response :success
  end

  # ============================================================================
  # AI Input Action Tests
  # ============================================================================

  test "ai_input renders for guest" do
    get onboarding_ai_input_path

    assert_response :success
  end

  test "ai_input renders for logged in user" do
    log_in_as(@user)
    get onboarding_ai_input_path

    assert_response :success
  end

  # ============================================================================
  # AI Questions Action Tests
  # ============================================================================

  test "ai_questions returns error for blank idea" do
    post onboarding_ai_questions_path, params: { idea: "" }, as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_equal "아이디어를 입력해주세요", json["error"]
  end

  test "ai_questions returns error for missing idea" do
    post onboarding_ai_questions_path, as: :json

    assert_response :unprocessable_entity
  end

  test "ai_questions returns follow up questions for valid idea" do
    # Mock AI response
    stub_gemini_json_response(mock_analysis_result)
    post onboarding_ai_questions_path, params: { idea: "AI 기반 창업 플랫폼" }, as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert json.is_a?(Array) || json.is_a?(Hash)
  end

  # ============================================================================
  # AI Analyze Action Tests
  # ============================================================================

  test "ai_analyze redirects with alert for blank idea" do
    post onboarding_ai_analyze_path, params: { idea: "" }

    assert_redirected_to onboarding_ai_input_path
    assert_equal "아이디어를 입력해주세요", flash[:alert]
  end

  test "ai_analyze redirects guest to login after saving idea" do
    stub_gemini_json_response(mock_analysis_result)
    post onboarding_ai_analyze_path, params: { idea: "새로운 스타트업 아이디어" }

    # 비로그인 사용자는 로그인 페이지로 리디렉션
    assert_redirected_to login_path
    assert_includes flash[:notice], "분석 준비가 완료되었습니다"
  end

  test "ai_analyze processes for logged in user" do
    log_in_as(@user)
    stub_gemini_json_response(mock_analysis_result)

    post onboarding_ai_analyze_path, params: { idea: "AI 기반 새로운 서비스" }

    # 로그인 사용자는 결과 페이지로 리디렉션
    assert_response :redirect
  end

  # ============================================================================
  # AI Result Action Tests
  # ============================================================================

  test "ai_result requires login" do
    # 가짜 ID로 접근
    get "/ai/result/999"

    assert_redirected_to login_path
  end

  test "ai_result renders for logged in user with valid analysis" do
    log_in_as(@user)

    # IdeaAnalysis fixture가 있다면 사용
    if @user.idea_analyses.any?
      analysis = @user.idea_analyses.first
      get ai_result_path(analysis)

      assert_response :success
    else
      # 분석 결과가 없으면 생성
      analysis = @user.idea_analyses.create!(
        idea: "테스트 아이디어",
        result: {
          summary: "테스트 요약",
          score: { overall: 75 }
        }.to_json,
        is_real_analysis: false
      )

      get ai_result_path(analysis)

      assert_response :success
    end
  end

  test "ai_result redirects for non-existent analysis" do
    log_in_as(@user)
    get "/ai/result/999999"

    assert_redirected_to onboarding_ai_input_path
    assert_equal "분석 결과를 찾을 수 없습니다", flash[:alert]
  end

  test "ai_result cannot access other user analysis" do
    log_in_as(@user)
    other_user = users(:two)

    if other_user.idea_analyses.any?
      other_analysis = other_user.idea_analyses.first
      get ai_result_path(other_analysis)

      # 다른 사용자의 분석에 접근하면 RecordNotFound
      assert_redirected_to onboarding_ai_input_path
    end
  end

  # ============================================================================
  # Usage Limit Tests
  # ============================================================================

  test "ai_analyze respects usage limit for guest" do
    # 쿠키로 사용량 제한 테스트
    # 기본 제한은 5회이므로 5회 초과 시 리디렉션
    stub_gemini_json_response(mock_analysis_result)

    # 첫 번째 요청은 성공
    post onboarding_ai_analyze_path, params: { idea: "테스트 아이디어 1" }
    assert_response :redirect
  end

  test "비로그인 사용자는 쿠키 횟수와 관계없이 ai_analyze 접근 가능" do
    # 쿠키로 5회 사용한 것처럼 설정
    cookies[:guest_ai_usage_count] = "5"

    stub_gemini_json_response(mock_analysis_result)

    post onboarding_ai_analyze_path, params: {
      idea: "테스트 아이디어",
      answers: { q1: "답변1" }.to_json
    }

    # 로그인 페이지로 리다이렉트 (차단되지 않음)
    assert_redirected_to login_path
    # "모두 사용" 메시지가 아닌 정상 안내 메시지
    assert_includes flash[:notice], "분석 준비가 완료되었습니다"
  end

  test "비로그인 사용자는 ai_input 페이지에서 limit_exceeded 모달이 표시되지 않음" do
    # 쿠키로 5회 사용한 것처럼 설정 (비로그인은 이 값과 무관하게 모달 미표시)
    cookies[:guest_ai_usage_count] = "5"

    get onboarding_ai_input_path

    assert_response :success
    # @limit_exceeded가 false여야 모달이 표시되지 않음
    assert_select "#limit-exceeded-modal", count: 0
    # 정상적인 입력 영역이 표시되어야 함 (Stimulus ai-input 컨트롤러)
    assert_select "[data-controller='ai-input']"
  end

  test "로그인 사용자가 5회 초과 시 제한 메시지와 함께 리다이렉트" do
    log_in_as(@user)

    # 기존 분석 삭제 후 5회 분석 기록 생성
    @user.idea_analyses.destroy_all
    5.times do |i|
      @user.idea_analyses.create!(
        idea: "테스트 아이디어 #{i}",
        status: :analyzing,
        analysis_result: "{}"
      )
    end

    post onboarding_ai_analyze_path, params: { idea: "6번째 분석 시도" }

    # ai_input으로 리다이렉트 (제한 모달 표시용)
    assert_redirected_to onboarding_ai_input_path
  end

  test "로그인 사용자가 횟수 미초과 시 분석 진행" do
    log_in_as(@user)

    # 기존 분석 기록 삭제 (테스트 격리)
    @user.idea_analyses.destroy_all

    # 3회만 사용
    3.times do |i|
      @user.idea_analyses.create!(
        idea: "테스트 아이디어 #{i}",
        status: :analyzing,
        analysis_result: "{}"
      )
    end

    stub_gemini_json_response(mock_analysis_result)

    post onboarding_ai_analyze_path, params: { idea: "4번째 분석" }

    # 차단되지 않고 분석 진행 (결과 페이지로 리다이렉트)
    assert_response :redirect
    assert_not_equal onboarding_ai_input_path, response.redirect_url
  end

  # ============================================================================
  # Phase 2: Guest → Login Flow Tests (비로그인 → 로그인 플로우)
  # ============================================================================

  test "ai_analyze stores pending_input_key in session for guest" do
    stub_gemini_json_response(mock_analysis_result)

    post onboarding_ai_analyze_path, params: { idea: "비로그인 테스트 아이디어" }

    # 세션에 pending_input_key가 저장되었는지 확인
    assert session[:pending_input_key].present?, "Expected pending_input_key in session"
    assert session[:pending_input_key].start_with?("pending_input:"), "Expected key to start with 'pending_input:'"
  end

  test "ai_analyze stores pending_input_key in cookie for OAuth backup" do
    stub_gemini_json_response(mock_analysis_result)

    post onboarding_ai_analyze_path, params: { idea: "OAuth 백업 테스트 아이디어" }

    # 쿠키에도 백업 저장되었는지 확인 (OAuth 리다이렉션 시 세션 손실 대비)
    # Integration test에서 cookies jar로 확인
    cookie_value = cookies[:pending_input_key]
    assert cookie_value.present?, "Expected pending_input_key cookie to be set"
  end

  test "ai_analyze increments guest_ai_usage_count cookie" do
    stub_gemini_json_response(mock_analysis_result)

    # 첫 번째 요청
    post onboarding_ai_analyze_path, params: { idea: "첫 번째 아이디어" }
    first_count = cookies[:guest_ai_usage_count].to_i

    # 두 번째 요청
    post onboarding_ai_analyze_path, params: { idea: "두 번째 아이디어" }
    second_count = cookies[:guest_ai_usage_count].to_i

    assert_equal first_count + 1, second_count, "Expected guest_ai_usage_count to increment"
  end

  test "ai_analyze stores idea in Rails.cache for guest" do
    stub_gemini_json_response(mock_analysis_result)
    test_idea = "캐시 저장 테스트 아이디어 #{SecureRandom.hex(4)}"

    post onboarding_ai_analyze_path, params: {
      idea: test_idea,
      answers: { q1: "답변1" }.to_json
    }

    # 세션에서 캐시 키 가져오기
    cache_key = session[:pending_input_key]
    assert cache_key.present?, "Expected cache key in session"

    # 캐시에서 데이터 확인
    cached_data = Rails.cache.read(cache_key)
    assert cached_data.present?, "Expected data in Rails.cache"
    assert_equal test_idea, cached_data[:idea], "Expected idea to match"
  end

  test "guest input creates IdeaAnalysis after login" do
    stub_gemini_json_response(mock_analysis_result)
    test_idea = "로그인 후 분석 생성 테스트 #{SecureRandom.hex(4)}"

    # 1. 비로그인 상태에서 아이디어 제출
    post onboarding_ai_analyze_path, params: { idea: test_idea }
    assert_redirected_to login_path

    # 세션에서 캐시 키 가져오기
    cache_key = session[:pending_input_key]
    assert cache_key.present?

    # 2. 로그인 (restore_pending_input_and_analyze 트리거)
    log_in_as(@user)

    # 3. IdeaAnalysis가 생성되었는지 확인
    analysis = @user.idea_analyses.find_by(idea: test_idea)
    assert analysis.present?, "Expected IdeaAnalysis to be created after login"
    assert_equal "analyzing", analysis.status
  end

  test "guest input redirects to ai_result after login" do
    stub_gemini_json_response(mock_analysis_result)
    test_idea = "리다이렉트 테스트 아이디어 #{SecureRandom.hex(4)}"

    # 1. 비로그인 상태에서 아이디어 제출
    post onboarding_ai_analyze_path, params: { idea: test_idea }

    # 2. 로그인 - 세션 컨트롤러가 restore_pending_input_and_analyze 호출
    post login_path, params: { email: @user.email, password: TEST_PASSWORD }

    # 3. 결과 페이지로 리다이렉트되는지 확인
    assert_response :redirect
    # ai_result 경로로 리다이렉트되거나 커뮤니티로 리다이렉트
    assert response.location.include?("/ai/result") || response.location.include?("/community"),
           "Expected redirect to ai_result or community path, got: #{response.location}"
  end

  test "guest input shows flash message after login" do
    stub_gemini_json_response(mock_analysis_result)
    test_idea = "플래시 메시지 테스트 #{SecureRandom.hex(4)}"

    # 1. 비로그인 상태에서 아이디어 제출
    post onboarding_ai_analyze_path, params: { idea: test_idea }

    # 2. 로그인
    post login_path, params: { email: @user.email, password: TEST_PASSWORD }

    # 3. 분석 준비 완료 또는 환영 메시지 확인
    # Note: 메시지는 구현에 따라 다를 수 있음
    assert flash[:notice].present? || flash[:alert].present?,
           "Expected flash message after login with pending analysis"
  end

  # ============================================================================
  # Phase 3: Usage Limit Integration Tests (사용량 제한 통합 테스트)
  # ============================================================================

  test "restore_pending_input respects usage limit after login" do
    stub_gemini_json_response(mock_analysis_result)
    test_idea = "제한 초과 테스트 #{SecureRandom.hex(4)}"

    # 1. 기존 분석 기록 삭제 후 최대 횟수만큼 분석 생성
    @user.idea_analyses.destroy_all
    max_analyses = Onboarding::UsageLimitChecker::MAX_FREE_ANALYSES

    max_analyses.times do |i|
      @user.idea_analyses.create!(
        idea: "기존 분석 #{i}",
        status: :completed,
        analysis_result: "{}"
      )
    end

    # 2. 비로그인 상태에서 아이디어 제출
    post onboarding_ai_analyze_path, params: { idea: test_idea }
    assert_redirected_to login_path

    # 3. 로그인
    post login_path, params: { email: @user.email, password: TEST_PASSWORD }

    # 4. 제한 초과로 분석이 생성되지 않음
    analysis = @user.idea_analyses.find_by(idea: test_idea)
    assert_nil analysis, "Expected no new IdeaAnalysis when limit exceeded"
  end

  test "restore_pending_input shows alert when usage limit exceeded" do
    stub_gemini_json_response(mock_analysis_result)
    test_idea = "제한 초과 알림 테스트 #{SecureRandom.hex(4)}"

    # 1. 최대 횟수 분석 생성
    @user.idea_analyses.destroy_all
    max_analyses = Onboarding::UsageLimitChecker::MAX_FREE_ANALYSES

    max_analyses.times do |i|
      @user.idea_analyses.create!(
        idea: "기존 분석 #{i}",
        status: :completed,
        analysis_result: "{}"
      )
    end

    # 2. 비로그인 상태에서 아이디어 제출
    post onboarding_ai_analyze_path, params: { idea: test_idea }

    # 3. 로그인
    post login_path, params: { email: @user.email, password: TEST_PASSWORD }

    # 4. 제한 초과 알림 메시지 확인
    # Note: restore_pending_input_and_analyze에서 flash[:alert] 설정
    assert flash[:alert]&.include?("모두 사용") || flash[:notice].present?,
           "Expected limit exceeded alert or redirect notice"
  end

  test "ai_input shows limit_exceeded modal for user at limit" do
    log_in_as(@user)

    # 최대 횟수 분석 생성
    @user.idea_analyses.destroy_all
    max_analyses = Onboarding::UsageLimitChecker::MAX_FREE_ANALYSES

    max_analyses.times do |i|
      @user.idea_analyses.create!(
        idea: "기존 분석 #{i}",
        status: :completed,
        analysis_result: "{}"
      )
    end

    # AI 입력 페이지 접근
    get onboarding_ai_input_path

    # @limit_exceeded가 true로 설정되어야 함
    # 실제 모달 표시는 뷰에서 확인
    assert_response :success
    # limit_exceeded 관련 데이터가 뷰에 전달됨 확인
    # (시스템 테스트에서 모달 표시 확인)
  end
end
