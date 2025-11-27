class JobPostsController < ApplicationController
  before_action :require_login, only: [:new, :create]

  def index
    # N+1 쿼리 방지를 위해 includes 사용
    @job_postings = JobPost.includes(:user)
                           .open_positions
                           .recent
                           .limit(50)

    @talent_postings = TalentListing.includes(:user)
                                    .available
                                    .recent
                                    .limit(50)
  end

  def show
    @job_post = JobPost.includes(:user).find(params[:id])
    @job_post.increment_views!
  end

  def new
    @job_post = JobPost.new
  end

  def create
    @job_post = JobPost.new(job_post_params)
    @job_post.user = current_user

    if @job_post.save
      redirect_to job_posts_path, notice: '구인 공고가 등록되었습니다.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def job_post_params
    params.require(:job_post).permit(:title, :description, :category, :project_type, :budget)
  end
end
