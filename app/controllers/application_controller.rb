class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # 페이지네이션 상수
  POSTS_PER_PAGE = 50          # 메인 피드 글 수
  PROFILE_POSTS_LIMIT = 10     # 프로필 페이지 글 수

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # 에러 핸들링 (프로덕션에서만)
  unless Rails.env.development?
    rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
    rescue_from ActionController::RoutingError, with: :handle_not_found
    rescue_from ActionController::InvalidAuthenticityToken, with: :handle_invalid_token
  end

  # Authentication helpers
  helper_method :current_user, :logged_in?

  private

  # 404 에러 핸들러
  def handle_not_found(exception = nil)
    Rails.logger.warn "[404] #{exception&.message} - #{request.path}"
    respond_to do |format|
      format.html { render file: Rails.public_path.join("404.html"), status: :not_found, layout: false }
      format.json { render json: { error: "Not found" }, status: :not_found }
    end
  end

  # CSRF 토큰 에러 핸들러
  def handle_invalid_token(exception = nil)
    Rails.logger.warn "[CSRF] Invalid token - #{request.path}"
    respond_to do |format|
      format.html { redirect_to root_path, alert: "세션이 만료되었습니다. 다시 시도해주세요." }
      format.json { render json: { error: "Invalid authenticity token" }, status: :unprocessable_entity }
    end
  end

  # Returns the currently logged-in user (if any)
  # 1. 세션에서 확인 (일반 로그인)
  # 2. 쿠키에서 확인 (Remember Me)
  # 탈퇴한 사용자는 nil 반환 (세션/쿠키 무효화)
  def current_user
    if session[:user_id]
      @current_user ||= User.find_by(id: session[:user_id])
    elsif cookies.encrypted[:user_id]
      # Remember Me: 쿠키 기반 인증
      user = User.find_by(id: cookies.encrypted[:user_id])
      if user&.authenticated?(cookies.encrypted[:remember_token])
        log_in(user)
        @current_user = user
      end
    end

    # 탈퇴한 사용자는 세션/쿠키 무효화
    if @current_user&.deleted?
      forget(@current_user)
      reset_session
      @current_user = nil
    end

    @current_user
  end

  # Returns true if the user is logged in, false otherwise
  def logged_in?
    current_user.present?
  end

  # Logs in the given user by storing their id in the session
  # 보안: 로그인 시 세션 ID 재생성 (Session Fixation 방지)
  def log_in(user)
    # 기존 세션의 중요 값들 보존
    return_to = session[:return_to]
    pending_analysis_key = session[:pending_analysis_key]
    pending_input_key = session[:pending_input_key]  # Lazy Registration용

    # 세션 ID 재생성 (Session Fixation Attack 방지)
    reset_session

    # 보존된 값 복원
    session[:return_to] = return_to if return_to.present?
    session[:pending_analysis_key] = pending_analysis_key if pending_analysis_key.present?
    session[:pending_input_key] = pending_input_key if pending_input_key.present?

    # 새 세션에 사용자 ID 저장
    session[:user_id] = user.id
    user.update(last_sign_in_at: Time.current)
  end

  # Remember Me: 영구 쿠키 생성 (20년)
  def remember(user)
    user.remember
    cookies.permanent.encrypted[:user_id] = user.id
    cookies.permanent.encrypted[:remember_token] = user.remember_token
  end

  # Remember Me: 쿠키 및 DB 토큰 삭제
  def forget(user)
    user&.forget
    cookies.delete(:user_id)
    cookies.delete(:remember_token)
  end

  # Logs out the current user by clearing the session and cookies
  # 보안: 로그아웃 시 전체 세션 + 쿠키 삭제
  def log_out
    forget(@current_user) if @current_user
    reset_session  # 세션 완전 삭제 (session.delete보다 안전)
    @current_user = nil
  end

  # Before action to require login for protected routes
  def require_login
    unless logged_in?
      # 로그인 후 원래 목적지로 돌아가기 위해 URL 저장 (쿠키 사용 - OAuth에서도 유지됨)
      store_location if request.get?
      flash[:alert] = "로그인이 필요합니다."
      redirect_to login_path
    end
  end

  # 현재 URL을 세션과 쿠키에 저장
  # 세션은 OAuth 외부 리디렉션 후에도 유지됨 (더 안정적)
  # 쿠키는 일반 로그인용 백업
  def store_location
    url = request.original_url
    # 상대 경로로 변환하여 저장 (보안상 안전)
    safe_url = safe_redirect_path(url)
    return unless safe_url

    Rails.logger.info "[AUTH] Storing return_to: #{safe_url}"

    # 세션에 저장 (OAuth 플로우에서 더 안정적)
    session[:return_to] = safe_url

    # 쿠키에도 저장 (일반 로그인용 백업)
    cookies[:return_to] = {
      value: safe_url,
      expires: 10.minutes.from_now,
      path: "/"  # 전체 경로에서 유효
    }
  end

  # 저장된 URL로 리디렉션하거나 기본 경로로 이동
  def redirect_back_or(default)
    # 세션 우선, 쿠키 백업
    session_return_to = session.delete(:return_to)
    cookie_return_to = cookies.delete(:return_to)
    return_url = validate_redirect_url(session_return_to) ||
                 validate_redirect_url(cookie_return_to)

    Rails.logger.info "[AUTH] Redirecting to: #{return_url || default} (session: #{session_return_to.inspect}, cookie: #{cookie_return_to.inspect})"
    redirect_to(return_url || default)
  end

  # Before action to redirect logged-in users (for login/signup pages)
  def require_no_login
    if logged_in?
      flash[:notice] = "이미 로그인되어 있습니다."
      redirect_back_or(community_path)
    end
  end

  # 플로팅 글쓰기 버튼 숨김 (글 작성/수정 등 특정 페이지에서 사용)
  def hide_floating_button
    @hide_floating_button = true
  end

  # URL 검증: 같은 호스트의 상대 경로만 허용 (Open Redirect 방지)
  def validate_redirect_url(url)
    return nil if url.blank?

    # 상대 경로는 허용 (단, // 로 시작하는 프로토콜 상대 URL은 제외)
    return url if url.start_with?("/") && !url.start_with?("//")

    # 절대 URL은 같은 호스트만 허용
    begin
      uri = URI.parse(url)
      if uri.host.nil? || uri.host == request.host
        uri.path.presence || "/"
      end
    rescue URI::InvalidURIError
      nil
    end
  end

  # URL에서 경로만 추출 (안전한 저장용)
  def safe_redirect_path(url)
    return nil if url.blank?

    begin
      uri = URI.parse(url)
      # 같은 호스트인 경우에만 경로 추출
      if uri.host.nil? || uri.host == request.host
        path = uri.path.presence || "/"
        path += "?#{uri.query}" if uri.query.present?
        path
      end
    rescue URI::InvalidURIError
      nil
    end
  end

  # 대기 중인 AI 분석 결과 복원 (비로그인 상태에서 분석 후 로그인 시)
  # 캐시에 저장된 분석 결과를 DB로 이전하고, 해당 IdeaAnalysis 레코드 반환
  def restore_pending_analysis
    return nil unless logged_in?
    return nil unless session[:pending_analysis_key].present?

    cache_key = session[:pending_analysis_key]
    cached_data = Rails.cache.read(cache_key)

    return nil unless cached_data

    Rails.logger.info "[AI] Restoring pending analysis from cache: #{cache_key}"

    # DB에 저장
    idea_analysis = current_user.idea_analyses.create!(
      idea: cached_data[:idea],
      follow_up_answers: cached_data[:follow_up_answers],
      analysis_result: cached_data[:analysis_result],
      score: cached_data[:score],
      is_real_analysis: cached_data[:is_real_analysis],
      partial_success: cached_data[:partial_success]
    )

    # 정리
    Rails.cache.delete(cache_key)
    session.delete(:pending_analysis_key)

    Rails.logger.info "[AI] Restored analysis as IdeaAnalysis##{idea_analysis.id}"
    idea_analysis
  rescue => e
    Rails.logger.error "[AI] Failed to restore pending analysis: #{e.message}"
    session.delete(:pending_analysis_key)
    nil
  end

  # 대기 중인 입력 데이터 복원 + 비동기 AI 분석 (Lazy Registration)
  # 비로그인 상태에서 입력만 저장 → 로그인 후 백그라운드에서 AI 분석 실행
  def restore_pending_input_and_analyze
    return nil unless logged_in?
    return nil unless session[:pending_input_key].present?

    cache_key = session[:pending_input_key]
    cached_input = Rails.cache.read(cache_key)

    return nil unless cached_input

    # 횟수 제한 확인 (로그인한 사용자의 기존 분석 횟수 체크)
    max_analyses = OnboardingController::MAX_FREE_ANALYSES
    usage_count = current_user.idea_analyses.count

    if usage_count >= max_analyses
      Rails.logger.warn "[AI] User##{current_user.id} exceeded free analysis limit (#{usage_count}/#{max_analyses})"

      # 캐시 및 세션 정리
      Rails.cache.delete(cache_key)
      session.delete(:pending_input_key)

      # 횟수 초과 알림
      flash[:alert] = "AI 분석 무료 이용 횟수(#{max_analyses}회)를 모두 사용했습니다."

      return nil
    end

    Rails.logger.info "[AI] Creating placeholder IdeaAnalysis for async processing: #{cache_key}"

    # 1. placeholder 레코드 생성 (status: analyzing)
    idea_analysis = current_user.idea_analyses.create!(
      idea: cached_input[:idea],
      follow_up_answers: cached_input[:follow_up_answers],
      status: :analyzing,        # 분석 중 상태
      analysis_result: {},       # 빈 결과
      score: nil,
      is_real_analysis: false,
      partial_success: false
    )

    # 2. 캐시 정리
    Rails.cache.delete(cache_key)
    session.delete(:pending_input_key)

    # 3. 백그라운드 잡 실행
    AiAnalysisJob.perform_later(idea_analysis.id)

    Rails.logger.info "[AI] Enqueued AiAnalysisJob for IdeaAnalysis##{idea_analysis.id}"
    idea_analysis
  rescue => e
    Rails.logger.error "[AI] Failed to create async analysis: #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
    session.delete(:pending_input_key)
    nil
  end

  # Mock 분석 결과 (LLM 미설정 시) - ApplicationController용 간략 버전
  def mock_analysis_result(idea)
    {
      summary: "AI 분석 결과입니다.",
      target_users: {
        primary: "타겟 사용자",
        characteristics: [],
        personas: []
      },
      market_analysis: {
        potential: "높음",
        market_size: "분석 중",
        trends: "분석 중",
        competitors: [],
        differentiation: "분석 중"
      },
      recommendations: {
        mvp_features: [],
        challenges: [],
        next_steps: []
      },
      score: {
        overall: 70,
        weak_areas: [],
        strong_areas: [],
        improvement_tips: []
      },
      actions: [],
      required_expertise: {
        roles: [],
        skills: [],
        description: "분석 중"
      },
      analyzed_at: Time.current,
      idea: idea
    }
  end
end
