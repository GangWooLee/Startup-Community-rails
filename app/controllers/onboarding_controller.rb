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
    # AI 분석 결과 화면 (Mock)
    @idea = params[:idea]

    # 아이디어가 없으면 입력 화면으로 리디렉션
    if @idea.blank?
      redirect_to onboarding_ai_input_path
    else
      # 온보딩 경험 완료 표시 (다음 방문 시 커뮤니티 직접 접근 허용)
      cookies[:onboarding_completed] = {
        value: "true",
        expires: 1.year.from_now
      }
    end
  end
end
