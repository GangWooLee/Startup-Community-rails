# 계정 관련 이메일 발송 Mailer
# - 회원가입 이메일 인증
# - 비밀번호 재설정
# - OAuth 사용자 안내
class AccountMailer < ApplicationMailer
  # Resend 테스트용: onboarding@resend.dev
  # 프로덕션 도메인 연결 시: noreply@undrewai.com 으로 변경
  default from: "Undrew <onboarding@resend.dev>"

  # 회원가입 이메일 인증 코드 발송
  # 5분 유효
  def signup_verification(email, code)
    @code = code
    @expiry_minutes = EmailVerification::EXPIRY_MINUTES

    mail(
      to: email,
      subject: "[Undrew] 회원가입 인증 코드"
    )
  end

  # 비밀번호 재설정 링크 발송
  # 보안: Rails 8.1 서명 토큰 (15분 유효)
  def password_reset(user, token)
    @user = user
    @reset_url = reset_password_form_url(token: token)
    @expiry_minutes = 15  # Rails 8.1 has_secure_password 기본값

    mail(
      to: @user.email,
      subject: "[Undrew] 비밀번호 재설정"
    )
  end

  # OAuth 전용 사용자에게 안내 메일 발송
  # 비밀번호 재설정 불가 안내 + 소셜 로그인 유도
  def oauth_password_notice(user)
    @user = user
    @providers = user.connected_providers.map do |provider|
      case provider
      when "google_oauth2" then "Google"
      when "github" then "GitHub"
      else provider.humanize
      end
    end

    mail(
      to: @user.email,
      subject: "[Undrew] 비밀번호 재설정 안내"
    )
  end
end
