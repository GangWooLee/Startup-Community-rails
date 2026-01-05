# frozen_string_literal: true

require "test_helper"

class Ai::Tools::GeminiGroundingToolTest < ActiveSupport::TestCase
  GEMINI_API_URL_PATTERN = %r{generativelanguage\.googleapis\.com/v1beta/models/.+:generateContent}

  setup do
    # Set environment variable for API key (WebMock will intercept actual calls)
    ENV["GEMINI_API_KEY"] = "test-api-key-for-testing"
    @tool = Ai::Tools::GeminiGroundingTool.new
  end

  teardown do
    ENV.delete("GEMINI_API_KEY")
  end

  # ─────────────────────────────────────────────────
  # Successful Search Tests
  # ─────────────────────────────────────────────────

  test "search_market_data returns formatted response on success" do
    stub_successful_grounding_response("이커머스 시장 규모는 200조원입니다.")

    result = @tool.search_market_data(query: "한국 이커머스 시장")

    assert_kind_of Langchain::ToolResponse, result
    assert_includes result.content, "시장 데이터"
    assert_includes result.content, "이커머스"
  end

  test "search_competitors returns formatted response on success" do
    stub_successful_grounding_response("배달의민족 55%, 쿠팡이츠 30%, 요기요 15%")

    result = @tool.search_competitors(query: "한국 배달앱 시장 점유율")

    assert_kind_of Langchain::ToolResponse, result
    assert_includes result.content, "경쟁사 정보"
  end

  test "search_trends returns formatted response on success" do
    stub_successful_grounding_response("AI 기반 핀테크 서비스가 주목받고 있습니다.")

    result = @tool.search_trends(query: "2024 핀테크 트렌드")

    assert_kind_of Langchain::ToolResponse, result
    assert_includes result.content, "트렌드"
  end

  test "includes sources in response when available" do
    stub_grounding_response_with_sources

    result = @tool.search_market_data(query: "테스트")

    assert_includes result.content, "출처"
  end

  # ─────────────────────────────────────────────────
  # API Error Handling Tests
  # ─────────────────────────────────────────────────

  test "handles API 500 error gracefully" do
    stub_request(:post, GEMINI_API_URL_PATTERN)
      .to_return(status: 500, body: "Internal Server Error")

    result = @tool.search_market_data(query: "테스트")

    assert_includes result.content, "검색 결과를 가져올 수 없습니다"
  end

  test "handles API 429 rate limit error" do
    stub_request(:post, GEMINI_API_URL_PATTERN)
      .to_return(status: 429, body: '{"error": "Rate limit exceeded"}')

    result = @tool.search_market_data(query: "테스트")

    assert_includes result.content, "검색 결과를 가져올 수 없습니다"
  end

  test "handles empty candidates in response" do
    stub_request(:post, GEMINI_API_URL_PATTERN)
      .to_return(
        status: 200,
        body: { candidates: [] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    result = @tool.search_market_data(query: "테스트")

    assert_includes result.content, "검색 결과를 가져올 수 없습니다"
  end

  test "handles network timeout" do
    stub_request(:post, GEMINI_API_URL_PATTERN).to_timeout

    result = @tool.search_market_data(query: "테스트")

    assert_includes result.content, "오류가 발생했습니다"
  end

  # ─────────────────────────────────────────────────
  # Query Enhancement Tests
  # ─────────────────────────────────────────────────

  test "search_market_data enhances query with market keywords" do
    request_body_contains = nil

    stub_request(:post, GEMINI_API_URL_PATTERN)
      .with { |req| request_body_contains = req.body; true }
      .to_return(status: 200, body: success_response_body, headers: json_headers)

    @tool.search_market_data(query: "커피 시장")

    assert_includes request_body_contains, "시장 규모"
  end

  test "search_competitors enhances query with competitor keywords" do
    request_body_contains = nil

    stub_request(:post, GEMINI_API_URL_PATTERN)
      .with { |req| request_body_contains = req.body; true }
      .to_return(status: 200, body: success_response_body, headers: json_headers)

    @tool.search_competitors(query: "배달앱")

    assert_includes request_body_contains, "경쟁사"
  end

  private

  def stub_successful_grounding_response(content)
    stub_request(:post, GEMINI_API_URL_PATTERN)
      .to_return(
        status: 200,
        body: build_grounding_response(content),
        headers: json_headers
      )
  end

  def stub_grounding_response_with_sources
    response = {
      candidates: [ {
        content: {
          parts: [ { text: "테스트 결과입니다." } ]
        },
        groundingMetadata: {
          webSearchQueries: [ "테스트 검색 쿼리" ],
          groundingChunks: [
            { web: { title: "출처1", uri: "https://example.com/1" } },
            { web: { title: "출처2", uri: "https://example.com/2" } }
          ]
        }
      } ]
    }

    stub_request(:post, GEMINI_API_URL_PATTERN)
      .to_return(status: 200, body: response.to_json, headers: json_headers)
  end

  def build_grounding_response(content)
    {
      candidates: [ {
        content: {
          parts: [ { text: content } ]
        },
        groundingMetadata: {
          webSearchQueries: [ "test query" ]
        }
      } ]
    }.to_json
  end

  def success_response_body
    build_grounding_response("테스트 성공")
  end

  def json_headers
    { "Content-Type" => "application/json" }
  end
end
