# frozen_string_literal: true

# URL 관련 헬퍼
#
# URL 안전성 검증 및 자동 링크 변환 기능 제공
module UrlHelper
  # URL 안전성 검증 (XSS 방지)
  # javascript:, data: 스킴 등 위험한 URL 차단
  # @param url [String] 검증할 URL
  # @return [Boolean] 안전한 URL이면 true
  def safe_url?(url)
    return false if url.blank?

    begin
      uri = URI.parse(url)
      # http, https 프로토콜만 허용
      %w[http https].include?(uri.scheme&.downcase)
    rescue URI::InvalidURIError
      false
    end
  end

  # 텍스트 내 URL을 클릭 가능한 하이퍼링크로 변환
  # rails_autolink gem을 사용하여 안전하고 검증된 방식으로 변환
  #
  # @param text [String] 변환할 텍스트
  # @param variant [Symbol] 링크 스타일 (:default | :light)
  # @return [ActiveSupport::SafeBuffer] 링크가 포함된 HTML safe 문자열
  #
  # @example 기본 스타일
  #   <%= linkify_urls("https://google.com 방문하세요") %>
  #
  # @example 밝은 스타일 (채팅용)
  #   <%= linkify_urls(message.content, variant: :light) %>
  #
  # 지원 형식:
  #   - http://, https:// URL
  #   - www. 로 시작하는 URL
  #
  # 보안:
  #   - XSS 방지: sanitize: true (기본값)
  #   - 새 탭 열기: target="_blank"
  #   - 보안 속성: rel="noopener noreferrer"
  def linkify_urls(text, variant: :default)
    return "".html_safe if text.blank?

    link_class = case variant
    when :light
      # 채팅용 (흰색 링크)
      "text-white underline break-all"
    else
      # 기본 (게시글, 댓글, 프로필 등)
      "text-primary hover:underline break-all"
    end

    # rails_autolink gem의 auto_link 사용
    auto_link(text, {
      html: {
        target: "_blank",
        rel: "noopener noreferrer",
        class: link_class
      },
      link: :urls,
      sanitize: true
    })
  end
end
