# 관리자 회원 관리 컨트롤러
# 회원 검색, 상세 정보, 채팅방 목록 확인
class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [:show, :chat_rooms]

  # GET /admin/users
  # 회원 목록 + 검색 기능
  def index
    @users = User.order(created_at: :desc)

    # 검색 기능: 이메일 또는 이름으로 검색
    if params[:q].present?
      keyword = "%#{params[:q]}%"
      @users = @users.where("email LIKE ? OR name LIKE ?", keyword, keyword)
    end

    # 페이지네이션 (20명씩)
    @page = (params[:page] || 1).to_i
    @per_page = 20
    @total_count = @users.count
    @total_pages = (@total_count.to_f / @per_page).ceil
    @users = @users.offset((@page - 1) * @per_page).limit(@per_page)

    # 오른쪽 패널 통계 데이터
    calculate_panel_stats
  end

  # GET /admin/users/:id
  # 회원 상세 정보 + 참여 채팅방 목록
  def show
    # 이 사용자가 참여한 모든 채팅방 (N+1 방지)
    @chat_rooms = @user.chat_rooms
                       .includes(:users, :messages)
                       .order(last_message_at: :desc)

    # 사용자 통계
    @posts_count = @user.posts.count
    @comments_count = @user.comments.count
    @messages_count = @user.sent_messages.count
  end

  # GET /admin/users/:id/chat_rooms
  # show 페이지로 리다이렉트 (채팅방 목록이 이미 show에 포함됨)
  def chat_rooms
    redirect_to admin_user_path(@user)
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  # 오른쪽 패널 통계 계산
  def calculate_panel_stats
    total = User.count
    return if total.zero?

    # 회원 타입별 카운트
    admin_count = User.where(is_admin: true).count
    oauth_count = User.joins(:oauth_identities).distinct.count
    normal_count = total - admin_count - oauth_count

    # 퍼센티지 계산
    @admin_percentage = ((admin_count.to_f / total) * 100).round
    @oauth_percentage = ((oauth_count.to_f / total) * 100).round
    @normal_percentage = 100 - @admin_percentage - @oauth_percentage

    # 도넛 차트 계산 (원 둘레 = 2 * π * r = 2 * 3.14159 * 40 ≈ 251.2)
    circumference = 251.2
    @normal_dash = ((@normal_percentage / 100.0) * circumference).round(1)
    @oauth_dash = ((@oauth_percentage / 100.0) * circumference).round(1)
    @admin_dash = ((@admin_percentage / 100.0) * circumference).round(1)
    @oauth_offset = -@normal_dash
    @admin_offset = -(@normal_dash + @oauth_dash)
  end
end
