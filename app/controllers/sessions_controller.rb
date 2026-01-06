class SessionsController < ApplicationController
  before_action :require_no_login, only: [:new, :create]

  # GET /login
  def new
    # URL 파라미터로 return_to가 전달된 경우 세션과 쿠키에 저장
    if params[:return_to].present?
      # 세션에 저장 (OAuth 플로우에서 더 안정적)
      session[:return_to] = params[:return_to]

      # 쿠키에도 저장 (백업)
      cookies[:return_to] = {
        value: params[:return_to],
        expires: 10.minutes.from_now,
        path: "/"
      }

      Rails.logger.info "[AUTH] Stored return_to from params: #{params[:return_to]}"
    end

    # OAuth 폼에 전달할 return_to 값 (세션 > 쿠키 > 파라미터 순으로 확인)
    @return_to = session[:return_to] || cookies[:return_to] || params[:return_to]
  end

  # POST /login
  def create
    user = User.find_by(email: params[:email]&.downcase)

    # 탈퇴한 사용자는 User.find_by로 찾으면 nil이 됨 (익명화되어 이메일 다름)
    # 만약 unscoped로 찾아서 deleted?인 경우 처리
    if user.nil?
      # 익명화된 사용자인지 확인 (이메일이 변경되었으므로 찾을 수 없음)
      flash.now[:alert] = "이메일 또는 비밀번호가 올바르지 않습니다."
      render :new, status: :unprocessable_entity
      return
    end

    if user.authenticate(params[:password])
      log_in(user)

      # GA4 로그인 이벤트
      track_ga4_event("login", { method: "email" })

      # Remember Me: 체크박스 선택 시 영구 쿠키 저장
      if params[:remember_me] == "1"
        remember(user)
      else
        forget(user)
      end

      # 1순위: 대기 중인 입력 → AI 분석 실행 (Lazy Registration)
      if (analysis = restore_pending_input_and_analyze)
        flash[:notice] = "로그인되었습니다! AI 분석 결과를 확인하세요."
        redirect_to ai_result_path(analysis)
        return
      end

      # 2순위: 기존 캐시된 분석 결과 복원 (하위 호환성)
      if (analysis = restore_pending_analysis)
        flash[:notice] = "로그인되었습니다! AI 분석 결과를 확인하세요."
        redirect_to ai_result_path(analysis)
        return
      end

      flash[:notice] = "로그인되었습니다. 환영합니다, #{user.name}님!"
      redirect_back_or(community_path)
    else
      flash.now[:alert] = "이메일 또는 비밀번호가 올바르지 않습니다."
      render :new, status: :unprocessable_entity
    end
  end

  # DELETE /logout
  def destroy
    # current_user를 호출하여 @current_user 설정 (log_out에서 forget 호출 시 필요)
    current_user
    log_out
    flash[:notice] = "로그아웃되었습니다."
    redirect_to root_path
  end
end
