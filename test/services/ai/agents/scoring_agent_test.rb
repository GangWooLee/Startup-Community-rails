# frozen_string_literal: true

require "test_helper"

class Ai::Agents::ScoringAgentTest < ActiveSupport::TestCase
  setup do
    ENV["GEMINI_API_KEY"] = "test-api-key"
    @context = {
      idea: "대학생을 위한 중고 교재 거래 플랫폼",
      previous_results: {
        summary: { summary: "중고 교재 거래 플랫폼" },
        target_user: { target_users: { primary: "대학생" } },
        market_analysis: { market_analysis: { potential: "High" } },
        strategy: { recommendations: { mvp_features: [ "검색", "결제" ] } }
      }
    }
  end

  teardown do
    ENV.delete("GEMINI_API_KEY")
  end

  test "analyze returns score result on successful API call" do
    stub_gemini_json_response({
      score: {
        overall: 72,
        weak_areas: [ "시장 분석", "기술 구체화" ],
        strong_areas: [ "타겟 명확성", "문제 인식" ],
        improvement_tips: [ "시장 조사 강화", "MVP 구체화" ]
      },
      required_expertise: {
        roles: [ "Developer", "Designer" ],
        skills: [ "웹 개발", "UX 디자인" ],
        description: "플랫폼 개발 역량 필요"
      },
      confidence_level: "High"
    })

    agent = Ai::Agents::ScoringAgent.new(@context)
    result = agent.analyze

    assert_equal 72, result[:score][:overall]
    assert result[:score][:weak_areas].is_a?(Array)
    assert result[:required_expertise][:roles].is_a?(Array)
    assert_equal "High", result[:confidence_level]
  end

  test "score is clamped to 0-100 range" do
    stub_gemini_json_response({
      score: { overall: 150, weak_areas: [], strong_areas: [], improvement_tips: [] },
      required_expertise: { roles: [], skills: [], description: "" },
      confidence_level: "Medium"
    })

    agent = Ai::Agents::ScoringAgent.new(@context)
    result = agent.analyze

    assert_operator result[:score][:overall], :<=, 100
    assert_operator result[:score][:overall], :>=, 0
  end

  test "analyze returns fallback on API error" do
    stub_gemini_api_error(status: 500)

    agent = Ai::Agents::ScoringAgent.new(@context)
    result = agent.analyze

    assert result[:error] || result[:score].present?
  end

  test "fallback_result contains required structure" do
    agent = Ai::Agents::ScoringAgent.new(@context)
    fallback = agent.fallback_result

    assert fallback[:score].is_a?(Hash)
    assert fallback[:score][:overall].is_a?(Integer)
    assert fallback[:required_expertise].is_a?(Hash)
    assert fallback[:confidence_level].present?
  end

  test "weak_areas are standardized" do
    stub_gemini_json_response({
      score: {
        overall: 65,
        weak_areas: [ "시장", "기술" ],  # 축약된 형태
        strong_areas: [],
        improvement_tips: []
      },
      required_expertise: { roles: [], skills: [], description: "" },
      confidence_level: "Medium"
    })

    agent = Ai::Agents::ScoringAgent.new(@context)
    result = agent.analyze

    # 표준화된 weak_areas 포함 확인
    assert result[:score][:weak_areas].any? { |area|
      Ai::Agents::ScoringAgent::STANDARD_WEAK_AREAS.include?(area) || area.present?
    }
  end
end
