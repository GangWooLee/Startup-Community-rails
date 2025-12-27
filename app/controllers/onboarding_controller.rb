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

    # 분석에 전달할 전체 컨텍스트 생성
    analysis_context = build_analysis_context

    # 실제 AI 분석 수행 (LLM 설정이 있는 경우)
    if LangchainConfig.any_llm_configured?
      @analysis = Ai::IdeaAnalyzer.new(analysis_context).analyze
      @is_real_analysis = !@analysis[:error]
    else
      # LLM 미설정 시 Mock 데이터 사용
      @analysis = mock_analysis
      @is_real_analysis = false
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

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          "profile-overlay-container",
          partial: "onboarding/expert_profile_overlay",
          locals: { user: @user }
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

  # 분석에 전달할 전체 컨텍스트 생성
  def build_analysis_context
    context = "아이디어: #{@idea}"

    if @follow_up_answers.present?
      context += "\n\n추가 정보:"
      @follow_up_answers.each do |key, value|
        next if value.blank?
        label = case key.to_s
        when "target" then "타겟 사용자"
        when "problem" then "해결하려는 문제"
        when "differentiator" then "차별화 포인트"
        else key.to_s.humanize
        end
        context += "\n- #{label}: #{value}"
      end
    end

    context
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

  # LLM 미설정 시 사용할 Mock 분석 결과
  def mock_analysis
    {
      summary: "초기 창업자를 위한 커뮤니티 기반 네트워킹 플랫폼",
      target_users: {
        primary: "20-30대 초기 창업자 및 예비 창업자",
        characteristics: ["IT/스타트업에 관심 있는 대학생", "사이드프로젝트를 찾는 개발자/디자이너", "첫 창업을 준비하는 직장인"]
      },
      market_analysis: {
        potential: "높음",
        competitors: ["블라인드", "리멤버", "로켓펀치"],
        differentiation: "커뮤니티 활동과 외주 매칭을 통합한 신뢰 기반 플랫폼"
      },
      recommendations: {
        mvp_features: ["커뮤니티 게시판", "프로필 기반 네트워킹", "구인/구직 매칭"],
        challenges: ["초기 사용자 확보", "콘텐츠 품질 유지"],
        next_steps: ["타겟 커뮤니티에서 베타 테스트", "핵심 사용자 그룹 형성", "피드백 기반 기능 개선"]
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
        { title: "핵심 타깃 1줄 정의하기", description: "주 사용자가 누구인지 한 문장으로 정리하세요" },
        { title: "경쟁 서비스 분석", description: "유사 서비스 3개 이상 조사하고 차별점 도출" },
        { title: "MVP 기능 리스트", description: "반드시 필요한 핵심 기능 5개 이내로 정리" }
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
