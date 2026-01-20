# 관리자 대시보드 컨트롤러
# 서비스 전체 현황 통계 표시
class Admin::DashboardController < Admin::BaseController
  include Admin::PanelStats
  def index
    # 사용자 통계
    @total_users = User.count
    @today_users = User.where("created_at >= ?", Time.current.beginning_of_day).count
    @this_week_users = User.where("created_at >= ?", 1.week.ago).count

    # 채팅 통계
    @total_chat_rooms = ChatRoom.count
    @total_messages = Message.count
    @today_messages = Message.where("created_at >= ?", Time.current.beginning_of_day).count

    # 게시글 통계
    @total_posts = Post.count
    @today_posts = Post.where("created_at >= ?", Time.current.beginning_of_day).count

    # 신고/문의 통계
    @pending_reports = Report.pending.count
    @pending_inquiries = Inquiry.pending.count

    # 세션 통계 (실시간 활성 사용자)
    @active_sessions_count = UserSession.active.count
    @online_users_count = UserSession.active.distinct.count(:user_id)
    @today_login_count = UserSession.where("logged_in_at >= ?", Time.current.beginning_of_day).count
    @unique_users_today = UserSession.where("logged_in_at >= ?", Time.current.beginning_of_day).distinct.count(:user_id)

    # 최근 가입 사용자 (10명 - 테이블용)
    # N+1 방지: oauth_identities도 preload (뷰에서 oauth_user? 호출)
    @recent_users = User.includes(:chat_rooms, :oauth_identities).order(created_at: :desc).limit(10)

    # 최근 활동 채팅방 (5개)
    @recent_chat_rooms = ChatRoom.includes(:users).order(last_message_at: :desc).limit(5)

    # 오른쪽 패널용 통계
    calculate_panel_stats
  end

  private

  # 오른쪽 패널 통계 계산
  # Admin::PanelStats concern 활용
  def calculate_panel_stats
    return if @total_users.zero?

    # 회원 타입별 통계 (Concern 활용)
    stats = calculate_user_type_stats(@total_users)
    @admin_users_count = stats[:admin_count]
    @oauth_users_count = stats[:oauth_count]
    @regular_users_count = stats[:normal_count]
    @admin_percentage = stats[:admin_percentage]
    @oauth_percentage = stats[:oauth_percentage]
    @regular_percentage = stats[:normal_percentage]

    # 평균 통계 (대시보드 전용)
    @avg_chat_rooms_per_user = (@total_chat_rooms.to_f / @total_users).round(1)
    @avg_posts_per_user = (@total_posts.to_f / @total_users).round(1)
    @avg_messages_per_room = @total_chat_rooms.positive? ? (@total_messages.to_f / @total_chat_rooms).round(1) : 0

    # Top 활동 회원 (메시지 수 기준)
    @top_active_users = User.left_joins(:sent_messages)
                            .group(:id)
                            .select("users.*, COUNT(messages.id) as messages_count")
                            .order("messages_count DESC")
                            .limit(5)
  end
end
