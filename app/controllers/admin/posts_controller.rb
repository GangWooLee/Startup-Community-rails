# frozen_string_literal: true

# 관리자 게시글 관리 컨트롤러
# 게시글 목록 조회, 필터링, 삭제, CSV 내보내기
class Admin::PostsController < Admin::BaseController
  before_action :set_post, only: [ :destroy ]

  # GET /admin/posts
  # 게시글 목록 + 필터링 + 페이지네이션
  def index
    @posts = Post.includes(:user).order(created_at: :desc)
    @posts = apply_filters(@posts)

    # 페이지네이션 (20개씩)
    @page = (params[:page] || 1).to_i
    @per_page = 20
    @total_count = @posts.count
    @total_pages = (@total_count.to_f / @per_page).ceil

    @posts = @posts.offset((@page - 1) * @per_page).limit(@per_page)

    # 통계 데이터
    calculate_stats
  end

  # DELETE /admin/posts/:id
  # 게시글 삭제 (외래키 참조 해제 후 삭제)
  def destroy
    ActiveRecord::Base.transaction do
      # 채팅방의 source_post_id 참조 해제 (외래 키 제약 우회)
      ChatRoom.where(source_post_id: @post.id).update_all(source_post_id: nil)

      # 주문의 post_id 참조 해제 (외래 키 제약 우회)
      Order.where(post_id: @post.id).update_all(post_id: nil)

      # 이제 게시글 삭제 (comments, notifications, reports는 dependent: :destroy로 처리됨)
      @post.destroy!
    end

    flash[:notice] = "게시글이 삭제되었습니다."
    redirect_to admin_posts_path(filter_params)
  rescue ActiveRecord::RecordNotDestroyed => e
    flash[:alert] = "게시글 삭제 실패: #{e.message}"
    redirect_to admin_posts_path(filter_params)
  end

  # GET /admin/posts/export.csv
  # 현재 필터가 적용된 게시글 목록을 CSV로 내보내기
  def export
    @posts = Post.includes(:user).order(created_at: :desc)
    @posts = apply_filters(@posts)

    columns = {
      id: "ID",
      title: "제목",
      category: ->(post) { category_label(post.category) },
      author: ->(post) { post.user&.name || "(삭제됨)" },
      views_count: "조회수",
      likes_count: "좋아요",
      comments_count: "댓글수",
      created_at: "작성일"
    }

    service = Admin::CsvExportService.new(@posts, columns: columns, filename_prefix: "posts")
    send_data service.generate, filename: service.filename, type: "text/csv; charset=utf-8"
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  # 필터 적용 (DRY: index와 export에서 공통 사용)
  def apply_filters(scope)
    # 카테고리 필터링
    if params[:category].present? && Post.categories.key?(params[:category])
      scope = scope.where(category: params[:category])
    end

    # 검색 기능: 제목 또는 작성자 이름으로 검색
    if params[:q].present?
      keyword = "%#{params[:q]}%"
      scope = scope.joins(:user).where("posts.title LIKE ? OR users.name LIKE ?", keyword, keyword)
    end

    # 날짜 범위 필터링 (안전한 파싱)
    from_date = parse_date_safely(params[:from_date])
    to_date = parse_date_safely(params[:to_date])
    scope = scope.where("posts.created_at >= ?", from_date.beginning_of_day) if from_date
    scope = scope.where("posts.created_at <= ?", to_date.end_of_day) if to_date

    scope
  end

  # 날짜 안전 파싱 (ArgumentError 방지)
  def parse_date_safely(date_string)
    return nil if date_string.blank?

    Date.parse(date_string)
  rescue ArgumentError
    flash.now[:alert] = "잘못된 날짜 형식입니다: #{date_string}"
    nil
  end

  # 필터 파라미터 유지
  def filter_params
    params.permit(:category, :q, :from_date, :to_date, :page).to_h.compact
  end

  # 카테고리 레이블
  def category_label(category)
    {
      "free" => "자유",
      "question" => "질문",
      "promotion" => "홍보",
      "hiring" => "구인",
      "seeking" => "구직"
    }[category] || category
  end

  # 통계 계산
  def calculate_stats
    @total_posts = Post.count
    @today_posts = Post.where("created_at >= ?", Time.current.beginning_of_day).count
    @category_counts = Post.group(:category).count
  end
end
