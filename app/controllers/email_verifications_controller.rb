# 회원가입 이메일 인증 컨트롤러
# - 인증 코드 발송
# - 인증 코드 확인
class EmailVerificationsController < ApplicationController
  skip_before_action :require_login, raise: false

  # POST /email_verifications - 인증 코드 발송
  def create
    email = params[:email]&.downcase&.strip

    if email.blank? || !email.match?(URI::MailTo::EMAIL_REGEXP)
      render json: { success: false, message: "올바른 이메일을 입력해주세요." }, status: :unprocessable_entity
      return
    end

    # 이미 가입된 이메일인지 확인 (OAuth 사용자는 허용 - 계정 통합 지원)
    existing_user = User.find_by(email: email)
    if existing_user && !existing_user.oauth_user?
      render json: { success: false, message: "이미 가입된 이메일입니다." }, status: :unprocessable_entity
      return
    end

    # 기존 코드 무효화
    EmailVerification.where(email: email).destroy_all

    # 새 코드 생성
    verification = EmailVerification.create!(
      email: email,
      code: EmailVerification.generate_code,
      expires_at: EmailVerification::EXPIRY_MINUTES.minutes.from_now
    )

    # 이메일 발송
    AccountMailer.signup_verification(email, verification.code).deliver_now

    render json: {
      success: true,
      expires_in: EmailVerification::EXPIRY_MINUTES * 60,
      message: "인증 코드를 발송했습니다."
    }
  end

  # POST /email_verifications/verify - 인증 코드 확인
  def verify
    email = params[:email]&.downcase&.strip
    code = params[:code]&.upcase&.strip

    if email.blank? || code.blank?
      render json: { success: false, message: "이메일과 인증 코드를 입력해주세요." }, status: :unprocessable_entity
      return
    end

    verification = EmailVerification.valid.find_by(email: email, code: code)

    if verification
      verification.update!(verified: true)
      render json: { success: true, message: "인증이 완료되었습니다." }
    else
      render json: { success: false, message: "인증 코드가 올바르지 않거나 만료되었습니다." }, status: :unprocessable_entity
    end
  end
end
