class ProfilesController < ApplicationController
  def show
    @user_id = params[:id]
    @is_own_profile = false # In real app, check if current user matches profile ID

    # Mock data for user profile
    @user_profile = {
      id: "user1",
      name: "김창업",
      avatar: "/diverse-user-avatars.png",
      role: "CEO",
      company: "스타트업 A",
      bio: "Zero to One을 만들어가는 창업자입니다. 3년차 스타트업을 운영하고 있으며, B2B SaaS 제품 개발에 집중하고 있습니다.",
      location: "서울, 한국",
      email: "kim@startup-a.com",
      website: "https://startup-a.com",
      skills: ["제품 기획", "팀 빌딩", "비즈니스 전략", "투자 유치"],
      posts: [
        {
          id: "1",
          content: "스타트업 초기 팀 빌딩에서 가장 중요한 것은 비전 공유입니다. 저희는 매주 금요일 팀 회고를 통해 방향성을 맞추고 있습니다.",
          category: "팀 빌딩",
          likes: 42,
          comments: 12,
          created_at: "2시간 전",
        },
        {
          id: "4",
          content: "초기 투자 유치 시 가장 중요한 것은 트랙션입니다. 아이디어만으로는 투자자를 설득하기 어렵습니다.",
          category: "투자/펀딩",
          likes: 28,
          comments: 8,
          created_at: "1주일 전",
        },
      ],
      job_postings: [
        {
          id: "j1",
          type: "job",
          title: "풀스택 개발자 구합니다",
          category: "개발",
          budget: "300-500만원",
          duration: "3개월",
          skills: ["Next.js", "Node.js", "TypeScript", "PostgreSQL"],
          posted_at: "1일 전",
        },
      ],
      talent_postings: [],
    }
  end
end
