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
    email = params[:user][:email]&.downcase&.strip

    # 이메일 인증 확인
    unless EmailVerification.find_by(email: email, verified: true)
      @user = User.new(user_params)
      @user.errors.add(:base, "이메일 인증이 필요합니다. 인증 코드를 받아주세요.")
      flash.now[:alert] = "이메일 인증이 필요합니다."
      render :new, status: :unprocessable_entity
      return
    end

    # 기존 OAuth 사용자 확인 (계정 통합)
    existing_user = User.find_by(email: email)
    if existing_user&.oauth_user?
      # 이미 OAuth로 가입된 사용자 → 비밀번호 설정 허용
      if existing_user.update(
        password: params[:user][:password],
        password_confirmation: params[:user][:password_confirmation],
        name: params[:user][:name].presence || existing_user.name
      )
        # 사용된 인증 코드 삭제
        EmailVerification.where(email: email).destroy_all
        log_in(existing_user)

        # 대기 중인 AI 분석 결과 처리
        if session[:pending_analysis_key].present?
          handle_pending_analysis(existing_user)
          return
        end

        flash[:notice] = "기존 소셜 계정에 비밀번호가 설정되었습니다. 이제 이메일로도 로그인할 수 있습니다!"
        redirect_back_or(community_path)
      else
        @user = existing_user
        flash.now[:alert] = "비밀번호 설정에 실패했습니다. #{existing_user.errors.full_messages.join(', ')}"
        render :new, status: :unprocessable_entity
      end
      return
    end

    # 새 사용자 생성
    @user = User.new(user_params)

    if @user.save
      # 사용된 인증 코드 삭제
      EmailVerification.where(email: email).destroy_all
      log_in(@user)

      # 대기 중인 AI 분석 결과 처리
      if session[:pending_analysis_key].present?
        handle_pending_analysis(@user)
        return
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

  # 대기 중인 AI 분석 결과를 사용자 계정에 연결
  def handle_pending_analysis(user)
    cache_key = session.delete(:pending_analysis_key)
    pending = Rails.cache.read(cache_key)

    if pending.present?
      Rails.cache.delete(cache_key)  # 사용 후 캐시 삭제
      idea_analysis = user.idea_analyses.create!(
        idea: pending[:idea] || pending["idea"],
        follow_up_answers: pending[:follow_up_answers] || pending["follow_up_answers"] || {},
        analysis_result: pending[:analysis_result] || pending["analysis_result"],
        score: pending[:score] || pending["score"],
        is_real_analysis: pending[:is_real_analysis] || pending["is_real_analysis"],
        partial_success: pending[:partial_success] || pending["partial_success"] || false
      )
      flash[:notice] = "계정이 설정되었습니다! AI 분석 결과를 확인하세요."
      redirect_to ai_result_path(idea_analysis)
    else
      flash[:notice] = "계정이 설정되었습니다. 환영합니다!"
      redirect_back_or(community_path)
    end
  end
end
