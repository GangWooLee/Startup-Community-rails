class SessionsController < ApplicationController
  before_action :require_no_login, only: [:new, :create]

  # GET /login
  def new
    # URL 파라미터로 return_to가 전달된 경우 쿠키에 저장
    if params[:return_to].present?
      cookies[:return_to] = {
        value: params[:return_to],
        expires: 10.minutes.from_now,
        path: "/"
      }
    end
  end

  # POST /login
  def create
    user = User.find_by(email: params[:email]&.downcase)

    if user&.authenticate(params[:password])
      log_in(user)
      flash[:notice] = "로그인되었습니다. 환영합니다, #{user.name}님!"
      redirect_back_or(root_path)
    else
      flash.now[:alert] = "이메일 또는 비밀번호가 올바르지 않습니다."
      render :new, status: :unprocessable_entity
    end
  end

  # DELETE /logout
  def destroy
    log_out
    flash[:notice] = "로그아웃되었습니다."
    redirect_to root_path
  end
end
