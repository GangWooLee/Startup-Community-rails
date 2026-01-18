# frozen_string_literal: true

require "test_helper"

module Onboarding
  class AnalysisExecutorTest < ActiveSupport::TestCase
    include ActiveJob::TestHelper

    setup do
      @user = users(:one)
      @idea = "AI 기반 창업 아이디어 분석 플랫폼"
      @follow_up_answers = { "q1" => "answer1", "q2" => "answer2" }
      @mock_session = {}
    end

    # =========================================================================
    # logged_in? Tests
    # =========================================================================

    test "logged_in? returns true when user present" do
      executor = AnalysisExecutor.new(
        user: @user,
        idea: @idea,
        follow_up_answers: @follow_up_answers,
        session: @mock_session
      )

      assert executor.logged_in?
    end

    test "logged_in? returns false when user nil" do
      executor = AnalysisExecutor.new(
        user: nil,
        idea: @idea,
        follow_up_answers: @follow_up_answers,
        session: @mock_session
      )

      assert_not executor.logged_in?
    end

    # =========================================================================
    # execute Tests
    # =========================================================================

    test "execute returns pending result for guest" do
      executor = AnalysisExecutor.new(
        user: nil,
        idea: @idea,
        follow_up_answers: @follow_up_answers,
        session: @mock_session
      )

      result = executor.execute

      assert result.success?
      assert result.pending?
      assert_nil result.idea_analysis
      assert result.cache_key.present?
      assert result.cache_key.start_with?("pending_input:")
    end

    test "execute returns idea_analysis for logged-in user" do
      executor = AnalysisExecutor.new(
        user: @user,
        idea: @idea,
        follow_up_answers: @follow_up_answers,
        session: @mock_session
      )

      result = nil
      assert_enqueued_with(job: AiAnalysisJob) do
        result = executor.execute
      end

      assert result.success?
      assert_not result.pending?
      assert result.idea_analysis.present?
      assert_nil result.cache_key
    end

    # =========================================================================
    # save_pending_input Tests
    # =========================================================================

    test "save_pending_input stores in Rails.cache" do
      executor = AnalysisExecutor.new(
        user: nil,
        idea: @idea,
        follow_up_answers: @follow_up_answers,
        session: @mock_session
      )

      result = executor.save_pending_input

      # 캐시에서 데이터 확인
      cached_data = Rails.cache.read(result.cache_key)
      assert cached_data.present?
      assert_equal @idea, cached_data[:idea]
      assert_equal @follow_up_answers, cached_data[:follow_up_answers]
    end

    test "save_pending_input stores key in session" do
      executor = AnalysisExecutor.new(
        user: nil,
        idea: @idea,
        follow_up_answers: @follow_up_answers,
        session: @mock_session
      )

      result = executor.save_pending_input

      assert_equal result.cache_key, @mock_session[:pending_input_key]
    end

    # =========================================================================
    # execute_analysis Tests
    # =========================================================================

    test "execute_analysis creates analyzing IdeaAnalysis" do
      executor = AnalysisExecutor.new(
        user: @user,
        idea: @idea,
        follow_up_answers: @follow_up_answers,
        session: @mock_session
      )

      result = nil
      assert_difference "@user.idea_analyses.count", 1 do
        # Job is enqueued but not executed in this test
        result = executor.execute_analysis
      end

      assert result.success?
      analysis = result.idea_analysis
      assert analysis.present?
      assert_equal @idea, analysis.idea
      assert_equal @follow_up_answers.stringify_keys, analysis.follow_up_answers
      assert_equal "analyzing", analysis.status
    end

    test "execute_analysis enqueues AiAnalysisJob" do
      executor = AnalysisExecutor.new(
        user: @user,
        idea: @idea,
        follow_up_answers: @follow_up_answers,
        session: @mock_session
      )

      assert_enqueued_with(job: AiAnalysisJob) do
        executor.execute_analysis
      end
    end

    # =========================================================================
    # Result Object Tests
    # =========================================================================

    test "Result.pending? true for pending" do
      result = AnalysisExecutor::Result.new(
        success: true,
        cache_key: "pending_input:abc123",
        pending: true
      )

      assert result.pending?
      assert result.success?
      assert_nil result.idea_analysis
    end

    test "Result.pending? false for completed" do
      analysis = @user.idea_analyses.create!(
        idea: @idea,
        status: :analyzing,
        analysis_result: {}
      )

      result = AnalysisExecutor::Result.new(
        success: true,
        idea_analysis: analysis,
        pending: false
      )

      assert_not result.pending?
      assert result.success?
      assert_equal analysis, result.idea_analysis
    end
  end
end
