---
name: auth-expert
description: 인증/인가 시스템 전문가 - 세션, OAuth, 이메일 인증, Remember Me
triggers:
  - 로그인
  - 인증
  - OAuth
  - 세션
  - 회원가입
  - 비밀번호
  - remember me
  - 이메일 인증
related_skills:
  - security-audit
---

# Auth Expert (인증 전문가)

## 🎯 역할

인증/인가 시스템의 모든 측면을 담당합니다:
- 세션 기반 로그인/로그아웃
- OAuth 소셜 로그인 (Google, GitHub)
- 이메일 인증 (Resend HTTP API)
- Remember Me (로그인 상태 유지)
- 회원 탈퇴 및 익명화

---

## 📁 담당 파일

### Controllers
```
app/controllers/sessions_controller.rb        # 로그인/로그아웃
app/controllers/users_controller.rb           # 회원가입
app/controllers/oauth_controller.rb           # OAuth 콜백
app/controllers/email_verifications_controller.rb  # 이메일 인증
app/controllers/password_resets_controller.rb # 비밀번호 재설정
app/controllers/user_deletions_controller.rb  # 회원 탈퇴
```

### Concerns
```
app/controllers/concerns/authentication.rb    # 인증 헬퍼
app/controllers/concerns/pending_analysis.rb  # OAuth 후 분석 복원
```

### Models
```
app/models/user.rb                            # 사용자 모델
app/models/user_deletion.rb                   # 탈퇴 정보 저장
```

### Services
```
app/services/oauth/google_service.rb          # Google OAuth
app/services/oauth/github_service.rb          # GitHub OAuth
app/services/users/deletion_service.rb        # 탈퇴 처리
app/services/email/verification_service.rb    # 이메일 인증
```

### Mailers
```
app/mailers/user_mailer.rb                    # 이메일 전송
app/mailers/email_verification_mailer.rb      # 인증 코드 발송
```

### JavaScript (Stimulus)
```
app/javascript/controllers/email_verification_controller.js
```

### Views
```
app/views/sessions/
├── new.html.erb              # 로그인 페이지

app/views/users/
├── new.html.erb              # 회원가입 페이지

app/views/email_verifications/
├── new.html.erb              # 인증 코드 입력

app/views/user_deletions/
├── new.html.erb              # 탈퇴 확인
```

### Tests
```
test/controllers/sessions_controller_test.rb
test/controllers/users_controller_test.rb
test/controllers/oauth_controller_test.rb
test/controllers/email_verifications_controller_test.rb
test/models/user_test.rb
test/services/oauth/*_test.rb
```

---

## 🔧 핵심 패턴

### 1. 세션 관리 (Session Fixation 방지)

```ruby
def log_in(user)
  reset_session  # 필수! 세션 고정 공격 방지
  session[:user_id] = user.id
end

def log_out
  reset_session
  @current_user = nil
end
```

### 2. OAuth 플로우

```ruby
# 1. 인가 요청
def google
  redirect_to GoogleOAuth.authorize_url(
    redirect_uri: oauth_callback_url(:google),
    state: form_authenticity_token
  ), allow_other_host: true
end

# 2. 콜백 처리
def callback
  user_info = Oauth::GoogleService.new(params[:code]).user_info
  user = User.find_or_create_from_oauth(user_info)
  log_in(user)

  # 비로그인 시 저장한 분석 복원
  restore_pending_input_and_analyze
end
```

### 3. Remember Me (영구 세션)

```ruby
# 로그인 시
if params[:remember_me] == "1"
  user.remember
  cookies.permanent.encrypted[:remember_token] = user.remember_token
end

# 자동 로그인
def current_user
  if session[:user_id]
    @current_user ||= User.find_by(id: session[:user_id])
  elsif cookies.encrypted[:remember_token]
    user = User.find_by(remember_token: cookies.encrypted[:remember_token])
    log_in(user) if user
    @current_user = user
  end
end
```

### 4. 이메일 인증 (6자리 코드)

```ruby
# 인증 코드 생성
def create_verification_code
  update(
    verification_code: SecureRandom.random_number(999999).to_s.rjust(6, '0'),
    verification_code_sent_at: Time.current
  )
end

# 코드 검증 (10분 만료)
def verify_code(code)
  return false if verification_code_sent_at < 10.minutes.ago
  verification_code == code
end
```

### 5. OAuth 세션 손실 대비

```ruby
# 비로그인 분석 후 OAuth 전환 시 세션 손실 대비
session[:pending_input_key] = cache_key
cookies.signed[:pending_input_key] = {
  value: cache_key,
  expires: 1.hour.from_now,
  httponly: true,
  same_site: :lax  # OAuth 리다이렉션 허용
}

# 복원 시
cache_key = session[:pending_input_key] || cookies.signed[:pending_input_key]
```

### 6. Rate Limiting (Brute Force 방지)

```ruby
# config/initializers/rack_attack.rb
class Rack::Attack
  # 로그인 시도 제한 - IP 기준 (5회/분)
  throttle("logins/ip", limit: 5, period: 60.seconds) do |req|
    req.ip if req.path == "/login" && req.post?
  end

  # 로그인 시도 제한 - 이메일 기준 (5회/분)
  throttle("logins/email", limit: 5, period: 60.seconds) do |req|
    if req.path == "/login" && req.post?
      req.params.dig("session", "email")&.downcase&.strip
    end
  end

  # 회원가입 제한 (10회/시간)
  throttle("signups/ip", limit: 10, period: 1.hour) do |req|
    req.ip if req.path == "/users" && req.post?
  end

  # 비밀번호 재설정 제한 (3회/시간)
  throttle("password_resets/ip", limit: 3, period: 1.hour) do |req|
    req.ip if req.path == "/password_resets" && req.post?
  end

  # 이메일 인증 코드 발송 제한 (3회/10분)
  throttle("email_verifications/ip", limit: 3, period: 10.minutes) do |req|
    req.ip if req.path == "/email_verifications" && req.post?
  end

  # 차단 응답 커스터마이징
  self.throttled_responder = lambda do |req|
    retry_after = (req.env["rack.attack.match_data"] || {})[:period]
    [
      429,
      { "Content-Type" => "application/json", "Retry-After" => retry_after.to_s },
      [{ error: "요청이 너무 많습니다. #{retry_after}초 후 다시 시도해주세요." }.to_json]
    ]
  end
end
```

### 7. 비밀번호 정책

```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_secure_password

  # 비밀번호 정책 (최소 8자, 대소문자+숫자 포함)
  PASSWORD_REQUIREMENTS = /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}\z/

  validates :password,
    length: { minimum: 8, message: "은(는) 최소 8자 이상이어야 합니다" },
    format: {
      with: PASSWORD_REQUIREMENTS,
      message: "은(는) 대문자, 소문자, 숫자를 각각 1개 이상 포함해야 합니다"
    },
    if: -> { new_record? || password.present? }

  # 일반적인 비밀번호 차단
  COMMON_PASSWORDS = %w[password 12345678 qwerty123].freeze

  validate :password_not_common, if: -> { password.present? }

  private

  def password_not_common
    if COMMON_PASSWORDS.include?(password.downcase)
      errors.add(:password, "는 너무 일반적입니다. 다른 비밀번호를 선택해주세요")
    end
  end
end
```

### 8. OAuth 세션 손실 방지 (강화 패턴)

```ruby
# app/controllers/concerns/pending_analysis.rb
module PendingAnalysis
  extend ActiveSupport::Concern

  private

  # OAuth 리다이렉션 전 데이터 저장 (세션 + 쿠키 + 캐시 3중 백업)
  def store_pending_analysis(idea)
    cache_key = "pending_analysis:#{SecureRandom.hex(16)}"
    cache_data = { idea: idea, created_at: Time.current }

    # 1. Rails Cache에 저장 (1시간)
    Rails.cache.write(cache_key, cache_data, expires_in: 1.hour)

    # 2. 세션에 키 저장
    session[:pending_input_key] = cache_key

    # 3. 쿠키에도 백업 (OAuth 리다이렉션 대비)
    cookies.signed[:pending_input_key] = {
      value: cache_key,
      expires: 1.hour.from_now,
      httponly: true,
      secure: Rails.env.production?,
      same_site: :lax  # OAuth 리다이렉션 허용!
    }
  end

  # OAuth 콜백 후 데이터 복원
  def restore_pending_analysis
    # 세션 우선, 쿠키 폴백
    cache_key = session.delete(:pending_input_key) ||
                cookies.signed.delete(:pending_input_key)
    return nil unless cache_key

    cached_data = Rails.cache.read(cache_key)
    Rails.cache.delete(cache_key)  # 한 번 사용 후 삭제

    return nil unless cached_data
    return nil if cached_data[:created_at] < 1.hour.ago  # 만료 체크

    cached_data[:idea]
  end
end
```

**same_site 옵션 가이드**:
| 값 | 동작 | OAuth 호환 | 보안 |
|-----|------|-----------|------|
| `:strict` | 같은 사이트만 | ❌ 콜백 실패 | 높음 |
| `:lax` | GET 허용 | ✅ 권장 | 중간 |
| `:none` | 모두 허용 | ✅ | 낮음 (HTTPS 필수) |

---

## ⚠️ 주의사항

### 금지 패턴

| 패턴 | 문제 | 대안 |
|------|------|------|
| `session[:user_id] = id` 직접 | Session Fixation | `reset_session` 먼저 호출 |
| 평문 비밀번호 저장 | 보안 위험 | `has_secure_password` 사용 |
| OAuth 토큰 로깅 | 민감정보 노출 | 필터링 또는 마스킹 |
| `same_site: :strict` | OAuth 콜백 실패 | `:lax` 사용 |
| 간단한 비밀번호 허용 | Brute Force 취약 | 비밀번호 정책 적용 |
| Rate Limiting 없음 | 무차별 대입 공격 | Rack::Attack 사용 |

### Strong Parameters 필수

```ruby
# ❌ 절대 금지
params.permit!

# ✅ 명시적 허용
def user_params
  params.require(:user).permit(:name, :email, :password, :password_confirmation)
  # admin, role 등 권한 필드 절대 허용 금지
end
```

---

## ✅ 체크리스트

### 로그인/로그아웃 수정 시
- [ ] `reset_session` 호출 확인
- [ ] CSRF 토큰 재생성 확인
- [ ] Remember Me 쿠키 처리 확인

### OAuth 수정 시
- [ ] state 파라미터 검증
- [ ] 콜백 URL 일치 확인
- [ ] 세션/쿠키 백업 사용
- [ ] 에러 핸들링 확인

### 이메일 인증 수정 시
- [ ] 만료 시간 확인 (10분)
- [ ] Rate Limiting 확인
- [ ] Resend API 연동 확인

### 회원 탈퇴 수정 시
- [ ] 개인정보 암호화 확인 (AES-256)
- [ ] 익명화 처리 확인
- [ ] 5년 보관 후 파기 확인

---

## 📚 참조 문서

- [CLAUDE.md - OAuth 세션 손실 패턴](../../CLAUDE.md#oauth-세션-손실-패턴-critical)
- [rules/backend/security.md](../../rules/backend/security.md)
- [SECURITY_GUIDE.md](../../SECURITY_GUIDE.md)
