# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data, :blob
    policy.object_src  :none
    policy.script_src  :self, :https, :unsafe_inline  # Stimulus/Turbo 호환성
    policy.style_src   :self, :https, :unsafe_inline  # Tailwind inline styles
    policy.connect_src :self, :https

    # OAuth 제공자 허용
    policy.form_action :self, "https://accounts.google.com", "https://github.com"

    # Specify URI for violation reports (프로덕션에서 활성화)
    # policy.report_uri "/csp-violation-report-endpoint"
  end

  # Generate session nonces for permitted importmap, inline scripts, and inline styles.
  # 참고: nonce 사용 시 unsafe_inline 제거 필요
  # config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  # config.content_security_policy_nonce_directives = %w(script-src style-src)

  # Report violations without enforcing the policy (개발 중에는 report-only 모드 권장)
  config.content_security_policy_report_only = Rails.env.development?
end
