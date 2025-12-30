# 관리자 - 탈퇴 회원 관리 컨트롤러
# - 탈퇴 회원 목록/상세
# - 암호화된 개인정보 열람 (로깅 필수)
class Admin::UserDeletionsController < Admin::BaseController
  before_action :set_deletion, only: [:show, :reveal]

  # GET /admin/user_deletions - 탈퇴 회원 목록
  def index
    @deletions = UserDeletion.includes(:user)
                             .order(created_at: :desc)
                             .limit(50)

    @stats = {
      total: UserDeletion.count,
      this_month: UserDeletion.where(created_at: Time.current.beginning_of_month..).count,
      by_reason: UserDeletion.group(:reason_category).count
    }
  end

  # GET /admin/user_deletions/:id - 탈퇴 상세 (마스킹된 상태)
  def show
    # 기본은 마스킹된 상태로 표시
  end

  # POST /admin/user_deletions/:id/reveal - 개인정보 열람 (로깅)
  def reveal
    # 열람 사유 필수
    unless params[:reason].present? && params[:reason].length >= 5
      render json: {
        success: false,
        error: "열람 사유를 5자 이상 입력해주세요."
      }, status: :unprocessable_entity
      return
    end

    # 열람 로그 기록 + 카운트 증가
    @deletion.record_admin_view!(
      admin: current_user,
      reason: params[:reason],
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )

    # 복호화된 원본 데이터 반환
    render json: {
      success: true,
      data: {
        email: @deletion.email_original,
        name: @deletion.name_original,
        phone: @deletion.phone_original,
        snapshot: @deletion.parsed_snapshot
      }
    }
  rescue StandardError => e
    Rails.logger.error "[AdminReveal] Error: #{e.message}"
    render json: {
      success: false,
      error: "정보 조회 중 오류가 발생했습니다."
    }, status: :internal_server_error
  end

  private

  def set_deletion
    @deletion = UserDeletion.find(params[:id])
  end
end
