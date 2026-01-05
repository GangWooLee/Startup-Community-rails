# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

class AiAnalysisJobTest < ActiveJob::TestCase
  setup do
    @user = users(:one)
    @analyzing_analysis = idea_analyses(:analyzing_analysis)
    @completed_analysis = idea_analyses(:completed_analysis)
  end

  # ============================================================================
  # Basic Execution Tests
  # ============================================================================

  test "job is queued to default queue" do
    assert_equal "default", AiAnalysisJob.queue_name
  end

  test "can be enqueued" do
    assert_enqueued_with(job: AiAnalysisJob) do
      AiAnalysisJob.perform_later(@analyzing_analysis.id)
    end
  end

  test "can be enqueued with correct arguments" do
    assert_enqueued_with(job: AiAnalysisJob, args: [@analyzing_analysis.id]) do
      AiAnalysisJob.perform_later(@analyzing_analysis.id)
    end
  end

  # ============================================================================
  # Skip Completed Analysis Tests
  # ============================================================================

  test "skips analysis if already completed" do
    # Use completed analysis fixture
    completed = @completed_analysis
    assert completed.completed?

    # The job should return early without making changes
    original_score = completed.score
    original_result = completed.analysis_result

    AiAnalysisJob.perform_now(completed.id)

    completed.reload
    assert_equal original_score, completed.score
    assert_equal original_result, completed.analysis_result
  end

  test "does not broadcast for already completed analysis" do
    completed = @completed_analysis

    # Should not trigger any broadcasts since it returns early
    assert_nothing_raised do
      AiAnalysisJob.perform_now(completed.id)
    end

    # Verify status unchanged
    completed.reload
    assert completed.completed?
  end

  # ============================================================================
  # Mock Analysis Tests (No LLM Configured)
  # ============================================================================

  test "performs mock analysis when LLM not configured" do
    # Stub LangchainConfig to return false for LLM check
    stub_llm_not_configured do
      analysis = create_analyzing_analysis

      AiAnalysisJob.perform_now(analysis.id)

      analysis.reload
      assert analysis.completed?
      assert_not analysis.is_real_analysis
      assert_not analysis.partial_success
      assert analysis.analysis_result.present?
      assert_equal 70, analysis.score  # Mock returns 70
    end
  end

  test "mock analysis contains expected structure" do
    stub_llm_not_configured do
      analysis = create_analyzing_analysis

      AiAnalysisJob.perform_now(analysis.id)

      analysis.reload
      result = analysis.analysis_result.deep_symbolize_keys

      # Verify mock result structure
      assert result[:summary].present?
      assert result[:target_users].present?
      assert result[:market_analysis].present?
      assert result[:recommendations].present?
      assert result[:score].present?
      assert_equal 70, result.dig(:score, :overall)
    end
  end

  test "mock analysis simulates progress stages" do
    stub_llm_not_configured do
      analysis = create_analyzing_analysis

      # We can't easily mock the stage callback, but we can verify
      # the job completes and the analysis is marked complete
      AiAnalysisJob.perform_now(analysis.id)

      analysis.reload
      assert analysis.completed?
    end
  end

  # ============================================================================
  # Real Analysis Tests (LLM Configured - Mocked)
  # ============================================================================

  test "performs real analysis when LLM is configured" do
    # Create mock orchestrator result
    mock_result = build_mock_orchestrator_result

    mock_orchestrator = Minitest::Mock.new
    mock_orchestrator.expect(:analyze, mock_result)

    stub_llm_configured do
      stub_orchestrator(mock_orchestrator) do
        analysis = create_analyzing_analysis

        AiAnalysisJob.perform_now(analysis.id)

        analysis.reload
        assert analysis.completed?
        assert analysis.is_real_analysis
        assert_not analysis.partial_success
        assert_equal 85, analysis.score
      end
    end

    mock_orchestrator.verify
  end

  test "marks partial_success when orchestrator indicates partial success" do
    mock_result = build_mock_orchestrator_result
    mock_result[:metadata] = { partial_success: true, agents_failed: 1 }

    mock_orchestrator = Minitest::Mock.new
    mock_orchestrator.expect(:analyze, mock_result)

    stub_llm_configured do
      stub_orchestrator(mock_orchestrator) do
        analysis = create_analyzing_analysis

        AiAnalysisJob.perform_now(analysis.id)

        analysis.reload
        assert analysis.completed?
        assert analysis.partial_success
      end
    end

    mock_orchestrator.verify
  end

  test "passes follow_up_answers to orchestrator" do
    follow_up_answers = { "question1" => "answer1", "question2" => "answer2" }
    mock_result = build_mock_orchestrator_result

    received_follow_up = nil

    stub_llm_configured do
      # Use a custom orchestrator that captures the follow_up_answers
      original_new = Ai::Orchestrators::AnalysisOrchestrator.method(:new)
      Ai::Orchestrators::AnalysisOrchestrator.define_singleton_method(:new) do |idea, follow_up_answers: {}, on_stage_complete: nil|
        received_follow_up = follow_up_answers
        mock = Object.new
        mock.define_singleton_method(:analyze) { mock_result }
        mock
      end

      begin
        analysis = create_analyzing_analysis(follow_up_answers: follow_up_answers)
        AiAnalysisJob.perform_now(analysis.id)
        assert_equal follow_up_answers.deep_stringify_keys, received_follow_up
      ensure
        Ai::Orchestrators::AnalysisOrchestrator.define_singleton_method(:new, original_new)
      end
    end
  end

  # ============================================================================
  # Error Handling Tests
  # ============================================================================

  test "marks analysis as failed on StandardError" do
    stub_llm_configured do
      # Create orchestrator that raises an error
      original_new = Ai::Orchestrators::AnalysisOrchestrator.method(:new)
      Ai::Orchestrators::AnalysisOrchestrator.define_singleton_method(:new) do |*args, **kwargs|
        mock = Object.new
        mock.define_singleton_method(:analyze) { raise StandardError, "Simulated AI failure" }
        mock
      end

      begin
        # Create analysis with non-empty analysis_result to avoid validation error on status change
        analysis = create_analyzing_analysis(analysis_result: { error: "placeholder" })

        # Should not raise, should handle gracefully
        assert_nothing_raised do
          AiAnalysisJob.perform_now(analysis.id)
        end

        analysis.reload
        assert analysis.failed?
      ensure
        Ai::Orchestrators::AnalysisOrchestrator.define_singleton_method(:new, original_new)
      end
    end
  end

  test "handles RecordNotFound gracefully" do
    non_existent_id = 999999

    # Should raise RecordNotFound (not rescued by the job)
    assert_raises(ActiveRecord::RecordNotFound) do
      AiAnalysisJob.perform_now(non_existent_id)
    end
  end

  test "logs error details on failure" do
    log_output = StringIO.new
    original_logger = Rails.logger
    Rails.logger = Logger.new(log_output)

    begin
      stub_llm_configured do
        original_new = Ai::Orchestrators::AnalysisOrchestrator.method(:new)
        Ai::Orchestrators::AnalysisOrchestrator.define_singleton_method(:new) do |*args, **kwargs|
          mock = Object.new
          mock.define_singleton_method(:analyze) { raise StandardError, "Detailed error message" }
          mock
        end

        begin
          # Create analysis with non-empty analysis_result to avoid validation error on status change
          analysis = create_analyzing_analysis(analysis_result: { error: "placeholder" })
          AiAnalysisJob.perform_now(analysis.id)
        ensure
          Ai::Orchestrators::AnalysisOrchestrator.define_singleton_method(:new, original_new)
        end
      end
    ensure
      Rails.logger = original_logger
    end

    log_content = log_output.string
    assert_match(/\[AiAnalysisJob\].*Failed/, log_content)
    assert_match(/Detailed error message/, log_content)
  end

  # ============================================================================
  # IdeaAnalysis Record Update Tests
  # ============================================================================

  test "updates analysis_result on successful completion" do
    mock_result = build_mock_orchestrator_result

    mock_orchestrator = Minitest::Mock.new
    mock_orchestrator.expect(:analyze, mock_result)

    stub_llm_configured do
      stub_orchestrator(mock_orchestrator) do
        analysis = create_analyzing_analysis

        AiAnalysisJob.perform_now(analysis.id)

        analysis.reload
        result = analysis.analysis_result.deep_symbolize_keys

        assert_equal mock_result[:summary], result[:summary]
        assert_equal mock_result[:score], result[:score]
      end
    end

    mock_orchestrator.verify
  end

  test "updates score from analysis result" do
    mock_result = build_mock_orchestrator_result
    mock_result[:score] = { overall: 92, weak_areas: [], strong_areas: ["innovation"] }

    mock_orchestrator = Minitest::Mock.new
    mock_orchestrator.expect(:analyze, mock_result)

    stub_llm_configured do
      stub_orchestrator(mock_orchestrator) do
        analysis = create_analyzing_analysis

        AiAnalysisJob.perform_now(analysis.id)

        analysis.reload
        assert_equal 92, analysis.score
      end
    end

    mock_orchestrator.verify
  end

  test "updates is_real_analysis flag correctly for real analysis" do
    mock_result = build_mock_orchestrator_result

    mock_orchestrator = Minitest::Mock.new
    mock_orchestrator.expect(:analyze, mock_result)

    stub_llm_configured do
      stub_orchestrator(mock_orchestrator) do
        analysis = create_analyzing_analysis

        AiAnalysisJob.perform_now(analysis.id)

        analysis.reload
        assert analysis.is_real_analysis
      end
    end

    mock_orchestrator.verify
  end

  test "sets is_real_analysis to false for mock analysis" do
    stub_llm_not_configured do
      analysis = create_analyzing_analysis

      AiAnalysisJob.perform_now(analysis.id)

      analysis.reload
      assert_not analysis.is_real_analysis
    end
  end

  test "updates status to completed on success" do
    stub_llm_not_configured do
      analysis = create_analyzing_analysis
      assert analysis.analyzing?

      AiAnalysisJob.perform_now(analysis.id)

      analysis.reload
      assert analysis.completed?
    end
  end

  test "updates status to failed on error" do
    stub_llm_configured do
      original_new = Ai::Orchestrators::AnalysisOrchestrator.method(:new)
      Ai::Orchestrators::AnalysisOrchestrator.define_singleton_method(:new) do |*args, **kwargs|
        mock = Object.new
        mock.define_singleton_method(:analyze) { raise StandardError, "Test error" }
        mock
      end

      begin
        # Create analysis with non-empty analysis_result to avoid validation error on status change
        analysis = create_analyzing_analysis(analysis_result: { error: "placeholder" })
        assert analysis.analyzing?

        AiAnalysisJob.perform_now(analysis.id)

        analysis.reload
        assert analysis.failed?
      ensure
        Ai::Orchestrators::AnalysisOrchestrator.define_singleton_method(:new, original_new)
      end
    end
  end

  # ============================================================================
  # Stage Progress Tests
  # ============================================================================

  test "calls on_stage_complete callback during analysis" do
    mock_result = build_mock_orchestrator_result

    stub_llm_configured do
      original_new = Ai::Orchestrators::AnalysisOrchestrator.method(:new)
      Ai::Orchestrators::AnalysisOrchestrator.define_singleton_method(:new) do |idea, follow_up_answers: {}, on_stage_complete: nil|
        mock = Object.new
        mock.define_singleton_method(:analyze) do
          # Simulate stage progression
          (1..5).each { |stage| on_stage_complete&.call(stage) }
          mock_result
        end
        mock
      end

      begin
        analysis = create_analyzing_analysis

        AiAnalysisJob.perform_now(analysis.id)

        # Verify current_stage was updated (final stage should be saved)
        analysis.reload
        assert_equal 5, analysis.current_stage
      ensure
        Ai::Orchestrators::AnalysisOrchestrator.define_singleton_method(:new, original_new)
      end
    end
  end

  # ============================================================================
  # Logging Tests
  # ============================================================================

  test "logs start of analysis" do
    log_output = StringIO.new
    original_logger = Rails.logger
    Rails.logger = Logger.new(log_output)

    begin
      stub_llm_not_configured do
        analysis = create_analyzing_analysis

        AiAnalysisJob.perform_now(analysis.id)
      end
    ensure
      Rails.logger = original_logger
    end

    log_content = log_output.string
    assert_match(/\[AiAnalysisJob\].*Starting analysis/, log_content)
  end

  test "logs completion of analysis" do
    log_output = StringIO.new
    original_logger = Rails.logger
    Rails.logger = Logger.new(log_output)

    begin
      stub_llm_not_configured do
        analysis = create_analyzing_analysis

        AiAnalysisJob.perform_now(analysis.id)
      end
    ensure
      Rails.logger = original_logger
    end

    log_content = log_output.string
    assert_match(/\[AiAnalysisJob\].*Completed/, log_content)
  end

  test "logs score on completion" do
    log_output = StringIO.new
    original_logger = Rails.logger
    Rails.logger = Logger.new(log_output)

    begin
      stub_llm_not_configured do
        analysis = create_analyzing_analysis

        AiAnalysisJob.perform_now(analysis.id)
      end
    ensure
      Rails.logger = original_logger
    end

    log_content = log_output.string
    assert_match(/score: 70/, log_content)  # Mock score is 70
  end

  test "logs fallback to mock when LLM not configured" do
    log_output = StringIO.new
    original_logger = Rails.logger
    Rails.logger = Logger.new(log_output)

    begin
      stub_llm_not_configured do
        analysis = create_analyzing_analysis

        AiAnalysisJob.perform_now(analysis.id)
      end
    ensure
      Rails.logger = original_logger
    end

    log_content = log_output.string
    assert_match(/Falling back to mock analysis/, log_content)
  end

  test "logs real AI analysis when LLM configured" do
    mock_result = build_mock_orchestrator_result
    mock_orchestrator = Minitest::Mock.new
    mock_orchestrator.expect(:analyze, mock_result)

    log_output = StringIO.new
    original_logger = Rails.logger
    Rails.logger = Logger.new(log_output)

    begin
      stub_llm_configured do
        stub_orchestrator(mock_orchestrator) do
          analysis = create_analyzing_analysis

          AiAnalysisJob.perform_now(analysis.id)
        end
      end
    ensure
      Rails.logger = original_logger
    end

    log_content = log_output.string
    assert_match(/Using real AI analysis/, log_content)

    mock_orchestrator.verify
  end

  # ============================================================================
  # Error Result Tests
  # ============================================================================

  test "handles orchestrator returning error result" do
    error_result = {
      error: true,
      message: "All agents failed",
      score: { overall: nil }
    }

    mock_orchestrator = Minitest::Mock.new
    mock_orchestrator.expect(:analyze, error_result)

    stub_llm_configured do
      stub_orchestrator(mock_orchestrator) do
        analysis = create_analyzing_analysis

        AiAnalysisJob.perform_now(analysis.id)

        analysis.reload
        # When error is present, is_real is false
        assert_not analysis.is_real_analysis
        assert analysis.completed?
      end
    end

    mock_orchestrator.verify
  end

  # ============================================================================
  # Concurrency Tests
  # ============================================================================

  test "multiple jobs for different analyses do not interfere" do
    stub_llm_not_configured do
      analysis1 = create_analyzing_analysis(idea: "First idea")
      analysis2 = create_analyzing_analysis(idea: "Second idea")

      AiAnalysisJob.perform_now(analysis1.id)
      AiAnalysisJob.perform_now(analysis2.id)

      analysis1.reload
      analysis2.reload

      assert analysis1.completed?
      assert analysis2.completed?
      assert_equal "First idea", analysis1.idea
      assert_equal "Second idea", analysis2.idea
    end
  end

  private

  # Helper to create analyzing IdeaAnalysis
  def create_analyzing_analysis(overrides = {})
    IdeaAnalysis.create!({
      user: @user,
      idea: "Test startup idea for analysis",
      status: :analyzing,
      current_stage: 0,
      analysis_result: {},
      is_real_analysis: true,
      partial_success: false
    }.merge(overrides))
  end

  # Helper to build mock orchestrator result
  def build_mock_orchestrator_result
    {
      summary: "This is a great startup idea.",
      core_value: "Innovation in technology",
      problem_statement: "Solving user pain points",
      target_users: {
        primary: "Young entrepreneurs",
        characteristics: ["Tech-savvy", "Ambitious"],
        personas: []
      },
      market_analysis: {
        potential: "High",
        market_size: "$10B",
        trends: "Growing AI adoption"
      },
      recommendations: {
        mvp_features: ["Core feature 1", "Core feature 2"],
        challenges: ["User acquisition"],
        next_steps: ["Launch beta"]
      },
      score: {
        overall: 85,
        weak_areas: ["Marketing"],
        strong_areas: ["Innovation", "Technology"]
      },
      actions: [
        { title: "Define MVP", description: "Focus on core features" }
      ],
      required_expertise: {
        roles: ["Developer", "Designer"],
        skills: ["Ruby", "React"],
        description: "Full-stack team needed"
      },
      analyzed_at: Time.current,
      metadata: {
        agents_total: 5,
        agents_completed: 5,
        agents_failed: 0,
        partial_success: false
      }
    }
  end

  # Stub LangchainConfig to simulate no LLM configured
  def stub_llm_not_configured
    original_method = LangchainConfig.method(:any_llm_configured?)
    LangchainConfig.define_singleton_method(:any_llm_configured?) { false }
    yield
  ensure
    LangchainConfig.define_singleton_method(:any_llm_configured?, original_method)
  end

  # Stub LangchainConfig to simulate LLM configured
  def stub_llm_configured
    original_method = LangchainConfig.method(:any_llm_configured?)
    LangchainConfig.define_singleton_method(:any_llm_configured?) { true }
    yield
  ensure
    LangchainConfig.define_singleton_method(:any_llm_configured?, original_method)
  end

  # Stub the orchestrator with a mock
  def stub_orchestrator(mock_orchestrator)
    original_new = Ai::Orchestrators::AnalysisOrchestrator.method(:new)
    Ai::Orchestrators::AnalysisOrchestrator.define_singleton_method(:new) do |*args, **kwargs|
      mock_orchestrator
    end
    yield
  ensure
    Ai::Orchestrators::AnalysisOrchestrator.define_singleton_method(:new, original_new)
  end
end
