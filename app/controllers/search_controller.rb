class SearchController < ApplicationController
  before_action :hide_floating_button

  def index
    @query = params[:q].to_s.strip

    if @query.present?
      # 사용자 검색 (이름, 역할, 소개에서 검색)
      @users = User.where(
        "name LIKE :query OR role_title LIKE :query OR bio LIKE :query",
        query: "%#{@query}%"
      ).limit(10)

      # 게시글 검색 (제목, 내용에서 검색)
      @posts = Post.published
                   .includes(:user, images_attachments: :blob)
                   .where("title LIKE :query OR content LIKE :query", query: "%#{@query}%")
                   .recent
                   .limit(20)
    else
      @users = []
      @posts = []
    end
  end
end
