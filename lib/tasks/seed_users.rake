# frozen_string_literal: true

# 커뮤니티 시드 계정 관리 Rake Tasks
#
# 사용법:
#   SEED_PASSWORD=your_password bin/rails seed:users           # 15개 생성
#   SEED_PASSWORD=your_password bin/rails seed:users COUNT=20  # 20개 생성
#   bin/rails seed:list                                         # 시드 계정 목록
#   bin/rails seed:cleanup                                      # 시드 계정 삭제

namespace :seed do
  # 다양한 페르소나 데이터 (15개)
  # slug: 이메일 주소에 사용될 영문 식별자
  PERSONAS = [
    {
      slug: "startup-lover",
      nickname: "스타트업러버",
      name: "김창업",
      role: "창업자",
      affiliation: "푸드테크 스타트업",
      skills: "사업개발, 마케팅, 팀빌딩",
      bio: "음식을 사랑하는 창업자입니다. 배달 플랫폼에서 일하다가 직접 창업했어요. 함께 성장할 동료를 찾고 있습니다!"
    },
    {
      slug: "coding-master",
      nickname: "코딩마스터",
      name: "이개발",
      role: "백엔드 개발자",
      affiliation: "프리랜서",
      skills: "Ruby on Rails, Python, AWS, Docker",
      bio: "7년차 백엔드 개발자입니다. 스타트업 3곳을 거쳐 현재 프리랜서로 활동 중이에요. 기술 관련 질문 환영합니다!"
    },
    {
      slug: "design-hero",
      nickname: "디자인히어로",
      name: "박디자인",
      role: "UI/UX 디자이너",
      affiliation: "디자인 에이전시",
      skills: "Figma, 브랜딩, 프로토타이핑",
      bio: "사용자 경험에 진심인 디자이너입니다. 스타트업 제품 디자인을 주로 하고 있어요. 포트폴리오 피드백 드려요!"
    },
    {
      slug: "marketer-jin",
      nickname: "마케터진",
      name: "정마케팅",
      role: "그로스 마케터",
      affiliation: "이커머스 스타트업",
      skills: "퍼포먼스 마케팅, SNS, 데이터 분석",
      bio: "데이터 기반 마케팅을 좋아합니다. GA, 메타 광고 최적화 경험 많아요. 마케팅 고민 나눠요!"
    },
    {
      slug: "investor-learn",
      nickname: "투자러닝",
      name: "최투자",
      role: "VC 심사역",
      affiliation: "시드 투자사",
      skills: "투자 심사, 시장 분석, 재무 모델링",
      bio: "초기 스타트업 투자를 담당하고 있습니다. 피칭 팁, IR 자료 피드백 드릴 수 있어요. 편하게 연락주세요!"
    },
    {
      slug: "fullstack-dev",
      nickname: "개발새발",
      name: "한풀스택",
      role: "풀스택 개발자",
      affiliation: "1인 개발",
      skills: "React, Next.js, Node.js, MongoDB",
      bio: "사이드 프로젝트 덕후입니다. 혼자 MVP 만들고 런칭하는 걸 좋아해요. 개발 파트너 구합니다!"
    },
    {
      slug: "product-pm",
      nickname: "기획충",
      name: "서기획",
      role: "Product Manager",
      affiliation: "SaaS 스타트업",
      skills: "제품 기획, Jira, Notion, 애자일",
      bio: "3년차 PM입니다. B2B SaaS 제품을 만들고 있어요. 기획 문서 템플릿 공유해드려요!"
    },
    {
      slug: "data-analyst",
      nickname: "데이터맨",
      name: "윤데이터",
      role: "데이터 분석가",
      affiliation: "핀테크 스타트업",
      skills: "SQL, Python, Tableau, BigQuery",
      bio: "데이터로 인사이트를 찾는 걸 좋아합니다. 스타트업 데이터 분석 환경 구축 경험 있어요!"
    },
    {
      slug: "startup-mentor",
      nickname: "창업멘토",
      name: "강멘토",
      role: "창업 컨설턴트",
      affiliation: "액셀러레이터",
      skills: "멘토링, BM 설계, 투자 유치",
      bio: "10년간 스타트업 생태계에서 일했습니다. 창업 초기 고민 상담해드려요. 커피챗 환영!"
    },
    {
      slug: "legal-master",
      nickname: "법률마스터",
      name: "임변호사",
      role: "스타트업 전문 변호사",
      affiliation: "테크 로펌",
      skills: "계약서, 투자 계약, 스톡옵션, 노무",
      bio: "스타트업 법률 이슈 전문입니다. 자주 묻는 법률 질문 정리해서 올릴게요!"
    },
    {
      slug: "ai-researcher",
      nickname: "AI연구원",
      name: "송인공지능",
      role: "ML 엔지니어",
      affiliation: "AI 스타트업",
      skills: "PyTorch, LLM, MLOps, Python",
      bio: "AI 모델 개발하고 있습니다. LLM 활용 서비스에 관심 많아요. AI 기술 질문 환영!"
    },
    {
      slug: "content-queen",
      nickname: "콘텐츠퀸",
      name: "오콘텐츠",
      role: "콘텐츠 마케터",
      affiliation: "미디어 스타트업",
      skills: "브랜드 콘텐츠, 영상 제작, 카피라이팅",
      bio: "콘텐츠로 브랜드를 만듭니다. 유튜브, 인스타 마케팅 경험 많아요. 협업 제안 환영!"
    },
    {
      slug: "sales-king",
      nickname: "세일즈킹",
      name: "장영업",
      role: "B2B 세일즈",
      affiliation: "B2B SaaS",
      skills: "영업, CRM, 고객 성공, 제안서",
      bio: "B2B 영업 5년차입니다. 스타트업 세일즈 프로세스 구축 경험 공유해요!"
    },
    {
      slug: "hr-manager",
      nickname: "인사담당",
      name: "류피플",
      role: "HR 매니저",
      affiliation: "시리즈A 스타트업",
      skills: "채용, 조직문화, 평가 제도",
      bio: "스타트업 인사 담당입니다. 채용, 조직문화 관련 고민 나눠요!"
    },
    {
      slug: "finance-pro",
      nickname: "재무고수",
      name: "배재무",
      role: "CFO",
      affiliation: "시리즈A 스타트업",
      skills: "재무 관리, 투자 유치, 회계",
      bio: "스타트업 CFO로 일하고 있습니다. 재무제표, 투자 유치 준비 팁 공유해요!"
    }
  ].freeze

  SEED_EMAIL_DOMAIN = "@seed.community".freeze

  desc "시드 계정 생성 (SEED_PASSWORD 환경변수 필수, COUNT로 개수 조절)"
  task users: :environment do
    password = ENV.fetch("SEED_PASSWORD") { abort "❌ SEED_PASSWORD 환경변수가 필요합니다" }
    count = [ (ENV["COUNT"] || 15).to_i, PERSONAS.size ].min

    puts "🌱 시드 계정 #{count}개 생성 시작..."
    puts ""

    created = 0
    skipped = 0

    PERSONAS.first(count).each do |persona|
      email = "#{persona[:slug]}#{SEED_EMAIL_DOMAIN}"

      if User.exists?(email: email)
        puts "⏭️  이미 존재: #{persona[:nickname]} (#{email})"
        skipped += 1
        next
      end

      user = create_seed_user(persona, password)
      if user.persisted?
        puts "✅ 생성 완료: #{persona[:nickname]} (#{email})"
        created += 1
      else
        puts "❌ 생성 실패: #{persona[:nickname]}"
      end
    end

    puts ""
    puts "=" * 50
    puts "📊 결과: 생성 #{created}개, 건너뜀 #{skipped}개"
    puts "🔑 공통 비밀번호: [SEED_PASSWORD 환경변수 값]"
    puts "=" * 50
  end

  desc "시드 계정 목록 조회"
  task list: :environment do
    seed_users = User.where("email LIKE ?", "%#{SEED_EMAIL_DOMAIN}")

    if seed_users.any?
      puts "📋 시드 계정 목록 (#{seed_users.count}개):"
      puts ""
      seed_users.order(:created_at).each do |user|
        puts "  #{user.nickname || user.name}"
        puts "    📧 #{user.email}"
        puts "    💼 #{user.role_title} @ #{user.affiliation}"
        puts "    🕐 생성: #{user.created_at.strftime('%Y-%m-%d %H:%M')}"
        puts ""
      end
    else
      puts "❌ 시드 계정이 없습니다"
      puts "   생성: SEED_PASSWORD=your_password bin/rails seed:users"
    end
  end

  desc "시드 계정 전체 삭제"
  task cleanup: :environment do
    seed_users = User.where("email LIKE ?", "%#{SEED_EMAIL_DOMAIN}")

    if seed_users.empty?
      puts "❌ 삭제할 시드 계정이 없습니다"
      return
    end

    puts "⚠️  #{seed_users.count}개의 시드 계정을 삭제합니다"
    puts "   계속하려면 Enter, 취소하려면 Ctrl+C..."
    $stdin.gets

    count = seed_users.count
    seed_users.destroy_all

    puts "✅ #{count}개의 시드 계정이 삭제되었습니다"
  end

  private

  def create_seed_user(persona, password)
    now = Time.current
    email = "#{persona[:slug]}#{SEED_EMAIL_DOMAIN}"

    user = User.new(
      email: email,
      name: persona[:name],
      nickname: persona[:nickname],
      role_title: persona[:role],
      affiliation: persona[:affiliation],
      skills: persona[:skills],
      bio: persona[:bio],
      is_anonymous: true,
      profile_completed: true,
      # 약관 동의
      terms_accepted_at: now,
      privacy_accepted_at: now,
      guidelines_accepted_at: now,
      terms_version: "1.0"
    )

    user.password = password
    user.password_confirmation = password
    user.save!(validate: false)

    user
  end
end
