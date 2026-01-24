# frozen_string_literal: true

# 세션 기반 리다이렉트 관련 메서드
#
# 포함 기능:
# - store_location: 현재 URL을 세션/쿠키에 저장
# - redirect_back_or: 저장된 URL로 리다이렉트 또는 기본 경로로 이동
# - validate_redirect_url: Open Redirect 방지를 위한 URL 검증
# - safe_redirect_path: 안전한 상대 경로 추출
module SessionRedirect
  extend ActiveSupport::Concern

  private

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

  # URL 검증: 같은 호스트의 상대 경로만 허용 (Open Redirect 방지)
  # Phase 3.1: javascript:, data: 등 위험 스킴 거부 (XSS 방지) 추가
  def validate_redirect_url(url)
    return nil if url.blank?

    # 상대 경로는 허용 (단, // 로 시작하는 프로토콜 상대 URL은 제외)
    return url if url.start_with?("/") && !url.start_with?("//")

    # 절대 URL 검증
    begin
      uri = URI.parse(url)

      # 스킴이 있는 경우 http/https만 허용 (javascript:, data: 등 거부)
      if uri.scheme.present? && !%w[http https].include?(uri.scheme.downcase)
        Rails.logger.warn "[SessionRedirect] Blocked dangerous scheme: #{uri.scheme}"
        return nil
      end

      # 같은 호스트만 허용
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
end
