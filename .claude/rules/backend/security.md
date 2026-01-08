---
paths: app/controllers/**/*.rb, app/models/**/*.rb
---

# 보안 규칙 (OWASP 기반)

## SQL Injection 방지

```ruby
# ❌ 취약 - 문자열 보간 금지
User.where("name = '#{params[:name]}'")
User.where("id IN (#{ids.join(',')})")

# ✅ 안전 - 파라미터화
User.where("name = ?", params[:name])
User.where(name: params[:name])
User.where(id: ids)
```

## XSS 방지

```erb
<%# ❌ 취약 - raw/html_safe 직접 사용 금지 %>
<%= raw user_input %>
<%= user_input.html_safe %>

<%# ✅ 안전 - sanitize 필수 %>
<%= sanitize(user_content, tags: %w[p br strong em]) %>

<%# ✅ 기본 자동 이스케이핑 활용 %>
<%= @post.content %>
```

## CSRF 보호

```ruby
# ApplicationController에서 필수 활성화
protect_from_forgery with: :exception

# API 컨트롤러 (JSON 응답)
protect_from_forgery with: :null_session
```

## 인증 규칙

### 세션 관리
```ruby
# 로그인 시 세션 재생성 (Session Fixation 방지)
def log_in(user)
  reset_session  # 필수!
  session[:user_id] = user.id
end

# 로그아웃 시 완전 초기화
def log_out
  reset_session
  @current_user = nil
end
```

### 비밀번호 정책
```ruby
validates :password, length: { minimum: 8 }
# 권장: 12자 이상, 대소문자+숫자 포함
```

## 인가 규칙

### 리소스 소유권 확인 필수
```ruby
# ❌ IDOR 취약 - 누구나 접근 가능
def show
  @post = Post.find(params[:id])
end

# ✅ 안전 - 소유권 확인
def show
  @post = current_user.posts.find(params[:id])
end

# 또는 별도 인가 체크
before_action :authorize_post, only: [:edit, :update, :destroy]

def authorize_post
  redirect_to root_path unless @post.user == current_user
end
```

## 파일 업로드

```ruby
# 파일 타입 검증 필수
validate :acceptable_file

def acceptable_file
  return unless file.attached?

  unless file.content_type.in?(%w[image/jpeg image/png image/gif])
    errors.add(:file, "은(는) JPEG, PNG, GIF만 허용됩니다")
  end

  if file.byte_size > 5.megabytes
    errors.add(:file, "은(는) 5MB 이하만 허용됩니다")
  end
end
```

## 민감정보 필터링

```ruby
# config/initializers/filter_parameter_logging.rb
Rails.application.config.filter_parameters += [
  :password, :password_confirmation,
  :credit_card, :card_number,
  :ssn, :api_key, :token, :secret
]
```

## Rate Limiting

```ruby
# Rack::Attack 설정 예시
Rack::Attack.throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
  req.ip if req.path == '/login' && req.post?
end

Rack::Attack.throttle("email/ip", limit: 10, period: 1.hour) do |req|
  req.ip if req.path == '/email_verifications' && req.post?
end
```
