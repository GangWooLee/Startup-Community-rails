# frozen_string_literal: true

# URL Sanitizer - SSRF 방지를 위한 URL 검증 서비스
#
# 용도: API를 통한 외부 이미지 URL 수집 시 내부 네트워크 접근 차단
#
# 차단 대상:
# - localhost / 127.x.x.x (loopback)
# - 10.x.x.x, 172.16-31.x.x, 192.168.x.x (private)
# - 169.254.x.x (link-local, AWS metadata endpoint)
# - ::1, fc00::/7 (IPv6 private)
#
# @example
#   UrlSanitizer.safe?("https://example.com/image.png")  # => true
#   UrlSanitizer.safe?("http://127.0.0.1/secret")        # => false
#   UrlSanitizer.safe?("http://192.168.1.1/config")      # => false
#
class UrlSanitizer
  PRIVATE_IP_RANGES = [
    IPAddr.new("127.0.0.0/8"),      # Loopback
    IPAddr.new("10.0.0.0/8"),       # Class A private
    IPAddr.new("172.16.0.0/12"),    # Class B private
    IPAddr.new("192.168.0.0/16"),   # Class C private
    IPAddr.new("169.254.0.0/16"),   # Link-local (AWS metadata)
    IPAddr.new("0.0.0.0/8"),        # This network
    IPAddr.new("::1/128"),          # IPv6 loopback
    IPAddr.new("fc00::/7"),         # IPv6 unique local
    IPAddr.new("fe80::/10")         # IPv6 link-local
  ].freeze

  ALLOWED_SCHEMES = %w[http https].freeze

  # URL이 안전한지 확인
  # @param url [String, nil] 검사할 URL
  # @return [Boolean] 안전하면 true, 위험하면 false
  def self.safe?(url)
    new(url).safe?
  end

  def initialize(url)
    @url = url
    @uri = parse_uri(url)
  end

  def safe?
    valid_uri? && valid_scheme? && public_ip?
  end

  private

  def parse_uri(url)
    return nil if url.blank?
    URI.parse(url.to_s)
  rescue URI::InvalidURIError
    nil
  end

  def valid_uri?
    @uri.present? && @uri.host.present?
  end

  def valid_scheme?
    @uri.scheme.to_s.downcase.in?(ALLOWED_SCHEMES)
  end

  # DNS를 해석하여 실제 IP가 public인지 확인
  # DNS rebinding 공격 방지를 위해 hostname이 아닌 해석된 IP 주소로 검증
  def public_ip?
    ip_address = resolve_host
    return false unless ip_address

    !private_ip?(ip_address)
  rescue => e
    Rails.logger.warn "[UrlSanitizer] Failed to resolve #{@uri.host}: #{e.message}"
    false
  end

  def resolve_host
    # IPv6 bracket 처리 (e.g., [::1])
    host = @uri.host.gsub(/\A\[|\]\z/, "")

    # IP 주소인 경우 그대로 반환
    return host if valid_ip_address?(host)

    # 호스트명인 경우 DNS 해석
    Resolv.getaddress(host)
  rescue Resolv::ResolvError, Resolv::ResolvTimeout
    nil
  end

  def valid_ip_address?(string)
    IPAddr.new(string)
    true
  rescue IPAddr::InvalidAddressError
    false
  end

  def private_ip?(ip_string)
    ip = IPAddr.new(ip_string)
    PRIVATE_IP_RANGES.any? { |range| range.include?(ip) }
  rescue IPAddr::InvalidAddressError
    true # 파싱 실패 시 안전하게 차단
  end
end
