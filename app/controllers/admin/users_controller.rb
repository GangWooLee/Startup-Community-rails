# 관리자 회원 관리 컨트롤러
# 회원 검색, 상세 정보, 채팅방 목록 확인
class Admin::UsersController < Admin::BaseController
  include Admin::SudoMode

  before_action :set_user, only: [ :show, :chat_rooms, :destroy_post, :destroy_comment, :force_logout_all ]
  before_action :require_sudo, only: [ :destroy_post, :destroy_comment, :force_logout_all ]

  # GET /admin/users
  # 회원 목록 + 검색 + 필터링 기능
  # N+1 쿼리 방지: 서브쿼리로 posts_count, chat_rooms_count 조회
  def index
    @users = User.order(created_at: :desc)

    # 상태 필터링: active(활동 중) / withdrawn(탈퇴)
    case params[:status]
    when "active"
      @users = @users.active
    when "withdrawn"
      @users = @users.deleted
    end

    # 타입 필터링: admin / oauth
    case params[:type]
    when "admin"
      @users = @users.where(is_admin: true)
    when "oauth"
      @users = @users.joins(:oauth_identities).distinct
    end

    # 검색 기능: 이메일 또는 이름으로 검색
    if params[:q].present?
      keyword = "%#{params[:q]}%"
      @users = @users.where("email LIKE ? OR name LIKE ?", keyword, keyword)
    end

    # 날짜 범위 필터링
    if params[:from_date].present?
      @users = @users.where("created_at >= ?", Date.parse(params[:from_date]).beginning_of_day)
    end
    if params[:to_date].present?
      @users = @users.where("created_at <= ?", Date.parse(params[:to_date]).end_of_day)
    end

    # 페이지네이션 (20명씩) - count는 서브쿼리 추가 전에 계산
    @page = (params[:page] || 1).to_i
    @per_page = 20
    @total_count = @users.count
    @total_pages = (@total_count.to_f / @per_page).ceil

    # N+1 방지: oauth_identities preload + 서브쿼리로 posts_count, chat_rooms_count 조회
    @users = @users.includes(:oauth_identities).select(
      "users.*",
      "(SELECT COUNT(*) FROM posts WHERE posts.user_id = users.id) AS posts_count_value",
      "(SELECT COUNT(*) FROM chat_room_participants WHERE chat_room_participants.user_id = users.id) AS chat_rooms_count_value"
    ).offset((@page - 1) * @per_page).limit(@per_page)

    # 오른쪽 패널 통계 데이터
    calculate_panel_stats
  end

  # GET /admin/users/export.csv
  # 현재 필터가 적용된 회원 목록을 CSV로 내보내기
  def export
    @users = User.order(created_at: :desc)

    # 상태 필터링 (index와 동일한 로직)
    case params[:status]
    when "active"
      @users = @users.active
    when "withdrawn"
      @users = @users.deleted
    end

    # 타입 필터링
    case params[:type]
    when "admin"
      @users = @users.where(is_admin: true)
    when "oauth"
      @users = @users.joins(:oauth_identities).distinct
    end

    # 검색
    if params[:q].present?
      keyword = "%#{params[:q]}%"
      @users = @users.where("email LIKE ? OR name LIKE ?", keyword, keyword)
    end

    # 날짜 필터링
    if params[:from_date].present?
      @users = @users.where("created_at >= ?", Date.parse(params[:from_date]).beginning_of_day)
    end
    if params[:to_date].present?
      @users = @users.where("created_at <= ?", Date.parse(params[:to_date]).end_of_day)
    end

    # N+1 방지: 서브쿼리로 카운트 조회
    @users = @users.select(
      "users.*",
      "(SELECT COUNT(*) FROM posts WHERE posts.user_id = users.id) AS posts_count_value",
      "(SELECT COUNT(*) FROM chat_room_participants WHERE chat_room_participants.user_id = users.id) AS chat_rooms_count_value"
    )

    columns = {
      id: "ID",
      name: "이름",
      email: "이메일",
      created_at: "가입일",
      type: ->(user) { user_type_label(user) },
      status: ->(user) { user.deleted? ? "탈퇴" : "활동 중" },
      posts_count_value: "게시글 수",
      chat_rooms_count_value: "채팅방 수"
    }

    service = Admin::CsvExportService.new(@users, columns: columns, filename_prefix: "users")
    send_data service.generate, filename: service.filename, type: "text/csv; charset=utf-8"
  end

  # GET /admin/users/:id
  # 회원 상세 정보 + 참여 채팅방 목록 + 게시글/댓글
  def show
    # 이 사용자가 참여한 모든 채팅방 (N+1 방지)
    @chat_rooms = @user.chat_rooms
                       .includes(:users, :messages)
                       .order(last_message_at: :desc)

    # 사용자의 게시글 (최신순, 페이지네이션)
    @posts = @user.posts.order(created_at: :desc).page(params[:posts_page]).per(10)

    # 사용자의 댓글 (최신순, 게시글 정보 포함)
    @comments = @user.comments.includes(:post).order(created_at: :desc).page(params[:comments_page]).per(10)

    # 사용자 통계
    @posts_count = @user.posts.count
    @comments_count = @user.comments.count
    @messages_count = @user.sent_messages.count

    # 접속 기록 (최근 20개)
    @sessions = @user.session_history(limit: 20)
    @sessions_count = @user.user_sessions.count
    @active_sessions_count = @user.active_sessions.count

    # 탈퇴 회원인 경우 탈퇴 기록 로드
    @user_deletion = @user.last_deletion if @user.deleted?
  end

  # GET /admin/users/:id/chat_rooms
  # show 페이지로 리다이렉트 (채팅방 목록이 이미 show에 포함됨)
  def chat_rooms
    redirect_to admin_user_path(@user)
  end

  # DELETE /admin/users/:id/destroy_post
  # 관리자 권한으로 게시글 삭제
  # 외래 키 제약으로 인해 연관 레코드를 먼저 처리
  def destroy_post
    @post = @user.posts.find(params[:post_id])

    ActiveRecord::Base.transaction do
      # 감사 로그 기록 (삭제 전)
      audit_log(:delete_user_post, @post, "관리자 게시글 삭제", metadata: {
        post_title: @post.title.truncate(50),
        author: @user.name
      })

      # 채팅방의 source_post_id 참조 해제 (외래 키 제약 우회)
      ChatRoom.where(source_post_id: @post.id).update_all(source_post_id: nil)

      # 주문의 post_id 참조 해제 (외래 키 제약 우회)
      Order.where(post_id: @post.id).update_all(post_id: nil)

      # 이제 게시글 삭제 (comments, notifications, reports는 dependent: :destroy로 처리됨)
      @post.destroy!
    end

    flash[:notice] = "게시글이 삭제되었습니다."
    redirect_to admin_user_path(@user, anchor: "posts")
  rescue ActiveRecord::RecordNotDestroyed => e
    flash[:alert] = "게시글 삭제 실패: #{e.message}"
    redirect_to admin_user_path(@user, anchor: "posts")
  end

  # DELETE /admin/users/:id/destroy_comment
  # 관리자 권한으로 댓글 삭제
  def destroy_comment
    @comment = @user.comments.find(params[:comment_id])

    # 감사 로그 기록 (삭제 전)
    audit_log(:delete_user_comment, @comment, "관리자 댓글 삭제", metadata: {
      comment_content: @comment.content.truncate(50),
      author: @user.name
    })

    @comment.destroy

    flash[:notice] = "댓글이 삭제되었습니다."
    redirect_to admin_user_path(@user, anchor: "comments")
  end

  # POST /admin/users/:id/force_logout_all
  # 모든 활성 세션 강제 종료
  def force_logout_all
    count = @user.active_sessions.count

    if count > 0
      @user.end_all_sessions!(reason: "admin_action")

      # 감사 로그 기록
      audit_log(:force_logout_all_sessions, @user, "#{count}개 세션 강제 종료", metadata: {
        session_count: count,
        target_user: @user.email
      })

      flash[:notice] = "#{@user.name}님의 #{count}개 세션이 모두 종료되었습니다."
    else
      flash[:alert] = "활성 세션이 없습니다."
    end

    redirect_to admin_user_path(@user)
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  # 사용자 타입 레이블
  def user_type_label(user)
    if user.admin?
      "관리자"
    elsif user.oauth_user?
      "OAuth"
    else
      "일반"
    end
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
