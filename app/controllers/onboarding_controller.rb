class OnboardingController < ApplicationController
  # AI 분석 기능은 로그인 필수 (계정당 무료 체험 3회)
  before_action :require_login, only: [:ai_input, :ai_result]
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

  def ai_result
    @idea = params[:idea]

    # 아이디어가 없으면 입력 화면으로 리디렉션
    if @idea.blank?
      redirect_to onboarding_ai_input_path
      return
    end

    # 실제 AI 분석 수행 (LLM 설정이 있는 경우)
    if LangchainConfig.any_llm_configured?
      @analysis = Ai::IdeaAnalyzer.new(@idea).analyze
      @is_real_analysis = !@analysis[:error]
    else
      # LLM 미설정 시 Mock 데이터 사용
      @analysis = mock_analysis
      @is_real_analysis = false
    end

    # 추천 전문가 찾기
    @recommended_experts = find_recommended_experts

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

  # LLM 미설정 시 사용할 Mock 분석 결과
  def mock_analysis
    {
      summary: "커뮤니티 기반의 스타트업 네트워킹 플랫폼으로, 초기 창업자들이 정보를 공유하고 협업 기회를 찾을 수 있는 공간입니다.",
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
        innovation: 7,
        feasibility: 8,
        market_fit: 7,
        overall: 7
      },
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

  # 추천 전문가 찾기
  def find_recommended_experts
    required_expertise = @analysis[:required_expertise] || mock_required_expertise

    ExpertMatcher.new(
      required_expertise,
      exclude_user_id: current_user&.id
    ).find_matches
  end
end
