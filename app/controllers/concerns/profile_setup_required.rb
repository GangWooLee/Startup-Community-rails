# frozen_string_literal: true

# 프로필 설정 완료 요구 관련 메서드
#
# 포함 기능:
# - require_profile_setup: 프로필 미완료 시 설정 페이지로 리다이렉트
# - skip_profile_setup?: 프로필 설정 확인을 건너뛸 컨트롤러/액션 목록
module ProfileSetupRequired
  extend ActiveSupport::Concern

  private

  # 프로필 설정 완료 여부 확인 (로그인 사용자만)
  # 무한 루프 방지: profile_setups, sessions(logout), 온보딩, 공개 페이지 제외
  def require_profile_setup
    return if skip_profile_setup?
    return if current_user.profile_completed?

    # 원래 가려던 곳 저장 (GET/HEAD 요청만)
    # HEAD 요청도 GET과 동일하게 라우팅되므로 포함
    store_location if request.get? || request.head?

    Rails.logger.info "[PROFILE] User##{current_user.id} redirected to profile setup"
    redirect_to profile_setup_path
  end

  # 프로필 설정 확인을 건너뛸 컨트롤러/액션 목록
  def skip_profile_setup?
    # 무한 루프 방지
    return true if controller_name == "profile_setups"

    # 로그아웃은 허용
    return true if controller_name == "sessions" && action_name == "destroy"

    # 온보딩/랜딩 페이지는 허용 (비회원도 접근 가능한 페이지)
    return true if controller_name == "onboarding" && %w[landing input follow_up result ai_result].include?(action_name)

    # OAuth 콜백은 허용
    return true if controller_name == "omniauth_callbacks"
    return true if controller_name == "oauth_terms"

    # 약관 동의 페이지는 허용
    return true if controller_name == "users" && action_name == "terms_agreement"

    # 정적 페이지는 허용
    return true if controller_name == "pages"

    false
  end
end
