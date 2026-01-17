# frozen_string_literal: true

# n8n 테스트용 단일 시드 유저 생성
# 실행: rails runner db/seeds/n8n_test_user.rb

puts "=" * 60
puts "n8n 테스트 유저 생성"
puts "=" * 60

TEST_USER = {
  email: "n8n.test.bot@seed.internal",
  name: "Test Bot",
  nickname: "테스트봇",
  password: "TestUser2024!",
  bio: "n8n 자동화 테스트용 계정입니다.",
  role_title: "테스트",
  skills: "자동화, 테스트",
  persona_id: "test_bot"
}

# 이미 존재하는지 확인
existing = User.find_by(email: TEST_USER[:email])

if existing
  puts "[INFO] 테스트 유저가 이미 존재합니다 (ID: #{existing.id})"

  # API 토큰이 없으면 생성
  unless existing.api_token?
    existing.generate_api_token!
    puts "  → API 토큰 새로 생성됨"
  end

  user = existing
else
  # 새 유저 생성
  user = User.new(
    email: TEST_USER[:email],
    name: TEST_USER[:name],
    nickname: TEST_USER[:nickname],
    password: TEST_USER[:password],
    password_confirmation: TEST_USER[:password],
    bio: TEST_USER[:bio],
    role_title: TEST_USER[:role_title],
    skills: TEST_USER[:skills],
    profile_completed: true
  )

  if user.save
    user.generate_api_token!
    puts "[OK] 테스트 유저 생성됨 (ID: #{user.id})"
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
puts "COMMUNITY_API_URL = http://localhost:3000"
puts "TEST_BOT_API_TOKEN = #{user.api_token}"
puts "\n"
puts "=" * 60
puts "API 테스트 (curl)"
puts "=" * 60
puts "\n다음 명령어로 API를 테스트할 수 있습니다:\n"
puts <<~CURL
curl -X POST http://localhost:3000/api/v1/posts \\
  -H "Authorization: Bearer #{user.api_token}" \\
  -H "Content-Type: application/json" \\
  -d '{
    "post": {
      "title": "테스트 게시글",
      "content": "n8n 자동화 테스트입니다.",
      "category": "free"
    }
  }'
CURL
puts "\n"
puts "=" * 60
