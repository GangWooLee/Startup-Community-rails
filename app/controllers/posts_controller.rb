class PostsController < ApplicationController
  before_action :require_login, only: [:new, :create, :edit, :update, :destroy]
  before_action :redirect_to_onboarding, only: [:index]
  before_action :set_post, only: [:show, :edit, :update, :destroy]
  before_action :authorize_post, only: [:edit, :update, :destroy]
  before_action :hide_floating_button, only: [:new, :edit, :show]

  def index
    # 커뮤니티 섹션: 커뮤니티 글만 표시 (free, question, promotion)
    # 구인/구직은 외주 섹션(/job_posts)에서 표시
    @posts = Post.published
                 .includes(:user)
                 .where(category: [:free, :question, :promotion])
                 .recent
                 .limit(POSTS_PER_PAGE)
  end

  def show
    @post.increment_views!
    # 최상위 댓글만 가져오고, 대댓글은 댓글 안에서 로드
    @comments = @post.comments.root_comments
                     .includes(:user, :likes, replies: [:user, :likes])
                     .oldest
  end

  def new
    @post = Post.new
    @initial_type = params[:type] || 'community'

    # 타입에 따른 기본 카테고리 설정
    if @initial_type == 'outsourcing'
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
      redirect_to posts_path, notice: '게시글이 작성되었습니다.'
    else
      @initial_type = @post.outsourcing? ? 'outsourcing' : 'community'
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @initial_type = @post.outsourcing? ? 'outsourcing' : 'community'
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

    if @post.update(permitted_params)
      redirect_to post_path(@post), notice: '게시글이 수정되었습니다.'
    else
      @initial_type = @post.outsourcing? ? 'outsourcing' : 'community'
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @post.destroy
    redirect_to posts_path, notice: '게시글이 삭제되었습니다.'
  end

  private

  def set_post
    @post = Post.includes(:user, comments: :user).find(params[:id])
  end

  def authorize_post
    unless @post.user == current_user
      redirect_to posts_path, alert: '권한이 없습니다.'
    end
  end

  def post_params
    params.require(:post).permit(
      :title, :content, :category,
      :service_type, :price, :work_period, :price_negotiable
    )
  end

  # 커뮤니티 카테고리인지 확인 (free, question, promotion)
  def community_category?(category)
    %w[free question promotion].include?(category.to_s)
  end

  # 비로그인 사용자를 온보딩으로 리디렉션
  # - 로그인 사용자: 커뮤니티 접근 허용
  # - 비로그인 + browse=true 파라미터: 둘러보기 모드 허용
  # - 비로그인 + 쿠키 있음: 이미 온보딩 경험함, 허용
  # - 비로그인 + 첫 방문: 온보딩으로 리디렉션
  def redirect_to_onboarding
    return if logged_in?
    return if params[:browse] == "true"
    return if cookies[:onboarding_completed].present?

    redirect_to root_path
  end
end
