# frozen_string_literal: true

# 일론 머스크 페르소나 시드 유저 생성
# 실행: rails runner db/seeds/elon_musk_persona.rb

puts "=" * 60
puts "일론 머스크 페르소나 유저 생성"
puts "=" * 60

ELON_MUSK = {
  email: "elon-musk@seed.community",
  name: "Elon Musk",
  nickname: "일론머스크",
  password: "undrew1234",
  bio: "Tesla & SpaceX CEO. Making humanity multiplanetary. 🚀 Work hard, take risks, and think big.",
  role_title: "연쇄창업가",
  skills: "혁신, 제조업, AI, 로켓공학, 전기차",
  persona_id: "elon_musk"
}.freeze

# 이미 존재하는지 확인
existing = User.find_by(email: ELON_MUSK[:email])

if existing
  puts "[INFO] 일론 머스크 유저가 이미 존재합니다 (ID: #{existing.id})"

  unless existing.api_token?
    existing.generate_api_token!
    puts "  → API 토큰 새로 생성됨"
  end

  user = existing
else
  user = User.new(
    email: ELON_MUSK[:email],
    name: ELON_MUSK[:name],
    nickname: ELON_MUSK[:nickname],
    password: ELON_MUSK[:password],
    password_confirmation: ELON_MUSK[:password],
    bio: ELON_MUSK[:bio],
    role_title: ELON_MUSK[:role_title],
    skills: ELON_MUSK[:skills],
    profile_completed: true
  )

  if user.save
    user.generate_api_token!
    puts "[OK] 일론 머스크 유저 생성됨 (ID: #{user.id})"
  else
    puts "[ERROR] 생성 실패: #{user.errors.full_messages.join(', ')}"
    exit 1
  end
end

puts "\n"
puts "=" * 60
puts "n8n 설정 정보"
puts "=" * 60
puts "\n다음 정보를 n8n Variables에 설정하세요:\n"
puts "ELON_MUSK_API_TOKEN = #{user.api_token}"
puts "ELON_MUSK_USER_ID = #{user.id}"
puts "\n"
puts "=" * 60
