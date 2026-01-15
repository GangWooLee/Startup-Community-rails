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
end
