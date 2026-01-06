class OmniauthCallbacksController < ApplicationController
  # OAuth 콜백은 외부에서 오므로 CSRF 검증 스킵 필요
  skip_before_action :verify_authenticity_token, only: [:create, :failure]

  # OAuth 콜백 처리 (Google, GitHub 공통)
  def create
    auth = request.env["omniauth.auth"]

    unless auth
      Rails.logger.error "OAuth callback received without auth data"
      redirect_to login_path, alert: "로그인에 실패했습니다. 다시 시도해주세요."
      return
    end

    provider_name = auth.provider == "google_oauth2" ? "Google" : "GitHub"

    # 사용자 생성 또는 찾기 (반환: { user:, deleted: })
    result = User.from_omniauth(auth)
    @user = result[:user]

    # 탈퇴한 사용자 처리 (즉시 익명화 방식 - 복구 불가)
    if result[:deleted] && @user.present?
      redirect_to login_path, alert: "탈퇴가 완료된 계정입니다. 새 계정으로 가입해주세요."
      return
    end

    if @user&.persisted?
      # 신규 OAuth 사용자: 약관 동의 필요
      if result[:new_user] && !@user.all_terms_accepted?
        # 세션에 사용자 ID 저장 (로그인 전 상태로 약관 동의 페이지로 이동)
        session[:pending_oauth_user_id] = @user.id
        # 기존 return_to 값 유지
        session[:oauth_return_to] = session.delete(:return_to) || cookies.delete(:return_to)
        Rails.logger.info "OAuth new user - redirecting to terms: #{provider_name} - User #{@user.id}"
        redirect_to oauth_terms_path
        return
      end

      # 로그인 처리 (세션 ID 재생성 + pending_analysis_key/pending_input_key 보존)
      log_in(@user)

      # GA4 이벤트: 신규 사용자 = sign_up, 기존 사용자 = login
      ga4_method = auth.provider == "google_oauth2" ? "google" : "github"
      if result[:new_user]
        track_ga4_event("sign_up", { method: ga4_method })
      else
        track_ga4_event("login", { method: ga4_method })
      end

      # 1순위: 대기 중인 입력 → AI 분석 실행 (Lazy Registration)
      if (analysis = restore_pending_input_and_analyze)
        Rails.logger.info "OAuth login with pending input (Lazy Registration): #{provider_name} - User #{@user.id}"
        flash[:notice] = "#{provider_name} 계정으로 로그인되었습니다! AI 분석 결과를 확인하세요."
        redirect_to ai_result_path(analysis)
        return
      end

      # 2순위: 기존 캐시된 분석 결과 복원 (하위 호환성)
      if (analysis = restore_pending_analysis)
        Rails.logger.info "OAuth login with pending analysis: #{provider_name} - User #{@user.id}"
        flash[:notice] = "#{provider_name} 계정으로 로그인되었습니다! AI 분석 결과를 확인하세요."
        redirect_to ai_result_path(analysis)
        return
      end

      # 리디렉션 URL 결정 (세션 > 쿠키 > 기본값)
      # omniauth.origin은 외부에서 조작 가능하므로 사용하지 않음 (Open Redirect 방지)
      session_return_to = session.delete(:return_to)
      cookie_return_to = cookies.delete(:return_to)

      Rails.logger.info "[OAuth] session return_to: #{session_return_to.inspect}"
      Rails.logger.info "[OAuth] cookie return_to: #{cookie_return_to.inspect}"

      # URL 검증 후 리디렉션
      redirect_url = validate_redirect_url(session_return_to) ||
                     validate_redirect_url(cookie_return_to) ||
                     community_path

      Rails.logger.info "OAuth login successful: #{provider_name} - User #{@user.id} - Redirecting to: #{redirect_url}"
      flash[:notice] = "#{provider_name} 계정으로 로그인되었습니다!"
      redirect_to redirect_url
    else
      # 사용자 저장 실패 (이메일 중복 등)
      Rails.logger.error "OAuth user creation failed: #{@user.errors.full_messages.join(', ')}"
      redirect_to login_path, alert: "로그인에 실패했습니다. 이미 같은 이메일로 가입된 계정이 있을 수 있습니다."
    end
  end

  # OAuth 실패 시
  def failure
    error_type = params[:message] || "unknown_error"
    error_origin = params[:origin]
    error_strategy = params[:strategy]

    Rails.logger.error "OAuth authentication failed: #{error_type}"
    Rails.logger.error "OAuth failure details - strategy: #{error_strategy}, origin: #{error_origin}"
    Rails.logger.error "OAuth failure params: #{params.to_unsafe_h.except(:controller, :action)}"

    # 세션/쿠키 정리
    session.delete(:return_to)
    cookies.delete(:return_to)

    # 사용자 친화적 오류 메시지
    alert_message = case error_type
    when "access_denied"
      "로그인이 취소되었습니다."
    when "invalid_credentials"
      "인증 정보가 올바르지 않습니다."
    when "redirect_uri_mismatch"
      "OAuth 설정 오류입니다. 관리자에게 문의해주세요."
    else
      "로그인에 실패했습니다. 다시 시도해주세요."
    end

    redirect_to login_path, alert: alert_message
  end
end
