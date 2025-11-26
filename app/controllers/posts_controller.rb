class PostsController < ApplicationController
  before_action :require_login, only: [:new, :create, :edit, :update, :destroy]

  def index
    # N+1 쿼리 방지를 위해 includes 사용
    @posts = Post.published
                 .includes(:user)
                 .recent
                 .limit(50)
  end

  def show
    @post = Post.includes(:user, comments: :user).find(params[:id])
    @post.increment_views!
  end

  def new
    @post = Post.new
  end

  def create
    @post = Post.new(post_params)
    @post.user = current_user
    @post.status = :published

    if @post.save
      redirect_to posts_path, notice: '게시글이 작성되었습니다.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @post = Post.find(params[:id])
  end

  def update
    @post = Post.find(params[:id])

    if @post.update(post_params)
      redirect_to post_path(@post), notice: '게시글이 수정되었습니다.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @post = Post.find(params[:id])
    @post.destroy
    redirect_to posts_path, notice: '게시글이 삭제되었습니다.'
  end

  private

  def post_params
    params.require(:post).permit(:title, :content)
  end
end
