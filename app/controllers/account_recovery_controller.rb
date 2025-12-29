# 계정 복구 컨트롤러 (비밀번호 재설정)
# 보안 고려사항:
# - 사용자 존재 여부 노출 방지 (동일 메시지)
# - 토큰 기반 인증 (15분 만료)
# - Rate Limiting 적용 (rack-attack)
class AccountRecoveryController < ApplicationController
  # 로그인 불필요
  skip_before_action :require_login, raise: false

  # 이미 로그인된 사용자는 리다이렉트
  before_action :redirect_if_logged_in
  before_action :find_user_by_token, only: [:reset_password_form, :reset_password]

  # ========================================
  # 비밀번호 찾기/재설정
  # ========================================

  # GET /password/forgot - 비밀번호 찾기 폼
  def forgot_password_form
  end

  # POST /password/forgot - 재설정 메일 발송
  def forgot_password
    email = params[:email]&.downcase&.strip
    user = User.find_by(email: email)

    if user
      if user.oauth_only?
        # OAuth 전용 사용자: 안내 메일 발송
        AccountMailer.oauth_password_notice(user).deliver_now
      else
        # 일반 사용자: Rails 8.1 토큰 생성 및 재설정 링크 발송
        token = user.generate_token_for(:password_reset)
        AccountMailer.password_reset(user, token).deliver_now
      end
    end

    # 보안: 사용자 존재 여부와 관계없이 동일 메시지
    redirect_to forgot_password_sent_path, notice: "입력하신 이메일로 안내를 발송했습니다."
  end

  # GET /password/forgot/sent - 발송 완료 안내
  def forgot_password_sent
  end

  # GET /password/reset/:token - 새 비밀번호 입력 폼
  def reset_password_form
    # OAuth 전용 사용자는 비밀번호 재설정 불가
    if @user.oauth_only?
      redirect_to login_path, alert: "소셜 로그인 계정은 비밀번호를 재설정할 수 없습니다."
    end
  end

  # PATCH /password/reset/:token - 비밀번호 변경
  def reset_password
    if @user.oauth_only?
      redirect_to login_path, alert: "소셜 로그인 계정은 비밀번호를 재설정할 수 없습니다."
      return
    end

    if params[:password].blank?
      flash.now[:alert] = "비밀번호를 입력해주세요."
      render :reset_password_form, status: :unprocessable_entity
      return
    end

    if params[:password] != params[:password_confirmation]
      flash.now[:alert] = "비밀번호 확인이 일치하지 않습니다."
      render :reset_password_form, status: :unprocessable_entity
      return
    end

    @user.password = params[:password]

    if @user.save
      # 자동 로그인: 비밀번호 변경 후 바로 서비스 이용 가능
      session[:user_id] = @user.id
      redirect_to root_path, notice: "비밀번호가 성공적으로 변경되었습니다."
    else
      flash.now[:alert] = @user.errors.full_messages.join(", ")
      render :reset_password_form, status: :unprocessable_entity
    end
  end

  private

  def redirect_if_logged_in
    redirect_to root_path if current_user
  end

  def find_user_by_token
    @user = User.find_by_token_for(:password_reset, params[:token])

    unless @user
      redirect_to forgot_password_form_path, alert: "링크가 만료되었거나 유효하지 않습니다. 다시 시도해주세요."
    end
  end
end
