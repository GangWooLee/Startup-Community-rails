# frozen_string_literal: true

# Cloudflare IP 신뢰 설정
# Cloudflare를 리버스 프록시로 사용할 때 실제 클라이언트 IP를 정확히 감지하기 위해 필요
#
# 문제: Cloudflare 없이는 request.remote_ip가 정확함
#       Cloudflare를 통하면 request.remote_ip가 Cloudflare 서버 IP로 보임
# 해결: Cloudflare IP를 신뢰 프록시로 등록하면 X-Forwarded-For에서 실제 IP 추출
#
# Cloudflare IP 목록: https://www.cloudflare.com/ips/
# 마지막 업데이트: 2026-01-19

Rails.application.config.after_initialize do
  # Cloudflare IPv4 ranges (2026-01 기준)
  cloudflare_ips_v4 = %w[
    173.245.48.0/20
    103.21.244.0/22
    103.22.200.0/22
    103.31.4.0/22
    141.101.64.0/18
    108.162.192.0/18
    190.93.240.0/20
    188.114.96.0/20
    197.234.240.0/22
    198.41.128.0/17
    162.158.0.0/15
    104.16.0.0/13
    104.24.0.0/14
    172.64.0.0/13
    131.0.72.0/22
  ].freeze

  # Cloudflare IPv6 ranges (2026-01 기준)
  cloudflare_ips_v6 = %w[
    2400:cb00::/32
    2606:4700::/32
    2803:f800::/32
    2405:b500::/32
    2405:8100::/32
    2a06:98c0::/29
    2c0f:f248::/32
  ].freeze

  # IPAddr 객체로 변환
  cloudflare_proxies = (cloudflare_ips_v4 + cloudflare_ips_v6).map { |ip| IPAddr.new(ip) }

  # 기존 신뢰 프록시에 Cloudflare IP 추가
  Rails.application.config.action_dispatch.trusted_proxies =
    ActionDispatch::RemoteIp::TRUSTED_PROXIES + cloudflare_proxies

  Rails.logger.info "[Cloudflare] Trusted #{cloudflare_proxies.size} proxy ranges"
end
