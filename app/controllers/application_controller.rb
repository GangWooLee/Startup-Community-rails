# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # 테스트 환경에서는 스킵 (Playwright HTTP 클라이언트의 User-Agent 문제 방지)
  allow_browser versions: :modern, unless: -> { Rails.env.test? }

  # ==========================================================================
  # Security
  # ==========================================================================
  # CSRF 보호 명시적 선언 (Rails 기본값이지만 보안 감사 도구 호환성 위해 명시)
  # with: :exception - 토큰 불일치 시 ActionController::InvalidAuthenticityToken 발생
  # ErrorHandling concern에서 해당 예외를 처리하여 사용자 친화적 에러 표시
  protect_from_forgery with: :exception

  # ==========================================================================
  # Concerns
  # ==========================================================================
  include ErrorHandling          # 404, CSRF 에러 핸들링
  include Authentication         # current_user, log_in/out, remember/forget
  include SessionRedirect        # store_location, redirect_back_or
  include ProfileSetupRequired   # require_profile_setup
  include PendingAnalysis        # restore_pending_analysis, restore_pending_input_and_analyze

  # GA4 이벤트 추적 헬퍼
  include Ga4Helper

  # User-Agent 헬퍼 (hotwire_native_app? 등)
  include UserAgentHelper

  # ==========================================================================
  # Layout Selection
  # ==========================================================================
  # Hotwire Native 앱에서는 간소화된 레이아웃 사용
  # 웹 헤더/사이드바 제거, 앱 네이티브 UI 사용
  layout :choose_layout

  # ==========================================================================
  # Configuration
  # ==========================================================================

  # 페이지네이션 상수
  POSTS_PER_PAGE = 50          # 메인 피드 글 수
  PROFILE_POSTS_LIMIT = 10     # 프로필 페이지 글 수

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # ==========================================================================
  # Before Actions
  # ==========================================================================

  # 보안 헤더 설정 (WebView 및 일반 브라우저 보안 강화)
  before_action :set_security_headers

  # 익명 프로필 설정: 로그인 사용자 중 프로필 미완료 시 /welcome으로 리다이렉트
  before_action :require_profile_setup, if: :logged_in?

  # 세션 활동 시간 업데이트 (5분 간격으로 DB 부하 최소화)
  before_action :touch_session_activity, if: :logged_in?

  # ==========================================================================
  # Helper Methods
  # ==========================================================================

  private

  # Hotwire Native 앱 여부에 따라 레이아웃 선택
  # @return [String] 레이아웃 이름 ("turbo_native" 또는 "application")
  def choose_layout
    hotwire_native_app? ? "turbo_native" : "application"
  end

  # 보안 헤더 설정
  # WebView 및 일반 브라우저에서 보안 강화
  #
  # 헤더 설명:
  # - X-Frame-Options: 클릭재킹 방지 (iframe 임베딩 제한)
  # - X-Content-Type-Options: MIME 타입 스니핑 방지
  # - Referrer-Policy: 외부 링크 시 리퍼러 정보 제한
  # - Permissions-Policy: 민감한 브라우저 API 사용 제한
  def set_security_headers
    response.headers["X-Frame-Options"] = "SAMEORIGIN"
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
    response.headers["Permissions-Policy"] = "geolocation=(), camera=(), microphone=()"
  end

  # 플로팅 글쓰기 버튼 숨김 (글 작성/수정 등 특정 페이지에서 사용)
  def hide_floating_button
    @hide_floating_button = true
  end

  # 세션 활동 시간 업데이트 (5분 간격으로 DB 부하 최소화)
  # @note 매 요청마다 DB 업데이트를 피하고, 5분 이상 지났을 때만 업데이트
  SESSION_ACTIVITY_INTERVAL = 5.minutes

  def touch_session_activity
    return unless session[:user_session_token].present?

    # 마지막 업데이트 시간 확인 (세션에 캐싱)
    last_touch = session[:last_activity_touch]
    return if last_touch.present? && Time.parse(last_touch) > SESSION_ACTIVITY_INTERVAL.ago

    # DB 업데이트 (5분 이상 지났거나 최초 요청)
    user_session = UserSession.find_by(session_token: session[:user_session_token])
    if user_session&.active?
      user_session.touch_activity!
      session[:last_activity_touch] = Time.current.iso8601
    end
  rescue ArgumentError
    # Time.parse 실패 시 무시
    session[:last_activity_touch] = nil
  end
end
