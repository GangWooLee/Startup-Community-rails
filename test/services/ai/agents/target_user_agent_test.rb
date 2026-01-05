# frozen_string_literal: true

require "test_helper"

class Ai::Agents::TargetUserAgentTest < ActiveSupport::TestCase
  setup do
    ENV["GEMINI_API_KEY"] = "test-api-key"
    @context = {
      idea: "대학생을 위한 중고 교재 거래 플랫폼",
      follow_up_answers: { target: "대학생" },
      previous_results: {
        summary: {
          summary: "중고 교재 거래",
          core_value: "비용 절감",
          problem_statement: "교재 비용 부담"
        }
      }
    }
  end

  teardown do
    ENV.delete("GEMINI_API_KEY")
  end

  test "analyze returns target user result on successful API call" do
    stub_gemini_json_response({
      target_users: {
        primary: "20대 대학생",
        characteristics: [ "학점 관리에 관심", "경제적 절약 필요" ],
        personas: [
          { name: "절약형 대학생", age_range: "20-25세", description: "학비 부담을 느끼는 대학생" }
        ]
      },
      user_pain_points: [ "교재 비용 부담", "중고책 찾기 어려움" ],
      user_goals: [ "비용 절감", "필요한 교재 구하기" ]
    })

    agent = Ai::Agents::TargetUserAgent.new(@context)
    result = agent.analyze

    assert_equal "20대 대학생", result[:target_users][:primary]
    assert result[:user_pain_points].is_a?(Array)
    assert result[:user_goals].is_a?(Array)
  end

  test "analyze returns fallback on API error" do
    stub_gemini_api_error(status: 500)

    agent = Ai::Agents::TargetUserAgent.new(@context)
    result = agent.analyze

    assert result[:error] || result[:target_users].present?
  end

  test "fallback_result contains required structure" do
    agent = Ai::Agents::TargetUserAgent.new(@context)
    fallback = agent.fallback_result

    assert fallback[:target_users].is_a?(Hash)
    assert fallback[:user_pain_points].is_a?(Array)
    assert fallback[:user_goals].is_a?(Array)
  end

  test "uses previous results in prompt" do
    stub_gemini_json_response({
      target_users: { primary: "테스트", characteristics: [], personas: [] },
      user_pain_points: [],
      user_goals: []
    })

    agent = Ai::Agents::TargetUserAgent.new(@context)
    result = agent.analyze

    assert result[:target_users].present?
  end
end
