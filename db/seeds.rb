# db/seeds.rb
# 스타트업 커뮤니티 종합 시드 데이터
# 모든 기능을 검증할 수 있는 다양한 시나리오의 데이터 생성

if Rails.env.development?
  puts "🌱 Starting comprehensive seed process..."
  puts "=" * 60

  # 기존 데이터 삭제 (순서 중요: 외래키 제약)
  [
    Notification, Message, ChatRoomParticipant, ChatRoom,
    Bookmark, Like, Comment, Post, JobPost, TalentListing,
    OauthIdentity, User
  ].each do |model|
    model.destroy_all
    puts "  ✓ Cleared #{model.name} table"
  end

  puts "\n" + "=" * 60
  puts "📝 Creating Users..."
  puts "=" * 60

  test_password = 'test1234'

  # ========================================
  # 1. 사용자 생성 (다양한 프로필)
  # ========================================

  # 관리자
  admin = User.create!(
    email: 'admin@startup.com',
    password: test_password,
    password_confirmation: test_password,
    name: '관리자',
    role_title: 'Platform Admin',
    bio: '스타트업 커뮤니티 관리자입니다. 문의사항은 편하게 연락주세요.',
    affiliation: 'Startup Community',
    skills: 'Community Management, User Support'
  )
  puts "  ✅ Admin: #{admin.email}"

  # 다양한 역할의 테스트 사용자들
  user_data = [
    {
      email: 'founder@startup.com',
      name: '김창업',
      role_title: 'Founder & CEO',
      bio: '시리즈 A 스타트업 대표입니다. EdTech 분야에서 혁신을 만들고 있습니다. 팀원을 구하고 있어요!',
      affiliation: '에듀테크 스타트업',
      skills: 'Business Development, Fundraising, Team Building',
      availability_statuses: ['hiring'],
      github_url: 'https://github.com/example',
      portfolio_url: 'https://notion.so/portfolio'
    },
    {
      email: 'developer@startup.com',
      name: '이개발',
      role_title: 'Full-Stack Developer',
      bio: '5년차 풀스택 개발자입니다. Rails, React, AWS 경험 있습니다. 사이드 프로젝트 환영합니다.',
      affiliation: '프리랜서',
      skills: 'Ruby on Rails, React, TypeScript, AWS, Docker',
      availability_statuses: ['available_for_work'],
      github_url: 'https://github.com/devlee',
      portfolio_url: 'https://devlee.dev'
    },
    {
      email: 'designer@startup.com',
      name: '박디자인',
      role_title: 'Product Designer',
      bio: 'UI/UX 디자이너 4년차입니다. 스타트업과의 협업을 좋아합니다. Figma 마스터!',
      affiliation: 'Design Agency',
      skills: 'Figma, UI/UX Design, Design System, Prototyping',
      availability_statuses: ['available_for_work'],
      portfolio_url: 'https://behance.net/parkdesign'
    },
    {
      email: 'pm@startup.com',
      name: '최기획',
      role_title: 'Product Manager',
      bio: 'IT 대기업 출신 PM입니다. 현재 창업 준비 중이며 공동창업자를 찾고 있습니다.',
      affiliation: '창업 준비 중',
      skills: 'Product Management, Agile, Data Analysis, User Research',
      availability_statuses: ['hiring'],
      custom_status: '공동창업자 모집'
    },
    {
      email: 'marketer@startup.com',
      name: '정마케팅',
      role_title: 'Growth Marketer',
      bio: '그로스 마케터입니다. 퍼포먼스 마케팅, SEO, 콘텐츠 마케팅 경험 다수.',
      affiliation: '마케팅 컨설팅',
      skills: 'Google Ads, Facebook Ads, SEO, Content Marketing',
      availability_statuses: ['available_for_work'],
      open_chat_url: 'https://open.kakao.com/o/example'
    },
    {
      email: 'student@startup.com',
      name: '홍대학생',
      role_title: 'Computer Science Student',
      bio: '컴공 4학년입니다. 졸업 전 스타트업 경험을 쌓고 싶습니다.',
      affiliation: '서울대학교',
      skills: 'Python, JavaScript, Machine Learning',
      custom_status: '인턴 구직 중'
    },
    {
      email: 'investor@startup.com',
      name: '강투자',
      role_title: 'Angel Investor',
      bio: '전직 창업자, 현재는 엔젤 투자자입니다. 좋은 팀을 만나고 싶습니다.',
      affiliation: 'Angel Investment Club',
      skills: 'Investment, Mentoring, Networking'
    },
    {
      email: 'junior@startup.com',
      name: '신주니어',
      role_title: 'Junior Developer',
      bio: '개발 1년차 주니어입니다. 배움에 열정적이고 성장하고 싶습니다!',
      affiliation: 'Tech Company',
      skills: 'JavaScript, React, Node.js',
      availability_statuses: ['available_for_work']
    },
    {
      email: 'video@startup.com',
      name: '유영상',
      role_title: 'Video Creator',
      bio: '유튜브 10만 구독자 크리에이터입니다. 스타트업 홍보 영상 제작 가능합니다.',
      affiliation: 'Freelancer',
      skills: 'Premiere Pro, After Effects, YouTube',
      availability_statuses: ['available_for_work'],
      portfolio_url: 'https://youtube.com/@example'
    },
    {
      email: 'data@startup.com',
      name: '오데이터',
      role_title: 'Data Scientist',
      bio: '데이터 사이언티스트 3년차입니다. ML/DL 프로젝트 경험 다수.',
      affiliation: 'AI Startup',
      skills: 'Python, TensorFlow, SQL, Data Visualization',
      github_url: 'https://github.com/datao'
    }
  ]

  users = user_data.map do |data|
    user = User.create!(
      email: data[:email],
      password: test_password,
      password_confirmation: test_password,
      name: data[:name],
      role_title: data[:role_title],
      bio: data[:bio],
      affiliation: data[:affiliation],
      skills: data[:skills],
      availability_statuses: data[:availability_statuses] || [],
      custom_status: data[:custom_status],
      github_url: data[:github_url],
      portfolio_url: data[:portfolio_url],
      open_chat_url: data[:open_chat_url]
    )
    puts "  ✅ User: #{user.email} (#{user.role_title})"
    user
  end

  # 편의를 위한 변수 할당
  founder, developer, designer, pm, marketer, student, investor, junior, video, data_scientist = users

  puts "\n" + "=" * 60
  puts "📝 Creating Community Posts..."
  puts "=" * 60

  # ========================================
  # 2. 커뮤니티 게시글 (자유/질문/홍보)
  # ========================================

  community_posts = [
    # 자유 게시판
    {
      user: founder,
      title: '창업 3년차, 드디어 시리즈 A 투자 유치했습니다!',
      content: "안녕하세요, 에듀테크 스타트업을 운영하는 김창업입니다.\n\n3년간의 여정 끝에 드디어 시리즈 A 투자를 유치하게 되었습니다. 정말 감개무량하네요.\n\n## 투자 유치 과정\n\n1. **시드 투자** (2022): 5억원\n2. **프리 시리즈 A** (2023): 15억원\n3. **시리즈 A** (2024): 50억원\n\n## 배운 점들\n\n- IR 자료는 스토리가 중요합니다\n- 투자자 미팅은 최소 50회 이상 각오하세요\n- 팀이 가장 중요합니다\n\n궁금한 점 있으시면 댓글 남겨주세요!",
      category: :free,
      views_count: 324
    },
    {
      user: developer,
      title: '주니어 개발자분들께 드리는 조언',
      content: "5년차 개발자로서 주니어분들께 드리고 싶은 조언입니다.\n\n## 기술 스택\n\n언어 하나를 깊게 파세요. 저는 Ruby를 선택했고, 지금도 만족합니다.\n\n## 사이드 프로젝트\n\n무조건 하세요. 실무에서 배우지 못하는 것들을 경험할 수 있습니다.\n\n## 커뮤니티 활동\n\n개발자 커뮤니티에 적극 참여하세요. 인맥도 쌓이고 정보도 얻을 수 있습니다.\n\n화이팅입니다! 💪",
      category: :free,
      views_count: 256
    },
    {
      user: designer,
      title: '디자이너의 스타트업 적응기',
      content: "대기업 디자이너에서 스타트업으로 이직한 지 1년이 되었습니다.\n\n## 달라진 점\n\n- **속도**: 모든 것이 빠르게 진행됩니다\n- **범위**: UI뿐 아니라 UX, 브랜딩까지 담당\n- **소통**: 개발자, PM과 긴밀하게 협업\n\n## 좋은 점\n\n- 내 의견이 바로 반영되는 것\n- 성장하는 제품을 직접 만드는 느낌\n- 자유로운 분위기\n\n스타트업 이직 고민하시는 분들, 추천드립니다!",
      category: :free,
      views_count: 189
    },
    # 질문 게시판
    {
      user: student,
      title: '스타트업 인턴 경험 어떻게 쌓을 수 있을까요?',
      content: "안녕하세요, 컴공 4학년 대학생입니다.\n\n졸업 전에 스타트업 경험을 쌓고 싶은데, 어떻게 시작해야 할지 모르겠습니다.\n\n## 궁금한 점\n\n1. 스타트업 인턴은 어디서 구하나요?\n2. 포트폴리오가 없어도 지원 가능할까요?\n3. 학교 수업과 병행 가능한가요?\n\n경험 있으신 분들 조언 부탁드립니다! 🙏",
      category: :question,
      views_count: 145
    },
    {
      user: junior,
      title: 'React vs Vue, 어떤 것을 더 깊게 공부해야 할까요?',
      content: "1년차 주니어 개발자입니다.\n\n현재 회사에서는 React를 사용하고 있는데, Vue도 배워두면 좋을 것 같습니다.\n\n## 현재 상황\n\n- React 6개월 경험\n- Vue는 튜토리얼만 해봄\n- 이직 고려 중\n\n시장 상황이나 트렌드 측면에서 어떤 것에 집중하면 좋을까요?",
      category: :question,
      views_count: 203
    },
    {
      user: pm,
      title: 'MVP 개발 기간 어느 정도가 적정할까요?',
      content: "창업 준비 중인 PM입니다.\n\n## 상황\n\n- B2B SaaS 제품 기획 중\n- 핵심 기능 5개 정도\n- 개발자 1-2명 예상\n\n## 질문\n\n1. MVP 개발 기간을 어떻게 잡아야 할까요?\n2. 외주 vs 정직원 채용 어떤 게 좋을까요?\n3. 노코드 툴로 MVP 만드는 건 어떨까요?\n\n경험담 공유해주시면 감사하겠습니다!",
      category: :question,
      views_count: 178
    },
    # 홍보 게시판
    {
      user: marketer,
      title: '[무료 웨비나] 스타트업을 위한 그로스 마케팅 전략',
      content: "안녕하세요, 그로스 마케터 정마케팅입니다.\n\n스타트업 초기에 유용한 마케팅 전략을 공유하는 무료 웨비나를 진행합니다.\n\n## 웨비나 정보\n\n- **일시**: 다음 주 토요일 오후 2시\n- **장소**: 온라인 (Zoom)\n- **정원**: 50명\n\n## 다룰 내용\n\n1. 제로 예산 마케팅 전략\n2. SEO 기초부터 실전까지\n3. 콘텐츠 마케팅 성공 사례\n\n관심 있으신 분들은 댓글 남겨주세요!",
      category: :promotion,
      views_count: 134
    },
    {
      user: video,
      title: '[포트폴리오] 스타트업 홍보 영상 제작 레퍼런스',
      content: "안녕하세요, 영상 크리에이터 유영상입니다.\n\n지금까지 제작한 스타트업 홍보 영상 레퍼런스를 공유드립니다.\n\n## 제작 영상 유형\n\n1. **서비스 소개 영상**: 30초~1분\n2. **회사 소개 영상**: 2-3분\n3. **IR 피칭 영상**: 3-5분\n4. **유튜브 광고**: 15초/30초\n\n## 포트폴리오\n\n유튜브 채널에서 확인하실 수 있습니다.\n\n문의는 DM이나 채팅으로 연락주세요!",
      category: :promotion,
      views_count: 98
    }
  ]

  created_community_posts = community_posts.map do |post_data|
    post = Post.create!(
      user: post_data[:user],
      title: post_data[:title],
      content: post_data[:content],
      category: post_data[:category],
      status: :published,
      views_count: post_data[:views_count] || rand(50..200)
    )
    puts "  ✅ [#{post.category_label}] #{post.title.truncate(40)}"
    post
  end

  puts "\n" + "=" * 60
  puts "📝 Creating Outsourcing Posts (구인/구직)..."
  puts "=" * 60

  # ========================================
  # 3. 외주 게시글 (구인/구직)
  # ========================================

  outsourcing_posts = [
    # 구인 (Hiring)
    {
      user: founder,
      title: '[구인] React 프론트엔드 개발자 (3개월 프로젝트)',
      content: "에듀테크 스타트업에서 신규 서비스 개발을 위한 프론트엔드 개발자를 찾습니다.\n\n## 프로젝트 개요\n\n학습 관리 시스템(LMS) 신규 기능 개발\n\n## 기술 스택\n\n- React, TypeScript\n- Tailwind CSS\n- REST API 연동\n\n## 우대사항\n\n- 스타트업 경험\n- 교육 서비스 개발 경험\n\n## 근무 조건\n\n- 재택 근무 가능\n- 주 5일, 하루 8시간\n\n관심 있으신 분은 포트폴리오와 함께 연락주세요!",
      category: :hiring,
      service_type: 'development',
      work_type: 'remote',
      price: 8000000,
      work_period: '3개월',
      views_count: 156
    },
    {
      user: pm,
      title: '[구인] UI/UX 디자이너 (MVP 디자인)',
      content: "새로운 B2B SaaS 제품의 MVP 디자인을 맡아주실 디자이너를 찾습니다.\n\n## 작업 범위\n\n1. 와이어프레임 설계\n2. UI 디자인 (5개 핵심 화면)\n3. 프로토타입 제작\n\n## 요구사항\n\n- Figma 사용 가능\n- SaaS 제품 디자인 경험\n- 심플하고 직관적인 디자인 선호\n\n## 기간 및 예산\n\n- 기간: 4주\n- 예산: 협의 (300-500만원 예상)\n\n포트폴리오 보내주시면 검토 후 연락드리겠습니다!",
      category: :hiring,
      service_type: 'design',
      work_type: 'remote',
      price: 4000000,
      price_negotiable: true,
      work_period: '4주',
      views_count: 134
    },
    {
      user: investor,
      title: '[구인] 투자 포트폴리오사 홍보 영상 제작',
      content: "포트폴리오사 소개 영상을 제작해주실 영상 크리에이터를 찾습니다.\n\n## 프로젝트 개요\n\n5개 스타트업의 짧은 소개 영상 (각 1분)\n\n## 요구사항\n\n- 세련된 모션그래픽\n- 인터뷰 촬영 및 편집\n- BGM 및 자막 포함\n\n## 예산\n\n- 영상당 100만원 (총 500만원)\n- 추가 영상 작업 가능\n\n포트폴리오 보내주세요!",
      category: :hiring,
      service_type: 'video',
      work_type: 'hybrid',
      price: 5000000,
      work_period: '2개월',
      views_count: 87
    },
    {
      user: founder,
      title: '[구인] 콘텐츠 마케터 (파트타임)',
      content: "스타트업 블로그 및 SNS 운영을 맡아주실 콘텐츠 마케터를 찾습니다.\n\n## 업무 내용\n\n- 블로그 포스팅 (주 2회)\n- 인스타그램/링크드인 콘텐츠\n- 뉴스레터 작성 (월 2회)\n\n## 요구사항\n\n- B2B 콘텐츠 작성 경험\n- EdTech/교육 분야 이해\n- SEO 기초 지식\n\n## 조건\n\n- 재택 근무\n- 주 20시간 내외\n- 월 150만원\n\n레퍼런스와 함께 지원해주세요!",
      category: :hiring,
      service_type: 'marketing',
      work_type: 'remote',
      price: 1500000,
      work_period: '6개월+',
      views_count: 112
    },
    # 구직 (Seeking)
    {
      user: developer,
      title: '[구직] 풀스택 개발자 (Rails + React)',
      content: "5년차 풀스택 개발자입니다. 스타트업 프로젝트에 참여하고 싶습니다.\n\n## 기술 스택\n\n### Backend\n- Ruby on Rails (4년)\n- Node.js/Express (2년)\n- PostgreSQL, Redis\n\n### Frontend\n- React, TypeScript (3년)\n- Tailwind CSS\n- Next.js\n\n### DevOps\n- AWS (EC2, RDS, S3, Lambda)\n- Docker, GitHub Actions\n\n## 경력\n\n- 핀테크 스타트업 (2년)\n- SI 회사 (2년)\n- 프리랜서 (1년)\n\n## 가능 조건\n\n- 원격 근무 선호\n- 풀타임/파트타임 모두 가능\n- 시급: 협의\n\n포트폴리오: [GitHub 링크]",
      category: :seeking,
      service_type: 'development',
      work_type: 'remote',
      price: 70000,
      available_now: true,
      portfolio_url: 'https://github.com/devlee',
      views_count: 198
    },
    {
      user: designer,
      title: '[구직] UI/UX 디자이너 (4년 경력)',
      content: "제품 디자이너 4년차입니다. 스타트업과 함께 성장하고 싶습니다.\n\n## 전문 분야\n\n- 모바일 앱 UI/UX\n- 웹 서비스 디자인\n- 디자인 시스템 구축\n\n## 사용 툴\n\n- Figma (메인)\n- Adobe XD, Sketch\n- Protopie, Principle\n- Adobe Illustrator\n\n## 주요 프로젝트\n\n1. 금융 앱 리뉴얼 (50만 DAU)\n2. 이커머스 웹사이트 전면 개편\n3. SaaS 대시보드 디자인\n\n## 가능 조건\n\n- 풀타임/파트타임 모두 가능\n- 재택 근무 선호\n- 단기/장기 프로젝트 모두 환영\n\nBehance 포트폴리오 확인해주세요!",
      category: :seeking,
      service_type: 'design',
      work_type: 'remote',
      price: 60000,
      available_now: true,
      portfolio_url: 'https://behance.net/parkdesign',
      views_count: 167
    },
    {
      user: marketer,
      title: '[구직] 그로스 마케터 (퍼포먼스 마케팅 전문)',
      content: "그로스 마케팅 전문가입니다. 스타트업의 성장을 함께 하겠습니다.\n\n## 전문 분야\n\n- 퍼포먼스 마케팅 (Google, Meta, Naver)\n- SEO/ASO 최적화\n- CRM/리텐션 마케팅\n- 데이터 분석 (GA4, Amplitude)\n\n## 주요 성과\n\n- CAC 40% 절감 (핀테크 스타트업)\n- MAU 300% 성장 (이커머스)\n- 앱 설치 단가 50% 개선\n\n## 가능 업무\n\n- 마케팅 전략 수립\n- 광고 세팅 및 운영\n- 성과 분석 리포팅\n- 마케팅 자동화 구축\n\n## 조건\n\n- 리테이너 계약 선호\n- 월 200-400만원 (협의)\n- 원격 근무",
      category: :seeking,
      service_type: 'marketing',
      work_type: 'remote',
      price: 3000000,
      available_now: true,
      views_count: 145
    },
    {
      user: video,
      title: '[구직] 영상 크리에이터 (유튜브 10만 구독자)',
      content: "스타트업 홍보 영상을 전문으로 제작합니다.\n\n## 제작 가능 영상\n\n1. **서비스 소개 영상** (30초~2분)\n2. **IR 피칭 영상** (3-5분)\n3. **유튜브/인스타 광고** (15초/30초/60초)\n4. **인터뷰 영상** (대표 인터뷰, 팀 소개)\n\n## 작업 과정\n\n1. 사전 미팅 (기획 논의)\n2. 시나리오/콘티 작성\n3. 촬영 (1-2일)\n4. 편집 및 피드백 (1주일)\n5. 최종 납품\n\n## 포트폴리오\n\n유튜브 채널에서 확인 가능합니다.\n\n## 가격\n\n- 간단한 편집: 50만원~\n- 촬영+편집: 150만원~\n- 모션그래픽: 200만원~",
      category: :seeking,
      service_type: 'video',
      work_type: 'hybrid',
      price: 1500000,
      price_negotiable: true,
      available_now: true,
      portfolio_url: 'https://youtube.com/@example',
      views_count: 123
    },
    {
      user: data_scientist,
      title: '[구직] 데이터 사이언티스트 (ML/DL 전문)',
      content: "AI/ML 전문 데이터 사이언티스트입니다.\n\n## 기술 스택\n\n- Python, TensorFlow, PyTorch\n- SQL, BigQuery\n- AWS SageMaker\n- MLOps (MLflow, Kubeflow)\n\n## 가능 업무\n\n1. 추천 시스템 구축\n2. 자연어 처리 (NLP)\n3. 이미지 분류/객체 탐지\n4. 데이터 파이프라인 설계\n5. A/B 테스트 설계 및 분석\n\n## 주요 프로젝트\n\n- 개인화 추천 엔진 (CTR 30% 개선)\n- 고객 이탈 예측 모델\n- 챗봇 NLP 모델 개발\n\n## 조건\n\n- 파트타임/풀타임 모두 가능\n- 원격 근무 선호\n- 프로젝트 단위 계약 선호",
      category: :seeking,
      service_type: 'development',
      work_type: 'remote',
      price: 80000,
      available_now: true,
      skills: 'Python, TensorFlow, PyTorch, SQL',
      views_count: 134
    }
  ]

  created_outsourcing_posts = outsourcing_posts.map do |post_data|
    post = Post.create!(
      user: post_data[:user],
      title: post_data[:title],
      content: post_data[:content],
      category: post_data[:category],
      status: :published,
      service_type: post_data[:service_type],
      work_type: post_data[:work_type],
      price: post_data[:price],
      price_negotiable: post_data[:price_negotiable] || false,
      work_period: post_data[:work_period],
      available_now: post_data[:available_now] || false,
      portfolio_url: post_data[:portfolio_url],
      skills: post_data[:skills],
      views_count: post_data[:views_count] || rand(50..150)
    )
    puts "  ✅ [#{post.category_label}] #{post.title.truncate(40)}"
    post
  end

  all_posts = created_community_posts + created_outsourcing_posts

  puts "\n" + "=" * 60
  puts "💬 Creating Comments..."
  puts "=" * 60

  # ========================================
  # 4. 댓글 생성
  # ========================================

  comment_contents = [
    # 긍정적 댓글
    "정말 도움이 되는 글이네요! 감사합니다 🙏",
    "저도 비슷한 경험이 있어서 공감됩니다.",
    "좋은 정보 공유해주셔서 감사합니다!",
    "오 이런 관점은 생각 못했네요. 배워갑니다.",
    "대박... 정말 인사이트 있는 글이에요!",
    "저도 참여하고 싶습니다! DM 드려도 될까요?",
    "완전 공감합니다. 저도 같은 고민 중이었어요.",
    "와 이 정보 진짜 필요했는데 감사합니다!",
    # 질문 댓글
    "혹시 구체적인 사례 하나만 더 들어주실 수 있나요?",
    "예산은 어느 정도 생각하시나요?",
    "원격 근무도 가능할까요?",
    "포트폴리오 보내드리면 검토해주실 수 있나요?",
    # 공유 댓글
    "저도 비슷한 글을 쓴 적이 있는데, 참고하시면 좋을 것 같아요.",
    "제 경험으로는 이런 방법도 효과적이었어요.",
    "팀원들이랑 공유했습니다. 좋은 글이에요!",
    # 응원 댓글
    "화이팅입니다! 좋은 결과 있으시길 바랍니다 💪",
    "멋지네요! 응원합니다!",
    "대단하시네요. 저도 열심히 해야겠어요."
  ]

  all_posts.each do |post|
    # 게시글당 0-8개 랜덤 댓글
    rand(0..8).times do
      commenter = users.reject { |u| u == post.user }.sample
      Comment.create!(
        post: post,
        user: commenter,
        content: comment_contents.sample
      )
    end
  end

  puts "  ✅ Created #{Comment.count} comments"

  puts "\n" + "=" * 60
  puts "❤️ Creating Likes & Bookmarks..."
  puts "=" * 60

  # ========================================
  # 5. 좋아요 & 북마크
  # ========================================

  all_posts.each do |post|
    # 좋아요 (0-8명)
    users.sample(rand(0..8)).each do |user|
      Like.create!(user: user, likeable: post) rescue nil
    end

    # 북마크 (0-4명)
    users.sample(rand(0..4)).each do |user|
      Bookmark.create!(user: user, bookmarkable: post) rescue nil
    end
  end

  puts "  ✅ Created #{Like.count} likes"
  puts "  ✅ Created #{Bookmark.count} bookmarks"

  puts "\n" + "=" * 60
  puts "💬 Creating Chat Rooms & Messages..."
  puts "=" * 60

  # ========================================
  # 6. 채팅방 & 메시지
  # ========================================

  # 시나리오 1: 구인 글에 대한 문의 (developer → founder의 구인 글)
  hiring_post = created_outsourcing_posts.find { |p| p.hiring? && p.user == founder }
  if hiring_post
    chat1 = ChatRoom.find_or_create_for_post(
      post: hiring_post,
      initiator: developer,
      post_author: founder
    )

    messages1 = [
      { sender: developer, content: "안녕하세요! 구인 글 보고 연락드립니다. 혹시 아직 구인 중이신가요?" },
      { sender: founder, content: "네 안녕하세요! 아직 구인 중입니다. 포트폴리오 보내주시면 검토해볼게요." },
      { sender: developer, content: "깃허브 링크 보내드립니다: https://github.com/devlee\n주요 프로젝트들 확인해주세요!" },
      { sender: founder, content: "확인했습니다! 경력이 인상적이네요. 간단하게 화상 미팅 한번 하시죠?" },
      { sender: developer, content: "좋습니다! 이번 주 언제가 편하신가요?" },
      { sender: founder, content: "목요일 오후 3시 어떠세요? Zoom으로 진행할게요." },
      { sender: developer, content: "네 좋습니다! 링크 공유해주시면 참석하겠습니다 😊" }
    ]

    messages1.each_with_index do |msg, idx|
      Message.create!(
        chat_room: chat1,
        sender: msg[:sender],
        content: msg[:content],
        created_at: (messages1.length - idx).hours.ago
      )
    end
    chat1.update!(last_message_at: Time.current)
    puts "  ✅ Chat room: #{developer.name} → #{founder.name} (구인 문의)"
  end

  # 시나리오 2: 구직 글에 대한 문의 (founder → designer의 구직 글)
  seeking_post = created_outsourcing_posts.find { |p| p.seeking? && p.user == designer }
  if seeking_post
    chat2 = ChatRoom.find_or_create_for_post(
      post: seeking_post,
      initiator: founder,
      post_author: designer
    )

    messages2 = [
      { sender: founder, content: "안녕하세요! 구직 글 보고 연락드립니다. 디자인 외주 의뢰 가능할까요?" },
      { sender: designer, content: "안녕하세요! 네 가능합니다. 어떤 프로젝트인가요?" },
      { sender: founder, content: "에듀테크 서비스의 새 기능 UI 디자인이에요. 약 5개 화면 정도입니다." },
      { sender: designer, content: "재미있을 것 같네요! 상세 기획서 공유해주시면 견적 드릴게요." },
      { sender: founder, content: "네 Notion으로 정리해서 보내드릴게요. 이메일 주소 알려주시겠어요?" }
    ]

    messages2.each_with_index do |msg, idx|
      Message.create!(
        chat_room: chat2,
        sender: msg[:sender],
        content: msg[:content],
        created_at: (messages2.length - idx).hours.ago - 1.day
      )
    end
    chat2.update!(last_message_at: 1.day.ago)
    puts "  ✅ Chat room: #{founder.name} → #{designer.name} (디자인 의뢰)"
  end

  # 시나리오 3: 확정된 거래 (pm → developer)
  dev_seeking = created_outsourcing_posts.find { |p| p.seeking? && p.user == developer }
  if dev_seeking
    chat3 = ChatRoom.find_or_create_for_post(
      post: dev_seeking,
      initiator: pm,
      post_author: developer
    )

    messages3 = [
      { sender: pm, content: "안녕하세요! MVP 개발 외주 맡기고 싶습니다." },
      { sender: developer, content: "안녕하세요! 어떤 서비스인가요?" },
      { sender: pm, content: "B2B SaaS 대시보드입니다. Rails + React로 생각하고 있어요." },
      { sender: developer, content: "제 주력 스택이네요! 기획서 보내주시면 견적 드릴게요." },
      { sender: pm, content: "Notion 링크 보내드렸습니다. 확인해주세요!" },
      { sender: developer, content: "확인했습니다. 예상 기간 3개월, 800만원 정도로 견적 드립니다." },
      { sender: pm, content: "좋습니다! 계약서 작성하시죠." }
    ]

    messages3.each_with_index do |msg, idx|
      Message.create!(
        chat_room: chat3,
        sender: msg[:sender],
        content: msg[:content],
        created_at: (messages3.length - idx).hours.ago - 3.days
      )
    end

    # 거래 확정
    chat3.confirm_deal!(developer)
    chat3.update!(last_message_at: 3.days.ago)
    puts "  ✅ Chat room: #{pm.name} → #{developer.name} (거래 확정됨)"
  end

  # 시나리오 4: 프로필에서 직접 대화 시작 (student → developer 멘토링 요청)
  chat4 = ChatRoom.find_or_create_between(student, developer, initiator: student)
  messages4 = [
    { sender: student, content: "안녕하세요! 개발자 커리어 관련해서 조언 구하고 싶어서 연락드렸습니다." },
    { sender: developer, content: "안녕하세요! 네 편하게 물어보세요 😊" },
    { sender: student, content: "스타트업과 대기업 중 어디로 첫 직장을 가는 게 좋을까요?" },
    { sender: developer, content: "저는 개인적으로 스타트업 추천드려요. 배울 게 정말 많아요!" }
  ]

  messages4.each_with_index do |msg, idx|
    Message.create!(
      chat_room: chat4,
      sender: msg[:sender],
      content: msg[:content],
      created_at: (messages4.length - idx).hours.ago - 2.days
    )
  end
  chat4.update!(last_message_at: 2.days.ago)
  puts "  ✅ Chat room: #{student.name} → #{developer.name} (멘토링 요청)"

  # 시나리오 5: 읽지 않은 메시지가 있는 채팅방
  chat5 = ChatRoom.find_or_create_between(marketer, founder, initiator: marketer)
  messages5 = [
    { sender: marketer, content: "안녕하세요! 마케팅 협업 제안드리고 싶습니다." },
    { sender: marketer, content: "에듀테크 서비스 그로스 마케팅 경험이 있어서 연락드렸어요." },
    { sender: marketer, content: "시간 되실 때 회신 부탁드립니다!" }
  ]

  messages5.each_with_index do |msg, idx|
    Message.create!(
      chat_room: chat5,
      sender: msg[:sender],
      content: msg[:content],
      created_at: (30 - idx * 10).minutes.ago
    )
  end
  chat5.update!(last_message_at: 10.minutes.ago)

  # founder의 읽지 않은 메시지 카운트 업데이트
  founder_participant = chat5.participants.find_by(user: founder)
  founder_participant.update!(last_read_at: 1.hour.ago)
  puts "  ✅ Chat room: #{marketer.name} → #{founder.name} (읽지 않은 메시지 있음)"

  puts "\n" + "=" * 60
  puts "🔔 Creating Notifications..."
  puts "=" * 60

  # ========================================
  # 7. 알림 생성
  # ========================================

  # 댓글 알림
  Comment.limit(5).each do |comment|
    next if comment.user == comment.post.user
    Notification.create!(
      recipient: comment.post.user,
      actor: comment.user,
      action: 'comment',
      notifiable: comment
    )
  end

  # 좋아요 알림
  Like.where(likeable_type: 'Post').limit(5).each do |like|
    next if like.user == like.likeable.user
    Notification.create!(
      recipient: like.likeable.user,
      actor: like.user,
      action: 'like',
      notifiable: like
    )
  end

  # 일부 알림은 읽음 처리
  Notification.limit(3).update_all(read_at: Time.current)

  puts "  ✅ Created #{Notification.count} notifications"

  # ========================================
  # 최종 요약
  # ========================================

  puts "\n" + "=" * 60
  puts "🎉 SEED DATA CREATED SUCCESSFULLY!"
  puts "=" * 60

  puts "\n📊 Summary:"
  puts "  - Users: #{User.count}"
  puts "  - Posts (Community): #{Post.community.count}"
  puts "  - Posts (Outsourcing): #{Post.outsourcing.count}"
  puts "  - Comments: #{Comment.count}"
  puts "  - Likes: #{Like.count}"
  puts "  - Bookmarks: #{Bookmark.count}"
  puts "  - Chat Rooms: #{ChatRoom.count}"
  puts "  - Messages: #{Message.count}"
  puts "  - Notifications: #{Notification.count}"

  puts "\n📧 Test Accounts (password: #{test_password}):"
  puts "  Admin:     admin@startup.com"
  puts "  Founder:   founder@startup.com   (팀원 모집 중)"
  puts "  Developer: developer@startup.com (외주 가능)"
  puts "  Designer:  designer@startup.com  (외주 가능)"
  puts "  PM:        pm@startup.com        (공동창업자 모집)"
  puts "  Marketer:  marketer@startup.com  (외주 가능)"
  puts "  Student:   student@startup.com   (인턴 구직 중)"
  puts "  Investor:  investor@startup.com"
  puts "  Junior:    junior@startup.com    (외주 가능)"
  puts "  Video:     video@startup.com     (외주 가능)"
  puts "  Data:      data@startup.com"

  puts "\n💡 Test Scenarios:"
  puts "  1. founder@startup.com 로그인 → 채팅에 읽지 않은 메시지 확인"
  puts "  2. developer@startup.com 로그인 → 확정된 거래 채팅 확인"
  puts "  3. 외주 섹션에서 구인/구직 글 확인"
  puts "  4. 프로필 페이지에서 활동 상태 확인"

  puts "\n✨ You can now start the server: bin/rails server"
end
