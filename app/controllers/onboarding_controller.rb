# frozen_string_literal: true

# 온보딩 컨트롤러
#
# AI 아이디어 분석 기능 및 온보딩 플로우 관리
# 비로그인 사용자는 입력만 저장 (Lazy Registration)
# 로그인 사용자는 백그라운드 잡으로 분석 실행
class OnboardingController < ApplicationController
  before_action :require_login, only: [ :ai_result, :save_analysis ]
  before_action :hide_floating_button, only: [ :landing, :ai_input, :ai_result ]
  before_action :check_usage_limit, only: [ :ai_analyze ]

  # ==========================================================================
  # Public Actions
  # ==========================================================================

  # GET /onboarding (랜딩 페이지)
  def landing
    set_usage_stats
  end

  # GET /ai/input (AI 입력 화면)
  def ai_input
    @back_path = logged_in? ? community_path : root_path
    @user = current_user
    set_usage_stats

    # 사용량 초과 여부를 뷰로 전달 (모달 표시용)
    # 로그인 사용자만 제한 확인 (비로그인은 ai_analyze에서 로그인 유도)
    @limit_exceeded = logged_in? && usage_checker.exceeded?
  end

  # POST /ai/questions (추가 질문 생성)
  def ai_questions
    idea = params[:idea]

    if idea.blank?
      render json: { error: "아이디어를 입력해주세요" }, status: :unprocessable_entity
      return
    end

    result = if LangchainConfig.any_llm_configured?
               Ai::FollowUpGenerator.new(idea).generate
    else
               Onboarding::MockData.default_follow_up_questions
    end

    render json: result
  end

  # POST /ai/analyze (AI 분석 요청)
  def ai_analyze
    @idea = params[:idea]
    @follow_up_answers = parse_follow_up_answers

    if @idea.blank?
      redirect_to onboarding_ai_input_path, alert: "아이디어를 입력해주세요"
      return
    end

    executor = Onboarding::AnalysisExecutor.new(
      user: current_user,
      idea: @idea,
      follow_up_answers: @follow_up_answers,
      session: session
    )

    result = executor.execute

    if result.pending?
      # 비로그인: 쿠키 횟수 증가 후 로그인 유도
      usage_checker.increment_guest_count!

      # 쿠키 백업 저장 (OAuth 외부 리다이렉션 시 세션 손실 대비)
      cookies.signed[:pending_input_key] = {
        value: result.cache_key,
        expires: 1.hour.from_now,
        httponly: true,
        same_site: :lax
      }

      redirect_to login_path, notice: "분석 준비가 완료되었습니다! 로그인하면 바로 결과를 확인할 수 있어요."
    else
      # 로그인: GA4 이벤트 후 결과 페이지로 리다이렉트
      track_ga4_event("ai_analysis_start", { idea_length: @idea.length })
      redirect_to ai_result_path(result.idea_analysis)
    end
  end

  # GET /ai/result/:id (분석 결과 조회)
  def ai_result
    @idea_analysis = current_user.idea_analyses.find(params[:id])
    @idea = @idea_analysis.idea
    @analysis = @idea_analysis.parsed_result
    @is_real_analysis = @idea_analysis.is_real_analysis
    @partial_analysis = @idea_analysis.partial_success

    track_ga4_event("ai_analysis_complete", {
      analysis_id: @idea_analysis.id,
      is_real: @is_real_analysis,
      score: @analysis.dig(:score, :overall)
    })

    @recommended_experts = find_recommended_experts_with_predictions

    # 온보딩 완료 표시
    cookies[:onboarding_completed] = { value: "true", expires: 1.year.from_now }
  rescue ActiveRecord::RecordNotFound
    redirect_to onboarding_ai_input_path, alert: "분석 결과를 찾을 수 없습니다"
  end

  # POST /ai/result/:id/save (분석 결과 저장)
  def save_analysis
    @idea_analysis = current_user.idea_analyses.find(params[:id])
    @idea_analysis.save_to_collection!

    track_ga4_event("ai_analysis_saved", {
      analysis_id: @idea_analysis.id,
      score: @idea_analysis.score
    })

    respond_to do |format|
      format.html { redirect_to ai_result_path(@idea_analysis), notice: "분석 결과가 저장되었습니다." }
      format.json { render json: { saved: true, message: "저장되었습니다" } }
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { redirect_to onboarding_ai_input_path, alert: "분석 결과를 찾을 수 없습니다" }
      format.json { render json: { error: "Not found" }, status: :not_found }
    end
  end

  # GET /ai/expert/:id (전문가 프로필 오버레이)
  def expert_profile
    @user = User.find(params[:id])
    @prediction = build_prediction_from_params

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          "profile-overlay-container",
          partial: "onboarding/expert_profile_overlay",
          locals: { user: @user, prediction: @prediction }
        )
      end
    end
  end

  private

  # ==========================================================================
  # Usage Limit
  # ==========================================================================

  def usage_checker
    @usage_checker ||= Onboarding::UsageLimitChecker.new(
      user: current_user,
      cookies: cookies
    )
  end

  def check_usage_limit
    # 비로그인 사용자는 스킵 - 로그인 후 restore_pending_input_and_analyze에서 DB 기반 체크
    return unless logged_in?
    return unless usage_checker.exceeded?

    limit = usage_checker.effective_limit

    respond_to do |format|
      format.html do
        # ai_input으로 리다이렉트하여 모달 표시
        redirect_to onboarding_ai_input_path
      end
      format.json do
        render json: {
          error: "limit_exceeded",
          message: "무료 분석 #{limit}회가 모두 사용되었습니다.",
          remaining: 0
        }, status: :forbidden
      end
    end
  end

  def set_usage_stats
    stats = usage_checker.stats
    @remaining_analyses = stats[:remaining]
    @effective_limit = stats[:effective_limit]
    @has_bonus = stats[:has_bonus]
  end

  # ==========================================================================
  # Helpers
  # ==========================================================================

  def parse_follow_up_answers
    answers = params[:answers]
    return {} if answers.blank?

    if answers.is_a?(String)
      begin
        JSON.parse(answers, symbolize_names: true)
      rescue JSON::ParserError
        {}
      end
    else
      answers.to_unsafe_h.symbolize_keys
    end
  end

  def build_prediction_from_params
    {
      score_boost: params[:score_boost]&.to_i || 10,
      boost_area: params[:boost_area] || "전문성",
      why: params[:why].presence || "#{params[:boost_area] || '전문성'} 보완에 적합"
    }
  end

  def find_recommended_experts_with_predictions
    required_expertise = @analysis[:required_expertise] || Onboarding::MockData.required_expertise

    experts = ExpertMatcher.new(
      required_expertise,
      exclude_user_id: current_user&.id
    ).find_matches

    predictor = Ai::ExpertScorePredictor.new(@analysis)
    predictor.predict_all(experts)
  end

  # ==========================================================================
  # Helper Methods (for views)
  # ==========================================================================

  def has_bonus?
    usage_checker.has_bonus?
  end
  helper_method :has_bonus?
end
