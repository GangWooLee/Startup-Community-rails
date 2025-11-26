class UsersController < ApplicationController
  before_action :require_no_login, only: [:new, :create]

  # GET /signup
  def new
    @user = User.new
  end

  # POST /signup
  def create
    @user = User.new(user_params)

    if @user.save
      log_in(@user)
      flash[:notice] = "회원가입이 완료되었습니다. 환영합니다!"
      redirect_to root_path
    else
      flash.now[:alert] = "회원가입에 실패했습니다. 입력 내용을 확인해주세요."
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :name, :role_title, :bio)
  end
end
