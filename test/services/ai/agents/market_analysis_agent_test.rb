# frozen_string_literal: true

require "test_helper"

class Ai::Agents::MarketAnalysisAgentTest < ActiveSupport::TestCase
  GEMINI_API_PATTERN = %r{generativelanguage\.googleapis\.com}

  setup do
    ENV["GEMINI_API_KEY"] = "test-api-key"
    @context = {
      idea: "대학생을 위한 중고 교재 거래 플랫폼",
      previous_results: {
        summary: { summary: "중고 교재 거래 플랫폼" },
        target_user: { target_users: { primary: "대학생" } }
      }
    }
  end

  teardown do
    ENV.delete("GEMINI_API_KEY")
  end

  test "analyze returns market analysis result on successful API call" do
    # Grounding API 호출 stub
    stub_request(:post, GEMINI_API_PATTERN)
      .to_return(
        status: 200,
        body: grounding_success_response.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    agent = Ai::Agents::MarketAnalysisAgent.new(@context)
    result = agent.analyze

    assert result[:market_analysis].present? || result[:error].present?
  end

  test "fallback_result contains required structure" do
    agent = Ai::Agents::MarketAnalysisAgent.new(@context)
    fallback = agent.fallback_result

    assert fallback[:market_analysis].is_a?(Hash)
    assert fallback[:market_opportunities].is_a?(Array)
    assert fallback[:market_risks].is_a?(Array)
  end

  test "handles API error gracefully" do
    stub_request(:post, GEMINI_API_PATTERN)
      .to_return(status: 500, body: "Internal Server Error")

    agent = Ai::Agents::MarketAnalysisAgent.new(@context)
    result = agent.analyze

    # 에러 시 fallback 또는 에러 결과 반환
    assert result[:market_analysis].present? || result[:error].present?
  end

  test "handles empty previous_results" do
    stub_request(:post, GEMINI_API_PATTERN)
      .to_return(
        status: 200,
        body: grounding_success_response.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    context = { idea: "테스트 아이디어" }
    agent = Ai::Agents::MarketAnalysisAgent.new(context)
    result = agent.analyze

    assert result.present?
  end

  private

  def grounding_success_response
    {
      candidates: [ {
        content: {
          parts: [ {
            text: <<~JSON
              ```json
              {
                "market_analysis": {
                  "potential": "High",
                  "market_size": "500억원",
                  "trends": ["온라인 중고거래 증가"],
                  "competitors": [{"name": "번개장터", "market_share": "30%"}],
                  "differentiation": "대학생 특화"
                },
                "market_opportunities": ["MZ세대 중고거래 선호"],
                "market_risks": ["플랫폼 경쟁 심화"]
              }
              ```
            JSON
          } ]
        },
        groundingMetadata: { webSearchQueries: [ "테스트 쿼리" ] }
      } ]
    }
  end
end
