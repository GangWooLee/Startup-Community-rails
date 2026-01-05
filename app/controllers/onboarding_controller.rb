class OnboardingController < ApplicationController
  # AI 분석 결과 페이지만 로그인 필수 (분석은 비로그인으로 가능)
  before_action :require_login, only: [:ai_result]
  before_action :hide_floating_button, only: [:ai_input, :ai_result]
  before_action :check_usage_limit, only: [:ai_analyze]

  # 무료 체험 최대 사용 횟수
  MAX_FREE_ANALYSES = 5

  def landing
    # 온보딩 랜딩은 누구나 접근 가능
    # 로그인한 사용자도 AI 분석 기능 사용 가능
    set_usage_stats
  end

  def ai_input
    # AI 아이디어 입력 화면
    # 뒤로가기 경로 설정: 로그인한 사용자는 커뮤니티로, 비로그인은 온보딩으로
    @back_path = logged_in? ? community_path : root_path
    @user = current_user
    set_usage_stats
  end

  # AI 추가 질문 생성 (POST /ai/questions)
  # 초기 아이디어 입력 후 맥락에 맞는 추가 질문 2-3개 생성
  def ai_questions
    idea = params[:idea]

    if idea.blank?
      render json: { error: "아이디어를 입력해주세요" }, status: :unprocessable_entity
      return
    end

    # AI로 추가 질문 생성 (LLM 설정이 있는 경우)
    if LangchainConfig.any_llm_configured?
      result = Ai::FollowUpGenerator.new(idea).generate
    else
      # LLM 미설정 시 기본 질문 사용
      result = default_follow_up_questions
    end

    render json: result
  end

  # AI 분석 요청 처리 (POST /ai/analyze)
  # - 로그인 사용자: 바로 AI 분석 실행 → 결과 페이지
  # - 비로그인 사용자: 입력만 저장 (API 비용 0) → 로그인 유도 → 로그인 후 분석 실행
  def ai_analyze
    @idea = params[:idea]
    @follow_up_answers = parse_follow_up_answers

    # 아이디어가 없으면 입력 화면으로 리디렉션
    if @idea.blank?
      redirect_to onboarding_ai_input_path, alert: "아이디어를 입력해주세요"
      return
    end

    if logged_in?
      # 로그인 사용자: 바로 AI 분석 실행
      execute_and_save_analysis
    else
      # 비로그인 사용자: 입력 데이터만 저장 (AI 미실행 - API 비용 절감)
      save_pending_input
      # 비로그인 사용자: 쿠키 횟수 증가
      increment_guest_usage_count
      # 로그인 페이지로 리다이렉트 (AI 분석은 로그인 후 실행)
      redirect_to login_path, notice: "분석 준비가 완료되었습니다! 로그인하면 바로 결과를 확인할 수 있어요."
    end
  end

  # 분석 결과 조회 (GET /ai/result/:id)
  # DB에서 저장된 결과를 로드 (재분석 없음)
  def ai_result
    # DB에서 분석 결과 로드
    @idea_analysis = current_user.idea_analyses.find(params[:id])
    @idea = @idea_analysis.idea
    @analysis = @idea_analysis.parsed_result
    @is_real_analysis = @idea_analysis.is_real_analysis
    @partial_analysis = @idea_analysis.partial_success

    # 추천 전문가 찾기 + 점수 향상 예측
    @recommended_experts = find_recommended_experts_with_predictions

    # 온보딩 경험 완료 표시 (다음 방문 시 커뮤니티 직접 접근 허용)
    cookies[:onboarding_completed] = {
      value: "true",
      expires: 1.year.from_now
    }
  rescue ActiveRecord::RecordNotFound
    redirect_to onboarding_ai_input_path, alert: "분석 결과를 찾을 수 없습니다"
  end

  # 전문가 프로필 오버레이 (Turbo Stream)
  def expert_profile
    @user = User.find(params[:id])

    # Prediction 데이터 (expert_card에서 전달됨)
    @prediction = {
      score_boost: params[:score_boost]&.to_i || 10,
      boost_area: params[:boost_area] || "전문성",
      why: params[:why].presence || "#{params[:boost_area] || '전문성'} 보완에 적합"
    }

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

  # 사용 횟수 제한 확인 (사용자별 limit + 보너스 적용)
  def check_usage_limit
    limit = effective_limit
    remaining = remaining_analyses

    if remaining <= 0
      respond_to do |format|
        format.html do
          flash[:alert] = "무료 분석 #{limit}회가 끝났습니다."
          redirect_to community_path
        end
        format.json do
          render json: {
            error: "limit_exceeded",
            message: "무료 분석 #{limit}회가 끝났습니다.",
            remaining: 0
          }, status: :forbidden
        end
      end
    elsif remaining == 1
      # 마지막 1회 남았을 때 경고 (분석 진행은 허용)
      flash.now[:notice] = "마지막 무료 분석입니다."
    end
  end

  # 현재 사용 횟수 조회 (비로그인 쿠키 + 로그인 DB 합산)
  def current_usage_count
    guest_count = cookies[:guest_ai_usage_count].to_i

    if logged_in?
      # 로그인 사용자: DB 분석 횟수 + 비로그인 시 사용 횟수
      current_user.idea_analyses.count + guest_count
    else
      # 비로그인 사용자: 쿠키 횟수만
      guest_count
    end
  end

  # 비로그인 사용자 쿠키 횟수 증가
  def increment_guest_usage_count
    current_count = cookies[:guest_ai_usage_count].to_i
    cookies.permanent[:guest_ai_usage_count] = (current_count + 1).to_s
  end

  # 사용자별 유효 limit 반환 (로그인: 사용자 설정, 비로그인: 기본값)
  def effective_limit
    if logged_in?
      current_user.effective_ai_limit
    else
      MAX_FREE_ANALYSES
    end
  end

  # 잔여 분석 횟수 반환 (로그인: 보너스 포함, 비로그인: 쿠키 기반)
  def remaining_analyses
    if logged_in?
      # 로그인 사용자: User 모델의 보너스 포함 계산 사용
      current_user.ai_analyses_remaining
    else
      # 비로그인 사용자: 기본 limit - 쿠키 사용량
      MAX_FREE_ANALYSES - cookies[:guest_ai_usage_count].to_i
    end
  end

  # 보너스 보유 여부 (UI 표시용)
  def has_bonus?
    logged_in? && current_user.ai_bonus_credits.to_i > 0
  end
  helper_method :has_bonus?

  # 뷰에 필요한 사용량 통계 설정
  def set_usage_stats
    @remaining_analyses = remaining_analyses
    @effective_limit = effective_limit
    @has_bonus = has_bonus?
  end

  # 입력 데이터만 캐시에 저장 (AI 미실행 - Lazy Registration)
  def save_pending_input
    cache_key = "pending_input:#{SecureRandom.uuid}"
    Rails.cache.write(cache_key, {
      idea: @idea,
      follow_up_answers: @follow_up_answers
    }, expires_in: 1.hour)

    session[:pending_input_key] = cache_key
    Rails.logger.info("[OnboardingController#ai_analyze] Saved pending input (no analysis yet): #{cache_key}")
  end

  # 비동기 AI 분석 실행 (로그인 사용자용)
  # placeholder 레코드 생성 후 백그라운드 잡으로 분석 실행
  def execute_and_save_analysis
    Rails.logger.info("[OnboardingController#execute_and_save_analysis] Creating placeholder for async analysis - user #{current_user.id}")

    # 1. placeholder 레코드 생성 (status: analyzing)
    idea_analysis = current_user.idea_analyses.create!(
      idea: @idea,
      follow_up_answers: @follow_up_answers,
      status: :analyzing,        # 분석 중 상태
      analysis_result: {},       # 빈 결과
      score: nil,
      is_real_analysis: false,
      partial_success: false
    )

    # 2. 백그라운드 잡 실행
    AiAnalysisJob.perform_later(idea_analysis.id)

    Rails.logger.info("[OnboardingController#execute_and_save_analysis] Enqueued AiAnalysisJob for IdeaAnalysis##{idea_analysis.id}")

    # 3. 즉시 결과 페이지로 리다이렉트 (로딩 상태로 표시됨)
    redirect_to ai_result_path(idea_analysis)
  end

  # 추가 질문 답변 파싱
  def parse_follow_up_answers
    answers = params[:answers]
    return {} if answers.blank?

    # JSON 문자열이면 파싱
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

  # LLM 미설정 시 사용할 기본 추가 질문
  def default_follow_up_questions
    {
      questions: [
        {
          id: "target",
          question: "주요 타겟 사용자는 누구인가요?",
          placeholder: "예: 20-30대 직장인, 대학생, 주부 등",
          required: true
        },
        {
          id: "problem",
          question: "해결하려는 가장 큰 문제는 무엇인가요?",
          placeholder: "현재 겪고 있는 불편함이나 해소되지 않는 니즈",
          required: true
        },
        {
          id: "differentiator",
          question: "기존 서비스와 다른 점은 무엇인가요? (선택)",
          placeholder: "차별화 포인트가 있다면 알려주세요",
          required: false
        }
      ]
    }
  end

  # LLM 미설정 시 사용할 Mock 분석 결과 (Figma 디자인에 맞게 확장)
  def mock_analysis
    {
      summary: "초기 창업자를 위한 커뮤니티 기반 네트워킹 플랫폼",
      target_users: {
        primary: "20-30대 초기 창업자 및 예비 창업자",
        characteristics: ["IT/스타트업에 관심 있는 대학생", "사이드프로젝트를 찾는 개발자/디자이너", "첫 창업을 준비하는 직장인"],
        personas: [
          {
            name: "열정적 대학생 창업가",
            age_range: "20-25세",
            description: "IT 관련 학과를 전공하며 창업에 관심이 많고, 팀원을 구하고 싶어하는 대학생. 아이디어는 있지만 실행력이 부족한 경우가 많음."
          },
          {
            name: "전환을 꿈꾸는 직장인",
            age_range: "28-35세",
            description: "현 직장에서 3-5년 경력을 쌓았으며, 사이드 프로젝트로 창업을 준비 중인 직장인. 실행력은 있지만 시간이 부족함."
          }
        ]
      },
      market_analysis: {
        potential: "높음",
        market_size: "국내 스타트업 지원 플랫폼 시장 규모 약 3,000억원 (2024년 기준), 연평균 12% 성장 중",
        trends: "AI 기반 매칭 서비스와 커뮤니티 중심 네트워킹 플랫폼이 성장세. 특히 초기 창업자 대상 서비스가 급성장 중.",
        competitors: ["블라인드", "리멤버", "로켓펀치", "원티드", "디스콰이어트"],
        differentiation: "커뮤니티 활동과 외주 매칭을 통합한 신뢰 기반 플랫폼. 활동 기반 프로필로 신뢰도 검증 가능."
      },
      recommendations: {
        mvp_features: [
          "커뮤니티 게시판 (자유/질문/홍보 카테고리)",
          "프로필 기반 네트워킹 및 스킬 태그",
          "구인/구직 매칭 및 1:1 채팅"
        ],
        challenges: [
          "초기 사용자 확보가 어려울 수 있음 → 대학교/창업동아리 타겟 마케팅 권장",
          "콘텐츠 품질 유지가 관건 → 커뮤니티 가이드라인 및 모더레이션 필요",
          "경쟁사 대비 차별점 부각 필요 → 신뢰 기반 프로필 시스템 강조"
        ],
        next_steps: [
          "타겟 커뮤니티(대학교 창업동아리)에서 베타 테스트 진행",
          "핵심 사용자 그룹 100명 확보",
          "피드백 기반 기능 개선 및 반복",
          "외주 매칭 기능 추가 개발",
          "수익화 모델 검증 (프리미엄 구독, 매칭 수수료)"
        ]
      },
      score: {
        overall: 72,
        weak_areas: ["시장 분석", "수익 모델"],
        strong_areas: ["아이디어 독창성", "타겟 명확성"],
        improvement_tips: [
          "타겟 시장의 규모를 구체화하세요",
          "수익화 모델을 명확히 정의하세요",
          "경쟁사 대비 차별점을 더 부각하세요"
        ]
      },
      actions: [
        { title: "핵심 타깃 1줄 정의하기", description: "명확한 페르소나 설정으로 마케팅 전략의 기반을 만드세요. 예: '창업 1년 미만 IT 분야 초기 창업자'" },
        { title: "경쟁 서비스 분석", description: "유사 서비스 5개 이상 조사하고 각각의 강점/약점 분석. 나만의 차별점 3가지 도출" },
        { title: "MVP 기능 리스트", description: "반드시 필요한 핵심 기능 5개 이내로 정리. 우선순위를 정하고 1차 런칭 범위 확정" }
      ],
      required_expertise: mock_required_expertise,
      analyzed_at: Time.current,
      idea: @idea
    }
  end

  # Mock 필요 전문성 데이터
  def mock_required_expertise
    {
      roles: [ "Developer", "Designer" ],
      skills: [ "React", "Node.js", "UI/UX", "스타트업", "MVP" ],
      description: "풀스택 개발자와 UI/UX 디자이너가 필요합니다"
    }
  end

  # 추천 전문가 찾기 (점수 예측 포함)
  def find_recommended_experts_with_predictions
    required_expertise = @analysis[:required_expertise] || mock_required_expertise

    # 전문가 매칭
    experts = ExpertMatcher.new(
      required_expertise,
      exclude_user_id: current_user&.id
    ).find_matches

    # 점수 향상 예측
    predictor = Ai::ExpertScorePredictor.new(@analysis)
    predictor.predict_all(experts)
  end
end
