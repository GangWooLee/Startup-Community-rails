# 관리자 페이지 기본 컨트롤러
# 모든 Admin 컨트롤러는 이 클래스를 상속받아 인증/인가를 처리
#
# 보안 기능:
# - 관리자 권한 검증 (require_admin)
# - 세션 활동 추적 (Authentication concern에서 처리)
# - 세션 자동 만료 (30분 비활동 시)
# - 감사 로깅 지원 (Admin::AuditLoggable)
#
class Admin::BaseController < ApplicationController
  include Admin::AuditLoggable

  before_action :require_admin
  layout "admin"

  private

  # 관리자 권한 확인
  # 비로그인 또는 관리자가 아닌 경우 접근 차단
  def require_admin
    unless current_user&.admin?
      Rails.logger.warn "[SECURITY] Unauthorized admin access attempt: #{request.remote_ip}"
      flash[:alert] = "관리자 권한이 필요합니다."
      redirect_to root_path
    end
  end
end
