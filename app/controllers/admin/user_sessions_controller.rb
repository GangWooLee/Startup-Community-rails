# frozen_string_literal: true

# 관리자 사용자 세션 관리 컨트롤러
# 로그인/로그아웃 기록 조회, 강제 로그아웃 기능
class Admin::UserSessionsController < Admin::BaseController
  before_action :set_session, only: [ :force_logout ]

  # GET /admin/user_sessions
  # 전체 세션 목록 (필터링, 검색, 페이지네이션)
  def index
    @sessions = UserSession.includes(:user).recent

    # 필터링
    apply_filters

    # 페이지네이션
    @page = (params[:page] || 1).to_i
    @per_page = 30
    @total_count = @sessions.count
    @total_pages = (@total_count.to_f / @per_page).ceil
    @sessions = @sessions.offset((@page - 1) * @per_page).limit(@per_page)

    # 통계
    calculate_stats
  end

  # GET /admin/user_sessions/active
  # 현재 활성 세션만 조회
  def active
    @sessions = UserSession.includes(:user).active.order(last_activity_at: :desc)

    # 페이지네이션
    @page = (params[:page] || 1).to_i
    @per_page = 30
    @total_count = @sessions.count
    @total_pages = (@total_count.to_f / @per_page).ceil
    @sessions = @sessions.offset((@page - 1) * @per_page).limit(@per_page)

    # 활성 세션 통계
    @active_count = UserSession.active.count
    @unique_users = UserSession.active.distinct.count(:user_id)

    render :index
  end

  # POST /admin/user_sessions/:id/force_logout
  # 특정 세션 강제 종료
  def force_logout
    if @session.active?
      @session.end_session!(reason: "admin_action")

      # 관리자 행위 로깅
      AdminViewLog.create!(
        admin: current_user,
        target: @session.user,
        action: "force_logout_session",
        ip_address: request.remote_ip,
        user_agent: request.user_agent,
        reason: "Session ID: #{@session.id}"
      )

      flash[:notice] = "#{@session.user.name}님의 세션이 강제 종료되었습니다."
    else
      flash[:alert] = "이미 종료된 세션입니다."
    end

    redirect_back(fallback_location: admin_user_sessions_path)
  end

  # GET /admin/user_sessions/export.csv
  # 세션 기록 CSV 내보내기
  def export
    @sessions = UserSession.includes(:user).recent

    # 필터링 (index와 동일)
    apply_filters

    columns = {
      id: "ID",
      user_name: ->(s) { s.user&.name || "탈퇴 회원" },
      user_email: ->(s) { s.user&.email || "N/A" },
      login_method: "로그인 방식",
      logged_in_at: "로그인 시간",
      logged_out_at: "로그아웃 시간",
      logout_reason: ->(s) { logout_reason_label(s.logout_reason) },
      ip_address: "IP 주소",
      device_type: "디바이스",
      remember_me: "Remember Me",
      duration: ->(s) { s.duration_formatted }
    }

    service = Admin::CsvExportService.new(@sessions, columns: columns, filename_prefix: "user_sessions")
    send_data service.generate, filename: service.filename, type: "text/csv; charset=utf-8"
  end

  private

  def set_session
    @session = UserSession.find(params[:id])
  end

  def apply_filters
    # 상태 필터
    case params[:status]
    when "active"
      @sessions = @sessions.active
    when "ended"
      @sessions = @sessions.ended
    end

    # 로그인 방식 필터
    if params[:method].present?
      @sessions = @sessions.by_login_method(params[:method])
    end

    # 사용자 필터 (ID 또는 검색)
    if params[:user_id].present?
      @sessions = @sessions.where(user_id: params[:user_id])
    end

    if params[:q].present?
      keyword = "%#{params[:q]}%"
      @sessions = @sessions.joins(:user).where(
        "users.email LIKE ? OR users.name LIKE ?", keyword, keyword
      )
    end

    # 날짜 필터
    if params[:from_date].present?
      @sessions = @sessions.where("logged_in_at >= ?", Date.parse(params[:from_date]).beginning_of_day)
    end
    if params[:to_date].present?
      @sessions = @sessions.where("logged_in_at <= ?", Date.parse(params[:to_date]).end_of_day)
    end
  end

  def calculate_stats
    @active_count = UserSession.active.count
    @online_users_count = UserSession.active.distinct.count(:user_id)
    @today_logins = UserSession.where("logged_in_at >= ?", Time.current.beginning_of_day).count
    @unique_users_today = UserSession.where("logged_in_at >= ?", Time.current.beginning_of_day).distinct.count(:user_id)
  end

  def logout_reason_label(reason)
    case reason
    when "user_initiated" then "사용자 로그아웃"
    when "session_expired" then "세션 만료"
    when "forced" then "강제 종료"
    when "admin_action" then "관리자 조치"
    else reason || "-"
    end
  end
  helper_method :logout_reason_label
end
