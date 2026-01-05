# frozen_string_literal: true

require "test_helper"

class Ai::Agents::SummaryAgentTest < ActiveSupport::TestCase
  setup do
    ENV["GEMINI_API_KEY"] = "test-api-key"
    @context = {
      idea: "대학생을 위한 중고 교재 거래 플랫폼",
      follow_up_answers: { target: "대학생", problem: "교재 비용 부담" }
    }
  end

  teardown do
    ENV.delete("GEMINI_API_KEY")
  end

  test "analyze returns summary result on successful API call" do
    stub_gemini_json_response({
      summary: "대학생 중고 교재 거래 플랫폼",
      core_value: "교재 비용 절감",
      problem_statement: "대학생들이 교재 비용으로 인해 경제적 부담을 느낌"
    })

    agent = Ai::Agents::SummaryAgent.new(@context)
    result = agent.analyze

    assert_equal "대학생 중고 교재 거래 플랫폼", result[:summary]
    assert_equal "교재 비용 절감", result[:core_value]
    assert_includes result[:problem_statement], "교재"
  end

  test "analyze returns fallback on API error" do
    stub_gemini_api_error(status: 500)

    agent = Ai::Agents::SummaryAgent.new(@context)
    result = agent.analyze

    assert result[:error] || result[:summary].present?
  end

  test "fallback_result contains required keys" do
    agent = Ai::Agents::SummaryAgent.new(@context)
    fallback = agent.fallback_result

    assert_includes fallback.keys, :summary
    assert_includes fallback.keys, :core_value
    assert_includes fallback.keys, :problem_statement
  end

  test "handles empty follow_up_answers" do
    stub_gemini_json_response({
      summary: "테스트 요약",
      core_value: "테스트 가치",
      problem_statement: "테스트 문제"
    })

    context = { idea: "테스트 아이디어" }
    agent = Ai::Agents::SummaryAgent.new(context)
    result = agent.analyze

    assert result[:summary].present?
  end
end
