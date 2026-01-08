# 회원 탈퇴 컨트롤러
# - 탈퇴 확인 페이지
# - 탈퇴 처리 (즉시 익명화, 복구 불가)
class UserDeletionsController < ApplicationController
  before_action :require_login, only: [ :new, :create ]

  # GET /account/delete - 탈퇴 확인 페이지
  def new
    @user = current_user
    @reason_categories = UserDeletion::REASON_CATEGORIES
  end

  # POST /account/delete - 탈퇴 처리
  def create
    unless verify_password
      flash.now[:alert] = current_user.oauth_only? ? "탈퇴 동의가 필요합니다." : "비밀번호가 올바르지 않습니다."
      @user = current_user
      @reason_categories = UserDeletion::REASON_CATEGORIES
      render :new, status: :unprocessable_entity
      return
    end

    result = Users::DeletionService.new(
      user: current_user,
      reason_category: params[:reason_category],
      reason_detail: params[:reason_detail],
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    ).call

    if result.success?
      log_out
      flash[:notice] = "회원 탈퇴가 완료되었습니다. 이용해 주셔서 감사합니다."
      redirect_to root_path
    else
      flash.now[:alert] = result.errors.join(", ")
      @user = current_user
      @reason_categories = UserDeletion::REASON_CATEGORIES
      render :new, status: :unprocessable_entity
    end
  end

  private

  def verify_password
    if current_user.oauth_only?
      # OAuth 사용자는 체크박스 동의로 대체
      params[:confirm_deletion] == "1" || params[:confirm_deletion] == "true"
    else
      current_user.authenticate(params[:password])
    end
  end
end
