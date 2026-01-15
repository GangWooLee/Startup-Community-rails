# frozen_string_literal: true

# 활동 피드 관련 메서드
# User 모델에서 추출된 concern
# "Ruby Merge Pattern" - 여러 모델 데이터를 시간순 정렬
module ActivityFeedable
  extend ActiveSupport::Concern

  # 최근 활동 가져오기 (게시글 + 댓글을 시간순 정렬)
  def recent_activities(limit: 20)
    # 1. 각 모델에서 데이터 가져오기 (N+1 방지)
    last_posts = posts.published
                      .includes(:user, images_attachments: :blob)
                      .order(created_at: :desc)
                      .limit(limit)

    last_comments = comments.includes(:post, :user)
                            .order(created_at: :desc)
                            .limit(limit)

    # 2. 하나의 배열로 합치기
    activities = last_posts.to_a + last_comments.to_a

    # 3. 시간순 정렬 (최신순) 후 자르기
    activities.sort_by(&:created_at).reverse.first(limit)
  end
end
