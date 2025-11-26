class FreelanceController < ApplicationController
  def index
    # Mock data for job postings (구인)
    @job_postings = [
      {
        id: "j1",
        type: "job",
        title: "MVP 웹 개발자 구합니다",
        author: { id: "user1", name: "김창업" },
        category: "웹 개발",
        budget: "300-500만원",
        duration: "2개월",
        description: "SaaS 스타트업 MVP 개발을 도와주실 프론트엔드/백엔드 개발자를 찾습니다.",
        skills: ["React", "Node.js", "TypeScript"],
        posted_at: "1일 전",
      },
      {
        id: "j2",
        type: "job",
        title: "초기 스타트업 마케터 구인",
        author: { id: "user2", name: "박마케팅" },
        category: "마케팅",
        budget: "200-300만원",
        duration: "3개월",
        description: "퍼포먼스 마케팅 경험이 있으신 분을 찾습니다. 성과 기반 인센티브 제공 가능합니다.",
        skills: ["퍼포먼스 마케팅", "SNS 마케팅", "콘텐츠 제작"],
        posted_at: "2일 전",
      },
    ]

    # Mock data for talent postings (구직)
    @talent_postings = [
      {
        id: "t1",
        type: "talent",
        title: "프론트엔드 개발자입니다",
        author: { id: "user4", name: "최개발" },
        category: "개발",
        rate: "시간당 5만원",
        experience: "3년",
        description: "React, Next.js 전문 개발자입니다. 스타트업 MVP 개발 경험 다수 보유하고 있습니다.",
        skills: ["React", "Next.js", "TypeScript", "Tailwind CSS"],
        posted_at: "2일 전",
      },
      {
        id: "t2",
        type: "talent",
        title: "디지털 마케터입니다",
        author: { id: "user5", name: "정마케터" },
        category: "마케팅",
        rate: "월 200만원~",
        experience: "5년",
        description: "페이스북, 구글 광고 운영 전문가입니다. ROAS 300% 이상 달성 경험 있습니다.",
        skills: ["페이스북 광고", "구글 애즈", "GA4", "데이터 분석"],
        posted_at: "5일 전",
      },
    ]
  end

  def show_job
    @job_id = params[:id]
    # TODO: Fetch job from database
  end

  def show_talent
    @talent_id = params[:id]
    # TODO: Fetch talent from database
  end

  def new
    # TODO: Implement new freelance posting form
  end
end
