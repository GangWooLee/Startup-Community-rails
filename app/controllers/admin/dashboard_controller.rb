# 관리자 대시보드 컨트롤러
# 서비스 전체 현황 통계 표시
class Admin::DashboardController < Admin::BaseController
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

    # 최근 가입 사용자 (10명 - 테이블용)
    @recent_users = User.includes(:chat_rooms).order(created_at: :desc).limit(10)

    # 최근 활동 채팅방 (5개)
    @recent_chat_rooms = ChatRoom.includes(:users).order(last_message_at: :desc).limit(5)

    # 오른쪽 패널용 통계
    calculate_panel_stats
  end

  private

  def calculate_panel_stats
    return if @total_users.zero?

    # 회원 타입별 비율
    @admin_users_count = User.where(is_admin: true).count
    @oauth_users_count = User.joins(:oauth_identities).distinct.count
    @regular_users_count = @total_users - @oauth_users_count

    @admin_percentage = ((@admin_users_count.to_f / @total_users) * 100).round(1)
    @oauth_percentage = ((@oauth_users_count.to_f / @total_users) * 100).round(1)
    @regular_percentage = (100 - @admin_percentage - @oauth_percentage).round(1)

    # 평균 통계
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
