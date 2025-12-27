# 관리자 페이지 기본 컨트롤러
# 모든 Admin 컨트롤러는 이 클래스를 상속받아 인증/인가를 처리
class Admin::BaseController < ApplicationController
  before_action :require_admin
  layout "admin"

  private

  # 관리자 권한 확인
  # 비로그인 또는 관리자가 아닌 경우 접근 차단
  def require_admin
    unless current_user&.admin?
      flash[:alert] = "관리자 권한이 필요합니다."
      redirect_to root_path
    end
  end
end
