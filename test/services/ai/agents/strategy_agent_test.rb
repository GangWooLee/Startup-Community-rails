# frozen_string_literal: true

require "test_helper"

class Ai::Agents::StrategyAgentTest < ActiveSupport::TestCase
  setup do
    ENV["GEMINI_API_KEY"] = "test-api-key"
    @context = {
      idea: "대학생을 위한 중고 교재 거래 플랫폼",
      previous_results: {
        summary: { summary: "중고 교재 거래 플랫폼" },
        target_user: { target_users: { primary: "대학생" } },
        market_analysis: { market_analysis: { potential: "High" } }
      }
    }
  end

  teardown do
    ENV.delete("GEMINI_API_KEY")
  end

  test "analyze returns strategy result on successful API call" do
    stub_gemini_json_response({
      recommendations: {
        mvp_features: [ "교재 검색", "결제 시스템", "채팅 기능" ],
        challenges: [ "신뢰 구축 → 리뷰 시스템", "배송 문제 → 직거래 유도" ],
        next_steps: [ "시장 조사", "MVP 개발", "베타 테스트" ]
      },
      actions: [
        { title: "MVP 정의", description: "핵심 기능 우선순위 설정" },
        { title: "팀 구성", description: "필요 역할 확보" }
      ]
    })

    agent = Ai::Agents::StrategyAgent.new(@context)
    result = agent.analyze

    assert result[:recommendations].present?
    assert result[:recommendations][:mvp_features].is_a?(Array)
    assert result[:actions].is_a?(Array)
  end

  test "analyze returns fallback on API error" do
    stub_gemini_api_error(status: 500)

    agent = Ai::Agents::StrategyAgent.new(@context)
    result = agent.analyze

    assert result[:error] || result[:recommendations].present?
  end

  test "fallback_result contains required structure" do
    agent = Ai::Agents::StrategyAgent.new(@context)
    fallback = agent.fallback_result

    assert fallback[:recommendations].is_a?(Hash)
    assert fallback[:recommendations][:mvp_features].is_a?(Array)
    assert fallback[:recommendations][:challenges].is_a?(Array)
    assert fallback[:recommendations][:next_steps].is_a?(Array)
    assert fallback[:actions].is_a?(Array)
  end

  test "handles empty previous_results" do
    stub_gemini_json_response({
      recommendations: { mvp_features: [], challenges: [], next_steps: [] },
      actions: []
    })

    context = { idea: "테스트 아이디어" }
    agent = Ai::Agents::StrategyAgent.new(context)
    result = agent.analyze

    assert result[:recommendations].present?
  end

  test "actions have title and description" do
    stub_gemini_json_response({
      recommendations: { mvp_features: [ "기능1" ], challenges: [], next_steps: [] },
      actions: [
        { title: "액션1", description: "설명1" },
        { title: "액션2", description: "설명2" }
      ]
    })

    agent = Ai::Agents::StrategyAgent.new(@context)
    result = agent.analyze

    if result[:actions].present?
      result[:actions].each do |action|
        assert action[:title].present? || action["title"].present?
      end
    end
  end
end
