class OnboardingController < ApplicationController
  # AI 분석 기능은 로그인 필수 (계정당 무료 체험 3회)
  before_action :require_login, only: [:ai_input, :ai_questions, :ai_result]
  before_action :hide_floating_button, only: [:ai_input, :ai_result]

  def landing
    # 온보딩 랜딩은 누구나 접근 가능
    # 로그인한 사용자도 AI 분석 기능 사용 가능
  end

  def ai_input
    # AI 아이디어 입력 화면 (로그인 필수)
    # 뒤로가기 경로 설정: 로그인한 사용자는 커뮤니티로, 비로그인은 온보딩으로
    @back_path = logged_in? ? community_path : root_path
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

  def ai_result
    @idea = params[:idea]
    @follow_up_answers = parse_follow_up_answers

    # 아이디어가 없으면 입력 화면으로 리디렉션
    if @idea.blank?
      redirect_to onboarding_ai_input_path
      return
    end

    # 디버그 로깅
    Rails.logger.info("[OnboardingController] LLM configured: #{LangchainConfig.any_llm_configured?}")
    Rails.logger.info("[OnboardingController] Gemini API key present: #{LangchainConfig.gemini_api_key.present?}")

    # 실제 AI 분석 수행 (LLM 설정이 있는 경우)
    if LangchainConfig.any_llm_configured?
      Rails.logger.info("[OnboardingController] Using real AI analysis with multi-agent orchestrator")

      # 멀티 에이전트 오케스트레이터 사용 (5개 전문 에이전트 순차 실행)
      orchestrator = Ai::Orchestrators::AnalysisOrchestrator.new(
        @idea,
        follow_up_answers: @follow_up_answers
      )
      @analysis = orchestrator.analyze

      Rails.logger.info("[OnboardingController] Analysis complete. Score: #{@analysis.dig(:score, :overall)}, Agents: #{@analysis.dig(:metadata, :agents_completed)}/#{@analysis.dig(:metadata, :agents_total)}")

      # 부분 실패 또는 에러 여부 확인
      @is_real_analysis = !@analysis[:error]
      @partial_analysis = @analysis.dig(:metadata, :partial_success)
    else
      Rails.logger.warn("[OnboardingController] Falling back to mock analysis - no LLM configured")

      # LLM 미설정 시 Mock 데이터 사용
      @analysis = mock_analysis
      @is_real_analysis = false
      @partial_analysis = false
    end

    # 추천 전문가 찾기 + 점수 향상 예측
    @recommended_experts = find_recommended_experts_with_predictions

    # 온보딩 경험 완료 표시 (다음 방문 시 커뮤니티 직접 접근 허용)
    cookies[:onboarding_completed] = {
      value: "true",
      expires: 1.year.from_now
    }
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
