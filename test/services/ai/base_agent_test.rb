# frozen_string_literal: true

require "test_helper"

# Mock Langchain module/classes for testing (if not loaded)
module Langchain
  module LLM
    class ApiError < StandardError; end unless defined?(Langchain::LLM::ApiError)
  end
end

class Ai::BaseAgentTest < ActiveSupport::TestCase
  # Mock LLM for testing
  class MockLLM
    def chat(messages:, **options)
      OpenStruct.new(
        completion: "Mock response",
        prompt_tokens: 100,
        completion_tokens: 50,
        total_tokens: 150
      )
    end
  end

  # Concrete implementation for testing abstract BaseAgent
  class TestAgent < Ai::BaseAgent
    def execute(input:)
      with_error_handling do
        { result: "processed: #{input}" }
      end
    end

    def parse_test(json_text)
      parse_json_response(json_text)
    end

    def format_test(messages, system_prompt: nil)
      format_messages_for_gemini(messages, system_prompt: system_prompt)
    end
  end

  setup do
    @mock_llm = MockLLM.new
    @agent = TestAgent.new(llm: @mock_llm)
  end

  # ─────────────────────────────────────────────────
  # Initialization Tests
  # ─────────────────────────────────────────────────

  test "initializes with provided llm" do
    agent = TestAgent.new(llm: @mock_llm)
    assert_equal @mock_llm, agent.llm
  end

  test "initializes with empty tools by default" do
    agent = TestAgent.new(llm: @mock_llm)
    assert_equal [], agent.tools
  end

  test "initializes with provided tools" do
    tools = [ :tool1, :tool2 ]
    agent = TestAgent.new(llm: @mock_llm, tools: tools)
    assert_equal tools, agent.tools
  end

  # ─────────────────────────────────────────────────
  # Error Handling Tests
  # ─────────────────────────────────────────────────

  test "with_error_handling returns result on success" do
    result = @agent.execute(input: "test")
    assert_equal({ result: "processed: test" }, result)
  end

  test "with_error_handling handles Langchain::LLM::ApiError" do
    # Create agent that raises API error
    error_agent = Class.new(Ai::BaseAgent) do
      def execute
        with_error_handling do
          raise Langchain::LLM::ApiError.new("API rate limit exceeded")
        end
      end
    end.new(llm: @mock_llm)

    result = error_agent.execute
    assert result[:error]
    assert_includes result[:message], "AI 서비스 오류"
  end

  test "with_error_handling handles StandardError" do
    error_agent = Class.new(Ai::BaseAgent) do
      def execute
        with_error_handling do
          raise StandardError.new("Unexpected error")
        end
      end
    end.new(llm: @mock_llm)

    result = error_agent.execute
    assert result[:error]
    assert_includes result[:message], "예기치 않은 오류"
  end

  # ─────────────────────────────────────────────────
  # JSON Parsing Tests
  # ─────────────────────────────────────────────────

  test "parse_json_response parses valid JSON" do
    json_text = '{"key": "value", "number": 42}'
    result = @agent.parse_test(json_text)
    assert_equal({ key: "value", number: 42 }, result)
  end

  test "parse_json_response extracts JSON from code block" do
    json_text = <<~TEXT
      Here is the analysis:
      ```json
      {"summary": "Test summary", "score": 85}
      ```
      Additional notes here.
    TEXT

    result = @agent.parse_test(json_text)
    assert_equal({ summary: "Test summary", score: 85 }, result)
  end

  test "parse_json_response returns raw_response on invalid JSON" do
    invalid_json = "This is not valid JSON at all"
    result = @agent.parse_test(invalid_json)
    assert_equal({ raw_response: invalid_json }, result)
  end

  test "parse_json_response handles nested JSON" do
    json_text = '{"data": {"nested": {"deep": true}}, "array": [1, 2, 3]}'
    result = @agent.parse_test(json_text)
    assert_equal({ data: { nested: { deep: true } }, array: [ 1, 2, 3 ] }, result)
  end

  # ─────────────────────────────────────────────────
  # Gemini Message Formatting Tests
  # ─────────────────────────────────────────────────

  test "format_messages_for_gemini converts OpenAI format" do
    messages = [
      { role: "user", content: "Hello" },
      { role: "assistant", content: "Hi there" }
    ]

    result = @agent.format_test(messages)

    assert_equal 2, result.length
    assert_equal "user", result[0][:role]
    assert_equal [ { text: "Hello" } ], result[0][:parts]
    assert_equal "assistant", result[1][:role]
    assert_equal [ { text: "Hi there" } ], result[1][:parts]
  end

  test "format_messages_for_gemini converts system to user" do
    messages = [ { role: "system", content: "You are a helpful assistant" } ]
    result = @agent.format_test(messages)

    assert_equal "user", result[0][:role]
    assert_equal [ { text: "You are a helpful assistant" } ], result[0][:parts]
  end

  test "format_messages_for_gemini handles string keys" do
    messages = [ { "role" => "user", "content" => "String key test" } ]
    result = @agent.format_test(messages)

    assert_equal "user", result[0][:role]
    assert_equal [ { text: "String key test" } ], result[0][:parts]
  end

  test "format_messages_for_gemini adds system_prompt with model response" do
    messages = [ { role: "user", content: "Question" } ]
    result = @agent.format_test(messages, system_prompt: "Be helpful")

    assert_equal 3, result.length
    assert_equal "user", result[0][:role]
    assert_equal [ { text: "Be helpful" } ], result[0][:parts]
    assert_equal "model", result[1][:role]
    assert_equal "user", result[2][:role]
  end

  # ─────────────────────────────────────────────────
  # LLM Detection Tests
  # ─────────────────────────────────────────────────

  test "using_gemini? returns false for non-Gemini LLM" do
    agent = TestAgent.new(llm: @mock_llm)
    assert_not agent.send(:using_gemini?)
  end
end
