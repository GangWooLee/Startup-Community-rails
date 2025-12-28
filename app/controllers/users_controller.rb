class UsersController < ApplicationController
  before_action :require_no_login, only: [:new, :create]

  # GET /signup
  def new
    @user = User.new
    # OAuth 폼에 전달할 return_to 값 (세션 > 쿠키 > 파라미터 순으로 확인)
    @return_to = session[:return_to] || cookies[:return_to] || params[:return_to]
  end

  # POST /signup
  def create
    @user = User.new(user_params)

    if @user.save
      log_in(@user)

      # 대기 중인 AI 분석 결과가 있으면 캐시에서 읽어 DB에 저장
      if session[:pending_analysis_key].present?
        cache_key = session.delete(:pending_analysis_key)
        pending = Rails.cache.read(cache_key)

        if pending.present?
          Rails.cache.delete(cache_key)  # 사용 후 캐시 삭제
          idea_analysis = @user.idea_analyses.create!(
            idea: pending[:idea] || pending["idea"],
            follow_up_answers: pending[:follow_up_answers] || pending["follow_up_answers"] || {},
            analysis_result: pending[:analysis_result] || pending["analysis_result"],
            score: pending[:score] || pending["score"],
            is_real_analysis: pending[:is_real_analysis] || pending["is_real_analysis"],
            partial_success: pending[:partial_success] || pending["partial_success"] || false
          )
          flash[:notice] = "회원가입이 완료되었습니다! AI 분석 결과를 확인하세요."
          redirect_to ai_result_path(idea_analysis)
          return
        end
      end

      flash[:notice] = "회원가입이 완료되었습니다. 환영합니다!"
      redirect_back_or(community_path)
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
