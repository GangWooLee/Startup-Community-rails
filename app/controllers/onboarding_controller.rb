class OnboardingController < ApplicationController
  # 온보딩은 비로그인 상태에서도 접근 가능 (require_login 사용 안함)

  def landing
    # 로그인한 사용자도 온보딩 플로우 사용 가능 (AI 분석 기능)
    # 별도 리디렉션 없음
  end

  def ai_input
    # AI 아이디어 입력 화면
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
