# 개발 환경 전환 가이드 (Mac ⇄ Ubuntu)

> **프로젝트**: Startup Community Platform
> **업데이트**: 2025-12-28
> **작성 이유**: Mac과 Ubuntu(Windows Desktop) 환경을 오가며 개발할 때 발생할 수 있는 문제 예방

---

## 🎯 환경 정보

### Mac (개발 환경 1)
- **OS**: macOS (darwin, Apple Silicon)
- **Ruby**: 3.4.1 (rbenv)
- **OpenSSL**: Homebrew OpenSSL 3.6.0
- **Platform**: `arm64-darwin-24`

### Ubuntu Desktop (개발 환경 2)
- **OS**: Ubuntu (WSL 또는 Native Linux)
- **Ruby**: 3.4.1 (rbenv 권장)
- **OpenSSL**: 시스템 기본 OpenSSL
- **Platform**: `x86_64-linux`

---

## ⚠️ 핵심 주의사항

### 1. **SSL 설정 파일 절대 삭제 금지!**

**파일**: `config/initializers/faraday_ssl.rb`

**이유**:
- Mac에서 Gemini API 호출 시 SSL 인증서 CRL 검증 오류 발생
- 이 파일이 없으면 Mac에서 AI 기능 전체가 작동하지 않음

**Ubuntu에서의 동작**:
- Ubuntu에서는 이 파일이 없어도 정상 작동
- 하지만 있어도 무해하므로 **절대 삭제하지 마세요!**

### 2. **master.key 백업 필수**

**파일**: `config/master.key` (Git에 커밋되지 않음!)

**백업 방법**:
```bash
# master.key 내용 확인
cat config/master.key

# 안전한 곳에 보관 (1Password, 비밀 메모 등)
```

**분실 시**:
- Credentials 복호화 불가 → Gemini API 키 사용 불가
- 다른 환경에서 복사하거나 재생성 필요

---

## 🔄 환경 전환 체크리스트

### Mac → Ubuntu 전환

```bash
# 1. Mac에서 작업 커밋
git add .
git commit -m "작업 내용"
git push origin main

# 2. Ubuntu에서 최신 코드 가져오기
cd /path/to/Startup-Community-rails
git pull origin main

# 3. Gem 재설치 (플랫폼 차이로 필수!)
bundle install

# 4. DB 마이그레이션 (변경사항이 있다면)
bin/rails db:migrate

# 5. master.key 확인
ls -la config/master.key
# 없으면 Mac에서 복사:
# scp mac:~/Startup-Community-rails/config/master.key config/

# 6. Credentials 복호화 테스트
bin/rails runner "puts Rails.application.credentials.dig(:gemini, :api_key).present?"
# 출력: true (정상)

# 7. 서버 시작
bin/rails server
```

### Ubuntu → Mac 전환

```bash
# 1. Ubuntu에서 작업 커밋
git add .
git commit -m "작업 내용"
git push origin main

# 2. Mac에서 최신 코드 가져오기
cd ~/Startup-Community-rails
git pull origin main

# 3. Gem 재설치 (플랫폼 차이로 필수!)
bundle install

# 4. DB 마이그레이션
bin/rails db:migrate

# 5. SSL 설정 파일 확인 (중요!)
ls -la config/initializers/faraday_ssl.rb
# 있어야 함! 없으면 AI 기능 작동 안 함

# 6. master.key 확인
ls -la config/master.key

# 7. Credentials 테스트
bin/rails runner "puts Rails.application.credentials.dig(:gemini, :api_key).present?"
# 출력: true

# 8. 서버 시작
bin/rails server
```

---

## 🐛 자주 발생하는 문제 & 해결

### 문제 1: "certificate verify failed (unable to get certificate CRL)"

**증상**:
```
SSL_connect returned=1 errno=0 state=error:
certificate verify failed (unable to get certificate CRL)
```

**원인**: Mac에서 `faraday_ssl.rb` 파일이 없음

**해결**:
```bash
# Ubuntu에서 이 파일을 삭제했는지 확인
git log --all --full-history -- config/initializers/faraday_ssl.rb

# 파일이 삭제되었다면 복구
git checkout HEAD~1 -- config/initializers/faraday_ssl.rb
git add config/initializers/faraday_ssl.rb
git commit -m "[fix] Restore SSL config for Mac compatibility"
git push
```

### 문제 2: "Couldn't decrypt config/credentials.yml.enc"

**증상**:
```
Couldn't decrypt config/credentials.yml.enc.
Perhaps you passed the wrong key?
```

**원인**: `master.key` 파일 없음 또는 내용 불일치

**해결**:
```bash
# 다른 환경에서 master.key 복사
# Mac에서:
cat config/master.key  # 내용 복사

# Ubuntu에:
echo "복사한_내용" > config/master.key
chmod 600 config/master.key

# 복호화 테스트
EDITOR=cat bin/rails credentials:edit
```

### 문제 3: Gemfile.lock 충돌

**증상**:
```
Git conflict in Gemfile.lock
PLATFORMS
<<<<<<< HEAD
  arm64-darwin-24
=======
  x86_64-linux
>>>>>>> origin/main
```

**해결**:
```bash
# 1. 충돌 발생 시 리모트 버전 사용
git checkout --theirs Gemfile.lock

# 2. 현재 플랫폼용 gem 재설치
bundle install

# 3. 커밋
git add Gemfile.lock
git commit -m "Resolve Gemfile.lock platform conflict"
```

### 문제 4: AI 기능이 작동하지 않음

**진단 순서**:

```bash
# 1. LLM 설정 확인
bin/rails runner "
  require './lib/langchain_config'
  puts 'LLM configured: ' + LangchainConfig.any_llm_configured?.to_s
  puts 'Gemini key present: ' + LangchainConfig.gemini_api_key.present?.to_s
"
# 출력:
# LLM configured: true
# Gemini key present: true

# 2. FollowUpGenerator 테스트
bin/rails runner "
  require './app/services/ai/follow_up_generator'
  result = Ai::FollowUpGenerator.new('테스트 아이디어').generate
  puts 'Questions: ' + result[:questions].present?.to_s
  puts 'Error: ' + result[:error].to_s
"
# 출력:
# Questions: true
# Error: false

# 3. 로그 확인
tail -f log/development.log | grep -i "LLM\|SSL\|Gemini"
```

---

## 📋 초기 설정 (새 환경 추가 시)

### 새로운 Ubuntu 환경 설정

```bash
# 1. Git clone
git clone <repository-url>
cd Startup-Community-rails

# 2. Ruby 설치 (rbenv)
rbenv install 3.4.1
rbenv local 3.4.1

# 3. Bundler 설치
gem install bundler

# 4. Gem 설치
bundle install

# 5. master.key 설정
# Mac에서 복사하거나 안전한 저장소에서 가져오기
echo "복사한_master_key_내용" > config/master.key
chmod 600 config/master.key

# 6. DB 생성 및 마이그레이션
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed  # 필요시

# 7. Credentials 확인
bin/rails runner "puts Rails.application.credentials.gemini[:api_key][0..10]"
# 출력: AIzaSyBSAe4... (API 키 앞부분)

# 8. 서버 시작 테스트
bin/rails server

# 9. AI 기능 테스트
# 브라우저에서 http://localhost:3000/ai/landing 접속
```

### 새로운 Mac 환경 설정

```bash
# 1-6번 동일

# 7. SSL 설정 확인
ls config/initializers/faraday_ssl.rb
# 있어야 함!

# 8-9번 동일
```

---

## 🔐 Credentials 관리

### 현재 설정된 키

**위치**: `config/credentials.yml.enc` (암호화됨)

**구조**:
```yaml
gemini:
  api_key: <YOUR_GEMINI_API_KEY>

google:
  client_id: <Google OAuth Client ID>
  client_secret: <Google OAuth Client Secret>

github:
  client_id: <GitHub OAuth Client ID>
  client_secret: <GitHub OAuth Client Secret>

# 기타 설정...
```

### Credentials 편집

```bash
# Mac
EDITOR="code --wait" bin/rails credentials:edit

# Ubuntu (nano)
EDITOR=nano bin/rails credentials:edit
```

---

## 📦 플랫폼별 Gem 차이

### Native Extension이 있는 Gem

다음 gem들은 플랫폼마다 다시 컴파일됩니다:

- `io-event` (SSL/네트워크)
- `nokogiri` (XML/HTML 파싱)
- `bootsnap` (부팅 속도 향상)
- `sqlite3` (데이터베이스)

**중요**: 환경 전환 시 반드시 `bundle install` 재실행!

### Gemfile.lock PLATFORMS

정상적인 Gemfile.lock은 여러 플랫폼을 포함합니다:

```ruby
PLATFORMS
  arm64-darwin-24
  x86_64-linux

DEPENDENCIES
  ...
```

---

## ✅ 환경 전환 자동화 스크립트

### 간편 전환 스크립트 (선택사항)

**파일**: `bin/switch_env` (생성 필요)

```bash
#!/bin/bash
# 환경 전환 자동화 스크립트

echo "🔄 환경 전환 시작..."

# Git pull
echo "📥 Git pull..."
git pull origin main

# Bundle install
echo "📦 Gem 재설치..."
bundle install

# DB migrate
echo "🗄️  DB 마이그레이션..."
bin/rails db:migrate

# Credentials 확인
echo "🔐 Credentials 확인..."
if bin/rails runner "Rails.application.credentials.dig(:gemini, :api_key)" > /dev/null 2>&1; then
  echo "✅ Credentials 정상"
else
  echo "❌ Credentials 오류 - master.key 확인 필요"
  exit 1
fi

# SSL 설정 확인 (Mac only)
if [[ "$OSTYPE" == "darwin"* ]]; then
  if [ -f "config/initializers/faraday_ssl.rb" ]; then
    echo "✅ SSL 설정 확인 (Mac)"
  else
    echo "⚠️  SSL 설정 파일 없음 - AI 기능 작동 안 할 수 있음"
  fi
fi

echo "✅ 환경 전환 완료!"
echo "서버 시작: bin/rails server"
```

**사용법**:
```bash
chmod +x bin/switch_env
./bin/switch_env
```

---

## 🚨 절대 하지 말아야 할 것

1. ❌ **master.key를 Git에 커밋**
   - `.gitignore`에 이미 포함되어 있으므로 안전하지만 주의

2. ❌ **SQLite DB 파일(.sqlite3)을 Git에 커밋**
   - 환경 간 DB 충돌 발생

3. ❌ **Ubuntu에서 faraday_ssl.rb 삭제**
   - Mac에서 작동 안 함!

4. ❌ **Gemfile.lock을 .gitignore에 추가**
   - 버전 불일치 문제 발생 가능

5. ❌ **bundle install 없이 서버 시작**
   - Gem 버전 불일치로 오류 발생

---

## 📞 문제 발생 시

### 빠른 진단

```bash
# 환경 정보 출력
echo "=== 환경 정보 ==="
echo "OS: $(uname -s)"
echo "Ruby: $(ruby -v)"
echo "Rails: $(bin/rails -v)"
echo "Bundler: $(bundle -v)"
echo ""

# Git 상태
echo "=== Git 상태 ==="
git status
git log --oneline -5
echo ""

# Credentials 확인
echo "=== Credentials 확인 ==="
ls -la config/master.key
bin/rails runner "puts 'Gemini key: ' + Rails.application.credentials.dig(:gemini, :api_key).present?.to_s"
echo ""

# SSL 설정 확인
echo "=== SSL 설정 ==="
ls -la config/initializers/faraday_ssl.rb
```

---

## 🎉 성공 확인

모든 설정이 완료되면 다음이 정상 작동해야 합니다:

1. ✅ `bin/rails server` 시작
2. ✅ http://localhost:3000 접속
3. ✅ AI 아이디어 분석 페이지 접속
4. ✅ 아이디어 입력 → 추가 질문 생성
5. ✅ 전체 분석 결과 확인

---

**작성자**: Claude
**최종 업데이트**: 2025-12-28
**버전**: 1.0
