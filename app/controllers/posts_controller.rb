class PostsController < ApplicationController
  before_action :require_login, only: [ :new, :create, :edit, :update, :destroy, :remove_image ]
  before_action :redirect_to_onboarding, only: [ :index ]
  before_action :set_post, only: [ :show, :edit, :update, :destroy, :remove_image ]
  before_action :authorize_post, only: [ :edit, :update, :destroy, :remove_image ]
  before_action :hide_floating_button, only: [ :new, :edit, :show ]

  def index
    # browse=true로 접근 시 세션에 브라우징 상태 저장 (사이드바 네비게이션 허용)
    session[:browsing_community] = true if params[:browse] == "true"

    # 커뮤니티 섹션: 커뮤니티 글만 표시 (free, question, promotion)
    # 구인/구직은 외주 섹션(/job_posts)에서 표시
    @page = [ params[:page].to_i, 1 ].max
    @per_page = POSTS_PER_PAGE

    base_query = Post.published
                     .includes(user: { avatar_attachment: :blob }, images_attachments: :blob)
                     .where(category: filter_categories)

    # 정렬 방식 적용
    base_query = if params[:sort] == "popular"
                   base_query.popular
    else
                   base_query.recent
    end

    # 전체 개수 확인 (다음 페이지 존재 여부)
    @total_count = base_query.count
    @has_more = (@page * @per_page) < @total_count

    # 페이지네이션 적용
    @posts = base_query.offset((@page - 1) * @per_page).limit(@per_page)

    # 현재 정렬 상태 (뷰에서 사용)
    @current_sort = params[:sort]&.to_sym || :recent

    # Turbo Stream 요청인 경우 (더 보기 버튼 클릭)
    respond_to do |format|
      format.html # 기본 렌더링
      format.turbo_stream do
        render turbo_stream: [
          # 새 게시글들을 목록 끝에 추가
          turbo_stream.append("posts-list", partial: "posts/medium_post_rows", locals: { posts: @posts }),
          # 더 보기 버튼 업데이트
          turbo_stream.replace("load-more-section", partial: "posts/load_more_button", locals: {
            page: @page,
            has_more: @has_more,
            category: params[:category],
            sort: params[:sort]
          })
        ]
      end
    end
  end

  def show
    @post.record_view(current_user)  # 로그인 사용자만, 중복/본인 제외
    # 최상위 댓글만 가져오고, 대댓글은 댓글 안에서 로드
    @comments = @post.comments.root_comments
                     .includes({ user: { avatar_attachment: :blob } },
                              :likes,
                              { replies: [ { user: { avatar_attachment: :blob } }, :likes ] })
                     .oldest

    # 외주 글일 경우 비슷한 프로젝트 쿼리 + GA4 이벤트
    if @post.outsourcing?
      # GA4 외주 공고 조회 이벤트
      track_ga4_event("job_post_view", {
        post_id: @post.id,
        category: @post.category
      })
      @similar_posts = Post.published
                           .includes(user: { avatar_attachment: :blob }, images_attachments: :blob)
                           .where(category: @post.category)
                           .where.not(id: @post.id)

      # 서비스 타입이 같은 것 우선, 없으면 같은 카테고리
      if @post.service_type.present?
        # 안전한 방식: sanitize로 SQL injection 방지
        sanitized_type = ActiveRecord::Base.connection.quote(@post.service_type)
        @similar_posts = @similar_posts
                           .order(Arel.sql("CASE WHEN service_type = #{sanitized_type} THEN 0 ELSE 1 END"))
                           .recent
                           .limit(3)
      else
        @similar_posts = @similar_posts.recent.limit(3)
      end
    end
  end

  def new
    @post = Post.new
    @initial_type = params[:type] || "community"

    # 타입에 따른 기본 카테고리 설정
    if @initial_type == "outsourcing"
      @post.category = :hiring
    else
      @post.category = :free
    end
  end

  def create
    @post = Post.new(post_params)
    @post.user = current_user
    @post.status = :published

    # 커뮤니티 글인 경우 외주 필드 초기화
    if @post.community?
      @post.service_type = nil
      @post.price = nil
      @post.work_period = nil
      @post.price_negotiable = false
    end

    if @post.save
      # GA4 게시글 작성 이벤트
      track_ga4_event("post_create", {
        category: @post.category,
        post_type: @post.outsourcing? ? "outsourcing" : "community"
      })

      # 카테고리에 따라 적절한 페이지로 리다이렉트
      if @post.outsourcing?
        redirect_to job_posts_path, notice: "게시글이 작성되었습니다."
      else
        redirect_to community_path, notice: "게시글이 작성되었습니다."
      end
    else
      @initial_type = @post.outsourcing? ? "outsourcing" : "community"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @initial_type = @post.outsourcing? ? "outsourcing" : "community"
  end

  def update
    permitted_params = post_params.to_h

    # 커뮤니티 글인 경우 외주 필드 초기화
    if community_category?(permitted_params[:category])
      permitted_params[:service_type] = nil
      permitted_params[:price] = nil
      permitted_params[:work_period] = nil
      permitted_params[:price_negotiable] = false
    end

    # 이미지를 별도로 추출 (update 성공 후에만 첨부)
    # validation 실패 시 unsaved attachment로 인한 signed_id 에러 방지
    new_images = permitted_params.delete(:images)

    if @post.update(permitted_params)
      # update 성공 시에만 새 이미지 첨부
      @post.images.attach(new_images) if new_images.present?
      redirect_to post_path(@post), notice: "게시글이 수정되었습니다."
    else
      @initial_type = @post.outsourcing? ? "outsourcing" : "community"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @post.destroy
    redirect_to posts_path, notice: "게시글이 삭제되었습니다."
  end

  def remove_image
    # Active Storage attachment를 ID로 찾기
    attachment = @post.images.attachments.find_by(id: params[:image_id])
    if attachment
      attachment.purge
      @post.reload # 이미지 카운트 갱신
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.remove("image-#{params[:image_id]}"),
            turbo_stream.update("image-counter", "#{@post.images.count}/5")
          ]
        end
        format.html { redirect_to edit_post_path(@post), notice: "이미지가 삭제되었습니다." }
      end
    else
      respond_to do |format|
        format.turbo_stream { head :not_found }
        format.html { redirect_to edit_post_path(@post), alert: "이미지를 찾을 수 없습니다." }
      end
    end
  end

  private

  def set_post
    # comments는 show 액션에서 별도로 로드 (replies, likes 포함)
    @post = Post.includes(:user).find(params[:id])
  end

  def authorize_post
    unless @post.user == current_user
      redirect_to posts_path, alert: "권한이 없습니다."
    end
  end

  def post_params
    params.require(:post).permit(
      :title, :content, :category,
      :service_type, :price, :work_period, :price_negotiable,
      :skills, :work_type, :portfolio_url, :available_now, :experience,
      images: []
    )
  end

  # 커뮤니티 카테고리인지 확인 (free, question, promotion)
  def community_category?(category)
    %w[free question promotion].include?(category.to_s)
  end

  # 필터링할 카테고리 결정
  # params[:category]가 있으면 해당 카테고리만, 없으면 전체 커뮤니티 카테고리
  def filter_categories
    if params[:category].present? && community_category?(params[:category])
      params[:category]
    else
      %i[free question promotion]
    end
  end

  # 비로그인 사용자를 온보딩으로 리디렉션
  # - 로그인 사용자: 커뮤니티 접근 허용
  # - 비로그인 + browse=true 파라미터: 둘러보기 모드 허용
  # - 비로그인 + 쿠키 있음: 이미 온보딩 경험함, 허용
  # - 비로그인 + Turbo Stream 요청: 더 보기 버튼 허용
  # - 비로그인 + 첫 방문: 온보딩으로 리디렉션
  def redirect_to_onboarding
    return if logged_in?
    return if params[:browse] == "true"
    return if session[:browsing_community]
    return if cookies[:onboarding_completed].present?
    return if request.format.turbo_stream?

    redirect_to root_path
  end
end
