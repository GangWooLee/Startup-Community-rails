# frozen_string_literal: true

# 관리자 API 키 관리 컨트롤러
# 용도: n8n 연동용 API 키 발급/폐기
class Admin::ApiKeysController < Admin::BaseController
  before_action :set_user, only: [:destroy]

  def index
    @users_with_tokens = User.where.not(api_token: nil)
                             .order(updated_at: :desc)
    @users_for_assignment = User.where(api_token: nil)
                                .where(deleted_at: nil)
                                .order(:name)
                                .limit(100)
  end

  # POST /admin/api_keys - 키 발급
  def create
    user = User.find(params[:user_id])
    token = user.generate_api_token!

    # 토큰은 발급 시에만 전체 표시 (보안)
    flash[:api_token] = token
    flash[:notice] = "#{user.name}에게 API 키가 발급되었습니다. 아래 토큰을 복사하세요."
    redirect_to admin_api_keys_path
  end

  # DELETE /admin/api_keys/:id - 키 폐기
  def destroy
    @user.revoke_api_token!

    flash[:notice] = "#{@user.name}의 API 키가 폐기되었습니다."
    redirect_to admin_api_keys_path
  end

  private

  def set_user
    @user = User.find(params[:id])
  end
end
