class CommunityController < ApplicationController
  def index
    # Mock data for community posts
    @posts = [
      {
        id: "1",
        author: {
          id: "user1",
          name: "김창업",
          avatar: "/diverse-user-avatars.png",
          role: "CEO",
        },
        content: "스타트업 초기 팀 빌딩에서 가장 중요한 것은 비전 공유입니다. 저희는 매주 금요일 팀 회고를 통해 방향성을 맞추고 있습니다.",
        category: "팀 빌딩",
        likes: 42,
        comments: 12,
        created_at: "2시간 전",
      },
      {
        id: "2",
        author: {
          id: "user2",
          name: "이개발",
          avatar: "/developer-avatar.png",
          role: "CTO",
        },
        content: "MVP 개발 시 기술 스택 선택은 신중해야 합니다. 빠른 개발도 중요하지만 확장성도 고려해야 해요. Next.js + Supabase 조합 추천드립니다!",
        category: "개발",
        likes: 89,
        comments: 24,
        created_at: "5시간 전",
      },
      {
        id: "3",
        author: {
          id: "user3",
          name: "박마케터",
          avatar: "/marketer-avatar.jpg",
          role: "마케팅 리드",
        },
        content: "초기 스타트업의 마케팅 예산은 한정적입니다. 콘텐츠 마케팅과 입소문을 통한 성장이 가장 효과적이었습니다.",
        category: "마케팅",
        likes: 67,
        comments: 18,
        created_at: "1일 전",
      },
    ]
  end

  def show
    @post_id = params[:id]
    # TODO: Fetch post from database
  end

  def new
    @categories = ["팀 빌딩", "개발", "마케팅", "투자/펀딩", "법률/회계", "비즈니스 모델", "제품 개발", "기타"]
  end

  def create
    # TODO: Implement post creation logic
    redirect_to root_path
  end
end
