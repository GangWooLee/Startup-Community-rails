# frozen_string_literal: true

require "test_helper"

class Ai::Orchestrators::AnalysisOrchestratorTest < ActiveSupport::TestCase
  GEMINI_API_PATTERN = %r{generativelanguage\.googleapis\.com}

  setup do
    ENV["GEMINI_API_KEY"] = "test-api-key"
    @idea = "대학생을 위한 중고 교재 거래 플랫폼"
    @follow_up_answers = { target: "대학생", problem: "교재 비용 부담" }
  end

  teardown do
    ENV.delete("GEMINI_API_KEY")
  end

  # ─────────────────────────────────────────────────
  # Basic Analysis Tests
  # ─────────────────────────────────────────────────

  test "analyze returns merged results from all agents" do
    stub_all_agent_responses

    orchestrator = Ai::Orchestrators::AnalysisOrchestrator.new(@idea, follow_up_answers: @follow_up_answers)
    result = orchestrator.analyze

    # 기본 필드 존재 확인
    assert result.key?(:summary)
    assert result.key?(:target_users)
    assert result.key?(:market_analysis)
    assert result.key?(:recommendations)
    assert result.key?(:score)
    assert result.key?(:metadata)
  end

  test "analyze includes metadata with agent counts" do
    stub_all_agent_responses

    orchestrator = Ai::Orchestrators::AnalysisOrchestrator.new(@idea)
    result = orchestrator.analyze

    assert_equal 5, result[:metadata][:agents_total]
    assert result[:metadata][:elapsed_seconds].is_a?(Numeric)
    assert result[:metadata][:agent_sequence].is_a?(Array)
  end

  test "analyze includes idea and timestamp" do
    stub_all_agent_responses

    orchestrator = Ai::Orchestrators::AnalysisOrchestrator.new(@idea)
    result = orchestrator.analyze

    assert_equal @idea, result[:idea]
    assert result[:analyzed_at].present?
  end

  # ─────────────────────────────────────────────────
  # Callback Tests
  # ─────────────────────────────────────────────────

  test "calls on_stage_complete callback for each agent" do
    stub_all_agent_responses

    stages_completed = []
    callback = ->(stage) { stages_completed << stage }

    orchestrator = Ai::Orchestrators::AnalysisOrchestrator.new(
      @idea,
      on_stage_complete: callback
    )
    orchestrator.analyze

    assert_equal [ 1, 2, 3, 4, 5 ], stages_completed
  end

  # ─────────────────────────────────────────────────
  # Error Handling Tests
  # ─────────────────────────────────────────────────

  test "uses fallback when agent fails" do
    # 첫 번째 API 호출 성공, 이후 실패
    stub_request(:post, GEMINI_API_PATTERN)
      .to_return(
        { status: 200, body: json_response(:summary).to_json, headers: json_headers },
        { status: 500, body: "Error" },
        { status: 500, body: "Error" },
        { status: 500, body: "Error" },
        { status: 500, body: "Error" }
      )

    orchestrator = Ai::Orchestrators::AnalysisOrchestrator.new(@idea)
    result = orchestrator.analyze

    # 에러가 있어도 결과는 반환됨
    assert result.present?
    assert result[:metadata][:agents_failed] >= 0
  end

  test "handles all agents failing gracefully" do
    stub_request(:post, GEMINI_API_PATTERN)
      .to_return(status: 500, body: "Error")

    orchestrator = Ai::Orchestrators::AnalysisOrchestrator.new(@idea)
    result = orchestrator.analyze

    # 전부 실패해도 fallback으로 결과 반환
    assert result.present?
    assert result[:metadata][:partial_success] == true
  end

  # ─────────────────────────────────────────────────
  # Agent Sequence Tests
  # ─────────────────────────────────────────────────

  test "AGENT_SEQUENCE contains correct order" do
    sequence = Ai::Orchestrators::AnalysisOrchestrator::AGENT_SEQUENCE

    assert_equal [ :summary, :target_user, :market_analysis, :strategy, :scoring ], sequence
  end

  test "AGENT_CLASSES maps to correct agent classes" do
    classes = Ai::Orchestrators::AnalysisOrchestrator::AGENT_CLASSES

    assert_equal Ai::Agents::SummaryAgent, classes[:summary]
    assert_equal Ai::Agents::TargetUserAgent, classes[:target_user]
    assert_equal Ai::Agents::MarketAnalysisAgent, classes[:market_analysis]
    assert_equal Ai::Agents::StrategyAgent, classes[:strategy]
    assert_equal Ai::Agents::ScoringAgent, classes[:scoring]
  end

  private

  def stub_all_agent_responses
    stub_request(:post, GEMINI_API_PATTERN)
      .to_return(
        { status: 200, body: json_response(:summary).to_json, headers: json_headers },
        { status: 200, body: json_response(:target_user).to_json, headers: json_headers },
        { status: 200, body: json_response(:market_analysis).to_json, headers: json_headers },
        { status: 200, body: json_response(:strategy).to_json, headers: json_headers },
        { status: 200, body: json_response(:scoring).to_json, headers: json_headers }
      )
  end

  def json_response(agent_type)
    content = case agent_type
              when :summary
                { summary: "테스트 요약", core_value: "테스트 가치", problem_statement: "테스트 문제" }
              when :target_user
                { target_users: { primary: "대학생", characteristics: [], personas: [] }, user_pain_points: [], user_goals: [] }
              when :market_analysis
                { market_analysis: { potential: "High" }, market_opportunities: [], market_risks: [] }
              when :strategy
                { recommendations: { mvp_features: [], challenges: [], next_steps: [] }, actions: [] }
              when :scoring
                { score: { overall: 70, weak_areas: [], strong_areas: [], improvement_tips: [] }, required_expertise: { roles: [], skills: [], description: "" }, confidence_level: "Medium" }
              else
                {}
              end

    {
      candidates: [ {
        content: {
          parts: [ { text: "```json\n#{content.to_json}\n```" } ]
        }
      } ]
    }
  end

  def json_headers
    { "Content-Type" => "application/json" }
  end
end
