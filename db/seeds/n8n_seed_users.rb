# frozen_string_literal: true

# n8n 자동화 시드 유저 생성 스크립트
# 용도: 커뮤니티 초기 콘텐츠 자동 생성용 봇 계정 5개
# 실행: rails runner db/seeds/n8n_seed_users.rb

puts "=" * 60
puts "n8n 시드 유저 생성 시작"
puts "=" * 60

# 페르소나 정의 (n8n workflows/config/personas.json과 동기화)
PERSONAS = [
  {
    email: "alex.chen.bot@seed.internal",
    name: "Alex Chen",
    nickname: "알렉스_창업러",
    password: "SeedUser2024!",
    bio: "3x 창업자, 2번 엑싯 경험. AI 스타트업 빌딩 중. 실패에서 배운 교훈 공유합니다.",
    role_title: "연쇄창업가",
    skills: "투자유치, PMF, 채용",
    persona_id: "alex_founder"
  },
  {
    email: "sam.dev.bot@seed.internal",
    name: "Sam Kim",
    nickname: "개발자샘",
    password: "SeedUser2024!",
    bio: "풀스택 개발자 10년차. 스타트업 CTO 경험. 기술 부채와 싸우는 중.",
    role_title: "시니어 개발자",
    skills: "React, Node.js, AWS, 시스템설계",
    persona_id: "dev_sam"
  },
  {
    email: "jenny.pm.bot@seed.internal",
    name: "Jenny Park",
    nickname: "제니PM",
    password: "SeedUser2024!",
    bio: "前 네카라쿠배 PM. 현재 초기 스타트업에서 0→1 프로덕트 빌딩 중.",
    role_title: "프로덕트 매니저",
    skills: "프로덕트전략, 사용자리서치, 데이터분석",
    persona_id: "jenny_pm"
  },
  {
    email: "mike.growth.bot@seed.internal",
    name: "Mike Lee",
    nickname: "그로스마이크",
    password: "SeedUser2024!",
    bio: "그로스 해커 5년차. MAU 10→100만 성장 경험. 퍼포먼스 마케팅 덕후.",
    role_title: "그로스 매니저",
    skills: "퍼포먼스마케팅, SEO, 데이터분석, A/B테스트",
    persona_id: "mike_growth"
  },
  {
    email: "sarah.designer.bot@seed.internal",
    name: "Sarah Choi",
    nickname: "디자이너사라",
    password: "SeedUser2024!",
    bio: "UX/UI 디자이너. 사용자 중심 디자인 철학. 디자인 시스템 구축 경험.",
    role_title: "시니어 디자이너",
    skills: "Figma, 디자인시스템, UX리서치, 프로토타이핑",
    persona_id: "sarah_designer"
  }
]

created_users = []

PERSONAS.each do |persona|
  # 이미 존재하는지 확인
  existing = User.find_by(email: persona[:email])

  if existing
    puts "[SKIP] #{persona[:name]} - 이미 존재함 (ID: #{existing.id})"

    # API 토큰이 없으면 생성
    unless existing.api_token?
      existing.generate_api_token!
      puts "  → API 토큰 생성됨"
    end

    created_users << {
      persona_id: persona[:persona_id],
      user_id: existing.id,
      name: existing.name,
      nickname: existing.nickname,
      api_token: existing.api_token
    }
    next
  end

  # 새 유저 생성
  user = User.new(
    email: persona[:email],
    name: persona[:name],
    nickname: persona[:nickname],
    password: persona[:password],
    password_confirmation: persona[:password],
    bio: persona[:bio],
    role_title: persona[:role_title],
    skills: persona[:skills],
    profile_completed: true
  )

  if user.save
    # API 토큰 생성
    user.generate_api_token!

    puts "[OK] #{persona[:name]} 생성됨 (ID: #{user.id})"

    created_users << {
      persona_id: persona[:persona_id],
      user_id: user.id,
      name: user.name,
      nickname: user.nickname,
      api_token: user.api_token
    }
  else
    puts "[ERROR] #{persona[:name]} 생성 실패: #{user.errors.full_messages.join(', ')}"
  end
end

puts "\n"
puts "=" * 60
puts "n8n Variables 설정용 정보"
puts "=" * 60
puts "\nn8n에서 Settings > Variables에 다음 값을 설정하세요:\n"

created_users.each do |u|
  puts "#{u[:persona_id].upcase}_API_TOKEN = #{u[:api_token]}"
  puts "#{u[:persona_id].upcase}_USER_ID = #{u[:user_id]}"
  puts ""
end

puts "\n"
puts "=" * 60
puts "personas.json 업데이트용 데이터"
puts "=" * 60
puts "\n다음 JSON을 workflows/config/personas.json의 각 페르소나에 추가하세요:\n"

created_users.each do |u|
  puts %Q({
  "id": "#{u[:persona_id]}",
  "accountId": #{u[:user_id]},
  "apiToken": "#{u[:api_token]}"
})
  puts ""
end

puts "=" * 60
puts "완료! #{created_users.size}명의 시드 유저가 준비되었습니다."
puts "=" * 60
