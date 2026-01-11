# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # 테스트 환경에서는 스킵 (Playwright HTTP 클라이언트의 User-Agent 문제 방지)
  allow_browser versions: :modern, unless: -> { Rails.env.test? }

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

  # 익명 프로필 설정: 로그인 사용자 중 프로필 미완료 시 /welcome으로 리다이렉트
  before_action :require_profile_setup, if: :logged_in?

  # ==========================================================================
  # Helper Methods
  # ==========================================================================

  private

  # 플로팅 글쓰기 버튼 숨김 (글 작성/수정 등 특정 페이지에서 사용)
  def hide_floating_button
    @hide_floating_button = true
  end
end
