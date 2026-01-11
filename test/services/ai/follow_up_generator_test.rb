# frozen_string_literal: true

require "test_helper"

class Ai::FollowUpGeneratorTest < ActiveSupport::TestCase
  # Mock LLM class for testing (no API key required)
  class MockLLM
    def chat(messages:)
      OpenStruct.new(chat_completion: "{}", prompt_tokens: 0, completion_tokens: 0, total_tokens: 0)
    end

    def is_a?(klass)
      klass == Langchain::LLM::GoogleGemini
    end
  end

  # Override default_llm to return mock in test environment
  module TestLangchainConfig
    def self.default_llm
      MockLLM.new
    end
  end

  setup do
    @idea = "대학생들이 스터디 그룹을 만들고 관리할 수 있는 앱"

    # Temporarily replace LangchainConfig.default_llm
    @original_method = LangchainConfig.method(:default_llm)
    LangchainConfig.define_singleton_method(:default_llm) { MockLLM.new }

    @generator = Ai::FollowUpGenerator.new(@idea)
  end

  teardown do
    # Restore original method
    if @original_method
      LangchainConfig.define_singleton_method(:default_llm, @original_method)
    end
  end

  # ─────────────────────────────────────────────────
  # 예시 정규화 테스트 (normalize_examples)
  # 이 메서드는 LLM 호출 없이 직접 테스트 가능
  # ─────────────────────────────────────────────────

  test "normalize_examples filters blank values" do
    examples = [ "유효한 예시", "", nil, "또 다른 예시" ]
    result = @generator.send(:normalize_examples, examples)

    assert_equal [ "유효한 예시", "또 다른 예시" ], result
    assert_not_includes result, ""
  end

  test "normalize_examples limits to 3 items" do
    examples = [ "하나", "둘", "셋", "넷", "다섯" ]
    result = @generator.send(:normalize_examples, examples)

    assert_equal 3, result.length
    assert_equal [ "하나", "둘", "셋" ], result
  end

  test "normalize_examples converts to strings" do
    examples = [ 123, :symbol, "문자열" ]
    result = @generator.send(:normalize_examples, examples)

    assert result.all? { |e| e.is_a?(String) }
    assert_includes result, "123"
    assert_includes result, "symbol"
  end

  test "normalize_examples returns empty array for non-array input" do
    assert_equal [], @generator.send(:normalize_examples, nil)
    assert_equal [], @generator.send(:normalize_examples, "string")
    assert_equal [], @generator.send(:normalize_examples, 123)
  end

  # ─────────────────────────────────────────────────
  # Fallback 테스트
  # ─────────────────────────────────────────────────

  test "fallback_questions returns valid structure" do
    result = @generator.send(:fallback_questions)

    assert result[:questions].is_a?(Array)
    assert_equal 3, result[:questions].length

    # 첫 번째 질문 확인
    first = result[:questions].first
    assert_equal "target", first[:id]
    assert first[:required]
    assert first[:examples].is_a?(Array)
    assert first[:examples].length > 0
  end

  test "fallback_questions has required and optional questions" do
    result = @generator.send(:fallback_questions)

    required_count = result[:questions].count { |q| q[:required] == true }
    optional_count = result[:questions].count { |q| q[:required] == false }

    assert_equal 2, required_count, "필수 질문 2개"
    assert_equal 1, optional_count, "선택 질문 1개"
  end

  test "fallback_questions does not include inappropriate examples" do
    result = @generator.send(:fallback_questions)

    bad_examples = [ "직접 입력", "기타", "없음", "해당 없음", "모름", "선택 안함" ]

    result[:questions].each do |question|
      question[:examples].each do |example|
        assert_not_includes bad_examples, example,
          "부적절한 예시가 포함되어 있음: #{example}"
      end
    end
  end

  test "fallback_questions examples are specific and meaningful" do
    result = @generator.send(:fallback_questions)

    # 각 질문의 예시가 구체적인지 확인
    result[:questions].each do |question|
      question[:examples].each do |example|
        assert example.length >= 2, "예시가 너무 짧음: #{example}"
        assert example.length <= 20, "예시가 너무 김: #{example}"
      end
    end
  end

  # ─────────────────────────────────────────────────
  # validate_and_normalize 테스트
  # ─────────────────────────────────────────────────

  test "validate_and_normalize handles raw_response error" do
    # raw_response가 있으면 fallback 반환
    result = @generator.send(:validate_and_normalize, { raw_response: "invalid json" })

    assert result[:questions].is_a?(Array)
    assert result[:questions].length >= 2
  end

  test "validate_and_normalize handles error key" do
    # error가 있으면 fallback 반환
    result = @generator.send(:validate_and_normalize, { error: true })

    assert result[:questions].is_a?(Array)
    assert result[:questions].length >= 2
  end

  test "validate_and_normalize handles empty questions array" do
    result = @generator.send(:validate_and_normalize, { questions: [] })

    # 빈 배열이면 fallback 반환
    assert result[:questions].is_a?(Array)
    assert result[:questions].length >= 2
  end

  test "validate_and_normalize handles missing questions key" do
    result = @generator.send(:validate_and_normalize, {})

    # questions 키가 없으면 fallback 반환
    assert result[:questions].is_a?(Array)
    assert result[:questions].length >= 2
  end

  test "validate_and_normalize generates id if missing" do
    input = {
      questions: [
        { question: "질문 1", examples: [ "예시" ], required: true }
      ]
    }

    result = @generator.send(:validate_and_normalize, input)

    # id가 없으면 자동 생성됨
    assert_equal "question_1", result[:questions].first[:id]
  end

  test "validate_and_normalize limits to 3 questions" do
    input = {
      questions: [
        { id: "q1", question: "질문 1", examples: [], required: true },
        { id: "q2", question: "질문 2", examples: [], required: true },
        { id: "q3", question: "질문 3", examples: [], required: false },
        { id: "q4", question: "질문 4", examples: [], required: false },
        { id: "q5", question: "질문 5", examples: [], required: false }
      ]
    }

    result = @generator.send(:validate_and_normalize, input)

    assert_equal 3, result[:questions].length
  end

  test "validate_and_normalize defaults required to true" do
    input = {
      questions: [
        { id: "q1", question: "질문", examples: [] }
        # required 없음
      ]
    }

    result = @generator.send(:validate_and_normalize, input)

    assert result[:questions].first[:required] == true
  end

  test "validate_and_normalize normalizes examples" do
    input = {
      questions: [
        { id: "q1", question: "질문", examples: [ "하나", "", "둘", nil, "셋", "넷" ], required: true }
      ]
    }

    result = @generator.send(:validate_and_normalize, input)

    # 빈 값 제거, 3개로 제한
    examples = result[:questions].first[:examples]
    assert_equal [ "하나", "둘", "셋" ], examples
  end

  test "validate_and_normalize provides default placeholder" do
    input = {
      questions: [
        { id: "q1", question: "질문", examples: [], required: true }
        # placeholder 없음
      ]
    }

    result = @generator.send(:validate_and_normalize, input)

    assert_equal "", result[:questions].first[:placeholder]
  end

  # ─────────────────────────────────────────────────
  # SYSTEM_PROMPT 검증 테스트
  # ─────────────────────────────────────────────────

  test "SYSTEM_PROMPT includes bad example prohibition" do
    prompt = Ai::FollowUpGenerator::SYSTEM_PROMPT

    assert_includes prompt, "직접 입력"
    assert_includes prompt, "기타"
    assert_includes prompt, "없음"
    assert_includes prompt, "절대 금지"
  end

  test "SYSTEM_PROMPT specifies JSON output format" do
    prompt = Ai::FollowUpGenerator::SYSTEM_PROMPT

    assert_includes prompt, "questions"
    assert_includes prompt, "JSON"
    assert_includes prompt, "examples"
  end

  test "SYSTEM_PROMPT mentions required and optional questions" do
    prompt = Ai::FollowUpGenerator::SYSTEM_PROMPT

    assert_includes prompt, "required"
    assert_includes prompt, "true"
    assert_includes prompt, "false"
  end

  # ─────────────────────────────────────────────────
  # 초기화 테스트
  # ─────────────────────────────────────────────────

  test "initializes with idea" do
    assert_equal @idea, @generator.instance_variable_get(:@idea)
  end

  # ─────────────────────────────────────────────────
  # build_chat_messages 테스트
  # ─────────────────────────────────────────────────

  test "build_chat_messages includes idea in user message" do
    messages = @generator.send(:build_chat_messages)

    assert_equal 1, messages.length
    assert_equal "user", messages.first[:role]
    assert_includes messages.first[:content], @idea
    assert_includes messages.first[:content], "아이디어"
  end
end
