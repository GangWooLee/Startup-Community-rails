class JobPostsController < ApplicationController
  def index
    # Post 모델의 외주 카테고리(hiring, seeking) 글을 조회
    @hiring_posts = Post.includes(:user, images_attachments: :blob)
                        .published
                        .where(category: :hiring)
                        .recent
                        .limit(POSTS_PER_PAGE)

    @seeking_posts = Post.includes(:user, images_attachments: :blob)
                         .published
                         .where(category: :seeking)
                         .recent
                         .limit(POSTS_PER_PAGE)
  end
end
