class JobPostsController < ApplicationController
  def index
    # 기본 쿼리 체인 (공통 includes)
    base_query = Post.includes(:user, images_attachments: :blob).published

    # ===== Main Sections: Hiring (Makers) & Seeking (Projects) =====
    @hiring_posts = base_query.where(category: :hiring).recent.limit(POSTS_PER_PAGE)
    @seeking_posts = base_query.where(category: :seeking).recent.limit(POSTS_PER_PAGE)

    # ===== Featured Section: HOT 공고 (조회수 + 좋아요 기준 상위 2개) =====
    @featured_posts = base_query
                        .where(category: [ :hiring, :seeking ])
                        .order(Arel.sql("(views_count + likes_count * 3) DESC"))
                        .limit(2)

    # ===== Weekly Best: 최근 7일 인기 공고 (가로 스크롤용) =====
    @weekly_best = base_query
                     .where(category: [ :hiring, :seeking ])
                     .where("created_at > ?", 7.days.ago)
                     .order(views_count: :desc)
                     .limit(6)

    # ===== Sidebar Stats =====
    @hiring_count = Post.published.where(category: :hiring).count
    @seeking_count = Post.published.where(category: :seeking).count
    @today_count = Post.published
                       .where(category: [ :hiring, :seeking ])
                       .where("created_at > ?", Date.current.beginning_of_day)
                       .count

    # ===== Top Makers: 외주 글이 있는 활성 사용자 =====
    # 외주 글 작성자 중 최근 활동이 많은 사용자 5명
    @top_makers = User.joins(:posts)
                      .where(posts: { category: [ :hiring, :seeking ], status: :published })
                      .group("users.id")
                      .order("COUNT(posts.id) DESC, MAX(posts.created_at) DESC")
                      .limit(5)
  end
end
