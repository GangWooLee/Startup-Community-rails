# frozen_string_literal: true

# 회원가입 후 익명 프로필 설정 컨트롤러
# 경로: /welcome
class ProfileSetupsController < ApplicationController
  before_action :require_login
  before_action :redirect_if_completed, only: [:show]

  # GET /welcome - 프로필 설정 페이지
  def show
    @suggested_nickname = NicknameGenerator.generate
    @default_avatar = rand(0..3)
    @avatar_options = (0..3).to_a
  end

  # PATCH /welcome - 프로필 설정 저장
  def update
    if current_user.update(profile_params.merge(profile_completed: true))
      flash[:notice] = "프로필 설정이 완료되었습니다!"
      redirect_to_original_destination
    else
      @suggested_nickname = params[:user][:nickname]
      @default_avatar = params[:user][:avatar_type].to_i
      @avatar_options = (0..3).to_a
      render :show, status: :unprocessable_entity
    end
  end

  # POST /welcome/regenerate_nickname - AJAX 닉네임 재생성
  def regenerate_nickname
    render json: { nickname: NicknameGenerator.regenerate }
  end

  private

  def profile_params
    params.require(:user).permit(:nickname, :avatar_type, :is_anonymous)
  end

  # 이미 프로필 설정 완료한 사용자는 원래 목적지로 리다이렉트
  def redirect_if_completed
    redirect_to_original_destination if current_user.profile_completed?
  end

  # 원래 목적지로 리다이렉트
  # 우선순위: Lazy Registration AI 분석 → 대기 중 분석 결과 → 저장된 URL → 커뮤니티
  def redirect_to_original_destination
    # 1. Lazy Registration: 비로그인 시 입력한 아이디어 → 로그인 후 분석 시작
    idea_analysis = restore_pending_input_and_analyze
    if idea_analysis
      redirect_to ai_result_path(idea_analysis), allow_other_host: false
      return
    end

    # 2. 대기 중인 분석 결과가 있으면 해당 페이지로 이동
    restored_analysis = restore_pending_analysis
    if restored_analysis
      redirect_to ai_result_path(restored_analysis), allow_other_host: false
      return
    end

    # 3. 저장된 URL이 있으면 해당 페이지로 이동
    return_to = session.delete(:return_to) || cookies.delete(:return_to)
    safe_url = validate_redirect_url(return_to)
    if safe_url.present?
      redirect_to safe_url, allow_other_host: false
      return
    end

    # 4. 기본: 커뮤니티로 이동
    redirect_to community_path
  end
end
