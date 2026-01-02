# 프로덕션 배포 설정 가이드

**목표**: 결제 제외, 핵심 인프라만 먼저 구축
**소요 시간**: 약 1시간
**완료 후**: 프로덕션 배포 가능 (결제 기능 제외)

---

## 📋 체크리스트

### 필수 (지금)
- [ ] 1. Rails Credentials 설정 (SMTP, AWS S3, Secret Keys)
- [ ] 2. 환경 변수 설정 (ALLOWED_HOSTS, DATABASE_URL)
- [ ] 3. 프로덕션 데이터베이스 설정 (PostgreSQL)
- [ ] 4. SSL/보안 설정
- [ ] 5. 이메일 발송 테스트

### 선택 (나중에)
- [ ] Toss Payments 연동 (사업자등록 이후)
- [ ] CDN 설정 (트래픽 증가 시)
- [ ] Redis 캐싱 (필요 시)

---

## 1️⃣ Rails Credentials 설정

### 1-1. Credentials 편집

```bash
# 에디터로 credentials 파일 열기
EDITOR="nano" bin/rails credentials:edit

# 또는 VS Code 사용 시
EDITOR="code --wait" bin/rails credentials:edit
```

### 1-2. Credentials 템플릿 (아래 내용 추가)

```yaml
# config/credentials.yml.enc (암호화되어 저장됨)

# ===== 개발 환경 (기존 유지) =====
development:
  google_oauth:
    client_id: YOUR_GOOGLE_CLIENT_ID
    client_secret: YOUR_GOOGLE_CLIENT_SECRET
  github_oauth:
    client_id: YOUR_GITHUB_CLIENT_ID
    client_secret: YOUR_GITHUB_CLIENT_SECRET
  gemini_api_key: YOUR_GEMINI_API_KEY

# ===== 프로덕션 환경 (새로 추가) =====
production:
  # 이메일 발송 (SendGrid 또는 Gmail SMTP)
  smtp:
    address: smtp.sendgrid.net
    port: 587
    domain: yourdomain.com
    user_name: apikey
    password: SG.xxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    # Gmail 사용 시:
    # address: smtp.gmail.com
    # user_name: your-email@gmail.com
    # password: your-app-password  # 2단계 인증 후 앱 비밀번호

  # AWS S3 (이미지 저장)
  aws:
    access_key_id: AKIA...
    secret_access_key: xxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    region: ap-northeast-2  # 서울 리전
    bucket: startup-community-production

  # Secret Key Base (자동 생성되지만 명시적으로 관리)
  secret_key_base: <%= SecureRandom.hex(64) %>

  # Google OAuth (프로덕션용)
  google_oauth:
    client_id: YOUR_PROD_GOOGLE_CLIENT_ID
    client_secret: YOUR_PROD_GOOGLE_CLIENT_SECRET

  # GitHub OAuth (프로덕션용)
  github_oauth:
    client_id: YOUR_PROD_GITHUB_CLIENT_ID
    client_secret: YOUR_PROD_GITHUB_CLIENT_SECRET

  # Gemini API (프로덕션용)
  gemini_api_key: YOUR_PROD_GEMINI_API_KEY

  # ===== 결제 (나중에 추가) =====
  # toss_payments:
  #   client_key: live_ck_xxxxx
  #   secret_key: live_sk_xxxxx
  #   success_url: https://yourdomain.com/payments/success
  #   fail_url: https://yourdomain.com/payments/fail
```

**저장 방법**:
- nano: `Ctrl+O` (저장) → `Enter` → `Ctrl+X` (종료)
- VS Code: 저장 후 에디터 닫기

---

## 2️⃣ 환경 변수 설정

### 2-1. `.env.production` 파일 생성 (선택사항)

```bash
# .env.production (서버에서만 사용, Git에 커밋 금지!)
ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com
RAILS_ENV=production
RAILS_MASTER_KEY=your_master_key_here  # config/master.key 내용
DATABASE_URL=postgresql://username:password@localhost/startup_community_production
```

### 2-2. Kamal Secrets 설정

```bash
# .kamal/secrets 파일 생성 (Kamal 배포 시 사용)
cat > .kamal/secrets << 'EOF'
# Rails 환경 변수
ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com
RAILS_MASTER_KEY=your_master_key_here

# 데이터베이스
DATABASE_URL=postgresql://username:password@db-host/startup_community_production

# Redis (나중에 필요 시)
# REDIS_URL=redis://localhost:6379/0
EOF
```

**⚠️ 중요**: `.env.production`과 `.kamal/secrets`는 `.gitignore`에 추가!

---

## 3️⃣ 프로덕션 데이터베이스 설정

### 3-1. PostgreSQL 설정 확인

```yaml
# config/database.yml (이미 설정되어 있는지 확인)
production:
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  timeout: 5000
  database: startup_community_production
  username: <%= ENV['DATABASE_USERNAME'] %>
  password: <%= ENV['DATABASE_PASSWORD'] %>
  host: <%= ENV['DATABASE_HOST'] || 'localhost' %>
```

### 3-2. PostgreSQL 설치 및 데이터베이스 생성

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install postgresql postgresql-contrib libpq-dev

# PostgreSQL 시작
sudo systemctl start postgresql
sudo systemctl enable postgresql

# 데이터베이스 생성
sudo -u postgres createuser -s startup_community
sudo -u postgres createdb startup_community_production -O startup_community

# 비밀번호 설정
sudo -u postgres psql
\password startup_community
# 비밀번호 입력
\q
```

---

## 4️⃣ 프로덕션 환경 설정 파일

### 4-1. config/environments/production.rb 주요 설정

```ruby
# config/environments/production.rb
Rails.application.configure do
  # ===== 보안 =====
  config.force_ssl = true  # HTTPS 강제
  config.ssl_options = { redirect: { exclude: -> request { request.path =~ /health/ } } }

  # ===== 이메일 =====
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.default_url_options = { host: ENV['ALLOWED_HOSTS']&.split(',')&.first || 'yourdomain.com' }

  config.action_mailer.smtp_settings = {
    address: Rails.application.credentials.dig(:production, :smtp, :address),
    port: Rails.application.credentials.dig(:production, :smtp, :port),
    domain: Rails.application.credentials.dig(:production, :smtp, :domain),
    user_name: Rails.application.credentials.dig(:production, :smtp, :user_name),
    password: Rails.application.credentials.dig(:production, :smtp, :password),
    authentication: :plain,
    enable_starttls_auto: true
  }

  # ===== Active Storage (AWS S3) =====
  config.active_storage.service = :amazon

  # ===== 로깅 =====
  config.log_level = :info
  config.log_tags = [:request_id]

  # ===== 성능 =====
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local = false
  config.public_file_server.enabled = true

  # ===== 자산 압축 =====
  config.assets.compile = false
  config.assets.digest = true
end
```

### 4-2. config/storage.yml (AWS S3 설정)

```yaml
# config/storage.yml
amazon:
  service: S3
  access_key_id: <%= Rails.application.credentials.dig(:production, :aws, :access_key_id) %>
  secret_access_key: <%= Rails.application.credentials.dig(:production, :aws, :secret_access_key) %>
  region: <%= Rails.application.credentials.dig(:production, :aws, :region) %>
  bucket: <%= Rails.application.credentials.dig(:production, :aws, :bucket) %>
  # 이미지는 public 읽기 허용
  public: true
```

---

## 5️⃣ Kamal 배포 설정

### 5-1. config/deploy.yml 설정

```yaml
# config/deploy.yml
service: startup-community
image: your-dockerhub-username/startup-community

servers:
  web:
    - your-production-server-ip  # 실제 서버 IP로 변경

registry:
  server: ghcr.io  # GitHub Container Registry
  username: your-github-username
  password:
    - KAMAL_REGISTRY_PASSWORD

env:
  clear:
    ALLOWED_HOSTS: <%= ENV['ALLOWED_HOSTS'] %>
  secret:
    - RAILS_MASTER_KEY
    - DATABASE_URL

# SSL 설정 (Let's Encrypt)
traefik:
  options:
    publish:
      - "443:443"
    volume:
      - "/letsencrypt/acme.json:/letsencrypt/acme.json"
  args:
    entryPoints.web.address: ":80"
    entryPoints.websecure.address: ":443"
    certificatesResolvers.letsencrypt.acme.email: "your-email@example.com"
    certificatesResolvers.letsencrypt.acme.storage: "/letsencrypt/acme.json"
    certificatesResolvers.letsencrypt.acme.httpchallenge: true
    certificatesResolvers.letsencrypt.acme.httpchallenge.entrypoint: web

# 헬스체크
healthcheck:
  path: /up
  port: 3000
  max_attempts: 7
  interval: 10s
```

---

## 6️⃣ 보안 체크리스트

### ✅ 확인 사항

- [ ] `config/master.key`가 `.gitignore`에 포함되어 있음
- [ ] `.env.production`이 `.gitignore`에 포함되어 있음
- [ ] `.kamal/secrets`가 `.gitignore`에 포함되어 있음
- [ ] `ALLOWED_HOSTS` 환경 변수가 설정되어 있음
- [ ] SSL/TLS 인증서가 설정되어 있음 (Let's Encrypt)
- [ ] 데이터베이스 비밀번호가 강력함 (12자 이상, 특수문자 포함)
- [ ] Secret Key Base가 64자 이상의 랜덤 문자열

### ⚠️ 절대 Git에 커밋하면 안 되는 파일

```
config/master.key
.env
.env.production
.env.local
.kamal/secrets
```

---

## 7️⃣ 배포 전 테스트

### 7-1. 로컬에서 프로덕션 환경 테스트

```bash
# Assets 프리컴파일
RAILS_ENV=production bin/rails assets:precompile

# 데이터베이스 마이그레이션
RAILS_ENV=production bin/rails db:migrate

# 프로덕션 모드로 서버 실행 (테스트)
RAILS_ENV=production bin/rails server

# 브라우저에서 확인: http://localhost:3000
```

### 7-2. 이메일 발송 테스트

```bash
# Rails 콘솔에서 테스트
RAILS_ENV=production bin/rails console

# 테스트 이메일 발송
ActionMailer::Base.mail(
  from: 'noreply@yourdomain.com',
  to: 'your-email@example.com',
  subject: 'Test Email',
  body: 'This is a test email from production.'
).deliver_now
```

---

## 8️⃣ AWS S3 버킷 생성 (이미지 저장용)

### 8-1. AWS 콘솔에서 S3 버킷 생성

1. AWS 콘솔 → S3 → "버킷 만들기"
2. 버킷 이름: `startup-community-production`
3. 리전: `아시아 태평양 (서울) ap-northeast-2`
4. 퍼블릭 액세스 차단: **해제** (이미지는 공개)
5. 버전 관리: 활성화 (선택)

### 8-2. CORS 설정

```json
[
  {
    "AllowedHeaders": ["*"],
    "AllowedMethods": ["GET", "PUT", "POST", "DELETE"],
    "AllowedOrigins": ["https://yourdomain.com", "https://www.yourdomain.com"],
    "ExposeHeaders": ["ETag"]
  }
]
```

### 8-3. IAM 사용자 생성 및 권한 부여

1. IAM → 사용자 → "사용자 추가"
2. 사용자 이름: `startup-community-s3`
3. 액세스 키 생성 (프로그래밍 방식 액세스)
4. 정책 연결: `AmazonS3FullAccess` (또는 버킷별 권한)
5. **액세스 키 ID**와 **비밀 액세스 키** 저장 → credentials.yml.enc에 추가

---

## 9️⃣ 배포 명령어

### Kamal로 첫 배포

```bash
# 1. 환경 변수 확인
cat .kamal/secrets

# 2. Docker 이미지 빌드 및 푸시
kamal build push

# 3. 서버 설정
kamal server bootstrap

# 4. 첫 배포
kamal deploy

# 5. 데이터베이스 마이그레이션
kamal app exec 'bin/rails db:migrate'
```

### 이후 배포

```bash
# 코드 변경 후 재배포
kamal deploy
```

---

## 🔟 배포 후 체크리스트

### ✅ 기능 테스트

- [ ] 홈페이지 로딩 확인
- [ ] 회원가입/로그인 작동
- [ ] OAuth 로그인 (Google, GitHub) 작동
- [ ] 게시글 작성/수정/삭제 작동
- [ ] 이미지 업로드 작동 (S3)
- [ ] 댓글 작성 작동
- [ ] 채팅 기능 작동
- [ ] 이메일 발송 작동 (회원가입 환영 이메일)
- [ ] HTTPS 접속 확인

### ⚠️ 결제 기능은 아직 비활성화

- [ ] 외주 글 작성은 가능하지만 결제는 불가
- [ ] Toss Payments 연동은 사업자등록 후 진행

---

## 📞 문제 해결

### 이메일 발송 실패 시

**SendGrid 사용 권장** (무료 플랜: 100통/일):
1. SendGrid 가입: https://sendgrid.com
2. API Key 생성
3. credentials.yml.enc에 추가

### 이미지 업로드 실패 시

1. S3 버킷 권한 확인
2. CORS 설정 확인
3. IAM 사용자 권한 확인
4. credentials.yml.enc의 AWS 키 확인

### SSL 인증서 오류 시

```bash
# Let's Encrypt 인증서 갱신
sudo certbot renew
```

---

## 🎯 다음 단계

### Phase 1.6: 통합 테스트
- SimpleCov 설치
- 전체 테스트 실행
- 커버리지 80% 이상 확인

### 결제 연동 (나중에)
- 사업자등록 완료 후
- Toss Payments 연동
- 결제 테스트 환경 구축

---

**작성일**: 2026-01-02
**다음 업데이트**: 배포 후 실제 설정값으로 수정
