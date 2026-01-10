# frozen_string_literal: true

module Onboarding
  # AI 분석 실행 및 입력 저장 서비스
  #
  # 로그인 사용자: 백그라운드 잡으로 분석 실행
  # 비로그인 사용자: 입력 데이터만 캐시에 저장 (Lazy Registration)
  #
  # 사용 예:
  #   executor = Onboarding::AnalysisExecutor.new(
  #     user: current_user,
  #     idea: params[:idea],
  #     follow_up_answers: parsed_answers,
  #     session: session
  #   )
  #   result = executor.execute
  class AnalysisExecutor
    attr_reader :user, :idea, :follow_up_answers, :session

    def initialize(user:, idea:, follow_up_answers:, session:)
      @user = user
      @idea = idea
      @follow_up_answers = follow_up_answers || {}
      @session = session
    end

    # 로그인 여부 확인
    def logged_in?
      user.present?
    end

    # 분석 실행 또는 입력 저장
    def execute
      if logged_in?
        execute_analysis
      else
        save_pending_input
      end
    end

    # 로그인 사용자: 비동기 AI 분석 실행
    # placeholder 레코드 생성 후 백그라운드 잡으로 분석 실행
    def execute_analysis
      Rails.logger.info("[Onboarding::AnalysisExecutor] Creating placeholder for user #{user.id}")

      # 1. placeholder 레코드 생성 (status: analyzing)
      idea_analysis = user.idea_analyses.create!(
        idea: idea,
        follow_up_answers: follow_up_answers,
        status: :analyzing,
        analysis_result: {},
        score: nil,
        is_real_analysis: false,
        partial_success: false
      )

      # 2. 백그라운드 잡 실행
      AiAnalysisJob.perform_later(idea_analysis.id)

      Rails.logger.info("[Onboarding::AnalysisExecutor] Enqueued AiAnalysisJob for IdeaAnalysis##{idea_analysis.id}")

      Result.new(success: true, idea_analysis: idea_analysis, pending: false)
    end

    # 비로그인 사용자: 입력 데이터만 캐시에 저장
    def save_pending_input
      cache_key = "pending_input:#{SecureRandom.uuid}"

      Rails.cache.write(cache_key, {
        idea: idea,
        follow_up_answers: follow_up_answers
      }, expires_in: 1.hour)

      session[:pending_input_key] = cache_key

      Rails.logger.info("[Onboarding::AnalysisExecutor] Saved pending input: #{cache_key}")

      Result.new(success: true, cache_key: cache_key, pending: true)
    end

    # 결과 객체
    class Result
      attr_reader :idea_analysis, :cache_key

      def initialize(success:, idea_analysis: nil, cache_key: nil, pending: false)
        @success = success
        @idea_analysis = idea_analysis
        @cache_key = cache_key
        @pending = pending
      end

      def success?
        @success
      end

      def pending?
        @pending
      end
    end
  end
end
