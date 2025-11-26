# db/seeds.rb

if Rails.env.development?
  puts "🌱 Starting seed process..."

  # 기존 데이터 삭제
  [Bookmark, Like, Comment, Post, JobPost, TalentListing, User].each do |model|
    model.destroy_all
    puts "  ✓ Cleared #{model.name} table"
  end

  # 관리자 계정
  admin = User.create!(
    email: 'admin@startup.com',
    password: 'password',
    password_confirmation: 'password',
    name: 'Admin',
    role_title: 'Platform Admin',
    bio: '스타트업 커뮤니티 관리자입니다.'
  )
  puts "✅ Created admin user: #{admin.email}"

  # 테스트 사용자 생성 (10명)
  users = []
  roles = ['Founder', 'Developer', 'Designer', 'PM', 'Marketer']

  10.times do |i|
    user = User.create!(
      email: "user#{i}@startup.com",
      password: 'password',
      password_confirmation: 'password',
      name: "사용자#{i}",
      role_title: roles.sample,
      bio: "안녕하세요, #{roles.sample}입니다. 스타트업에 관심이 많습니다."
    )
    users << user
  end
  puts "✅ Created #{users.count} test users"

  # 커뮤니티 게시글 생성 (30개)
  post_titles = [
    "창업 아이디어 피드백 부탁드립니다",
    "개발자 구합니다",
    "디자이너와 협업하고 싶어요",
    "마케팅 전략 조언 구합니다",
    "MVP 개발 어떻게 시작하나요?",
    "첫 고객 확보 팁 공유합니다",
    "스타트업 초기 팀 빌딩 경험",
    "투자 유치 경험 공유",
    "사이드 프로젝트 팀원 모집",
    "프리랜서로 시작하기",
    "노코드 툴 추천해주세요",
    "B2B vs B2C 어떻게 결정하셨나요?",
    "린 스타트업 방법론 질문",
    "제품 시장 적합성 찾는 법",
    "초기 유저 인터뷰 방법"
  ]

  posts = []
  30.times do |i|
    post = Post.create!(
      user: users.sample,
      title: post_titles.sample + " ##{i+1}",
      content: "본문 내용입니다.\n\n안녕하세요, 스타트업을 준비하고 있는 창업자입니다.\n궁금한 점이 있어서 글을 올립니다.\n\n여러분의 경험과 조언을 나눠주시면 감사하겠습니다.\n\n감사합니다!",
      status: :published,
      views_count: rand(0..100)
    )
    posts << post

    # 댓글 추가 (0-5개)
    rand(0..5).times do
      Comment.create!(
        post: post,
        user: users.sample,
        content: ["좋은 글이네요!", "도움이 되었습니다.", "저도 궁금했는데 감사합니다.", "같이 고민해봐요!", "응원합니다!"].sample
      )
    end

    # 좋아요 추가 (0-10개)
    users.sample(rand(0..10)).each do |user|
      Like.create!(user: user, likeable: post) rescue nil
    end
  end
  puts "✅ Created #{Post.count} posts with #{Comment.count} comments and #{Like.count} likes"

  # 구인 공고 생성 (15개)
  job_titles = [
    "풀스택 개발자 구합니다",
    "React 프론트엔드 개발자 찾습니다",
    "Rails 백엔드 개발자 모집",
    "UI/UX 디자이너 찾습니다",
    "제품 디자이너 구합니다",
    "그래픽 디자이너 협업 제안",
    "PM/기획자 구합니다",
    "프로젝트 매니저 모집",
    "마케팅 담당자 찾습니다",
    "그로스 해커 구합니다"
  ]

  15.times do |i|
    JobPost.create!(
      user: users.sample,
      title: job_titles.sample,
      description: "안녕하세요!\n\n저희 스타트업에서 함께할 팀원을 찾습니다.\n\n**프로젝트 설명:**\n- 초기 스타트업 프로젝트\n- 혁신적인 아이디어를 실현하고 있습니다\n\n**업무 내용:**\n- 제품 개발 및 운영\n- 팀과 협업하여 MVP 완성\n\n**우대사항:**\n- 스타트업 경험\n- 열정과 책임감\n\n관심 있으신 분은 연락 주세요!",
      category: [:development, :design, :pm, :marketing].sample,
      project_type: [:short_term, :long_term, :one_time].sample,
      budget: ["100만원", "200만원", "협의 가능", "시급 3만원", "일당 10만원"].sample,
      status: :open,
      views_count: rand(0..50)
    )
  end
  puts "✅ Created #{JobPost.count} job posts"

  # 구직 정보 생성 (10개)
  talent_titles = [
    "풀스택 개발자입니다 (Node.js, React)",
    "프론트엔드 개발자입니다 (React, Vue)",
    "백엔드 개발자입니다 (Rails, Django)",
    "UI/UX 디자이너입니다 (Figma)",
    "제품 디자이너입니다 (3년 경력)",
    "그래픽 디자이너입니다",
    "PM/기획자입니다 (스타트업 경험)",
    "마케팅 전문가입니다 (퍼포먼스 마케팅)",
    "그로스 해커입니다 (데이터 분석)",
    "콘텐츠 마케터입니다"
  ]

  10.times do |i|
    TalentListing.create!(
      user: users.sample,
      title: talent_titles.sample,
      description: "안녕하세요!\n\n**경력:**\n- 3년차 #{['개발자', '디자이너', '기획자', '마케터'].sample}\n- 스타트업 경험 다수\n\n**가능한 업무:**\n- 프로젝트 전반 참여 가능\n- 단기/장기 모두 가능\n\n**포트폴리오:**\n- 여러 프로젝트 성공적으로 완료\n- 레퍼런스 제공 가능\n\n**희망 사항:**\n- 열정적인 팀과 협업\n- 성장 가능한 프로젝트\n\n편하게 연락 주세요!",
      category: [:development, :design, :pm, :marketing].sample,
      project_type: [:short_term, :long_term, :one_time].sample,
      rate: ["시급 5만원", "일당 20만원", "월 300만원", "협의 가능"].sample,
      status: :available,
      views_count: rand(0..30)
    )
  end
  puts "✅ Created #{TalentListing.count} talent listings"

  # 북마크 추가
  bookmark_count = 0
  users.each do |user|
    # 게시글 북마크
    Post.published.sample(rand(1..3)).each do |post|
      Bookmark.create!(user: user, bookmarkable: post) rescue nil
      bookmark_count += 1
    end

    # 구인공고 북마크
    JobPost.open_positions.sample(rand(0..2)).each do |job_post|
      Bookmark.create!(user: user, bookmarkable: job_post) rescue nil
      bookmark_count += 1
    end

    # 구직정보 북마크
    TalentListing.available.sample(rand(0..1)).each do |talent|
      Bookmark.create!(user: user, bookmarkable: talent) rescue nil
      bookmark_count += 1
    end
  end
  puts "✅ Created #{Bookmark.count} bookmarks"

  puts "\n🎉 Seed data created successfully!"
  puts "\n📊 Summary:"
  puts "  - Users: #{User.count}"
  puts "  - Posts: #{Post.count}"
  puts "  - Comments: #{Comment.count}"
  puts "  - Likes: #{Like.count}"
  puts "  - Job Posts: #{JobPost.count}"
  puts "  - Talent Listings: #{TalentListing.count}"
  puts "  - Bookmarks: #{Bookmark.count}"
  puts "\n📧 Test Accounts:"
  puts "  Admin: admin@startup.com / password"
  puts "  Users: user0@startup.com ~ user9@startup.com / password"
  puts "\n✨ You can now start the server and test the application!"
end
