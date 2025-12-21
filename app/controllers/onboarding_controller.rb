class OnboardingController < ApplicationController
  # 온보딩 플로우는 비로그인 상태에서 접근 가능
  skip_before_action :require_login, only: [:landing, :ai_input, :ai_result], if: -> { respond_to?(:require_login, true) }

  def landing
    # 이미 로그인한 사용자는 커뮤니티로 리디렉션
    redirect_to root_path if logged_in?
  end

  def ai_input
    # AI 아이디어 입력 화면
  end

  def ai_result
    # AI 분석 결과 화면 (Mock)
    @idea = params[:idea]

    # 아이디어가 없으면 입력 화면으로 리디렉션
    redirect_to onboarding_ai_input_path if @idea.blank?
  end
end
