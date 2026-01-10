# frozen_string_literal: true

# 에러 핸들링 관련 메서드
#
# 포함 기능:
# - handle_not_found: 404 에러 핸들러
# - handle_invalid_token: CSRF 토큰 에러 핸들러
module ErrorHandling
  extend ActiveSupport::Concern

  included do
    # 에러 핸들링 (프로덕션에서만)
    unless Rails.env.development?
      rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
      rescue_from ActionController::RoutingError, with: :handle_not_found
      rescue_from ActionController::InvalidAuthenticityToken, with: :handle_invalid_token
    end
  end

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
end
