---
paths: app/**/*.rb, config/**/*.rb, lib/**/*.rb
---

# Rails 안티패턴 (금지 사항)

## 데이터베이스 쿼리

### N+1 쿼리 (필수 방지)
```ruby
# ❌ N+1 발생 - 절대 금지
@posts.each { |post| post.user.name }

# ✅ includes 사용
@posts = Post.includes(:user, :comments).all

# ✅ joins + select (집계용)
Post.joins(:comments).select("posts.*, COUNT(comments.id) as comments_count").group("posts.id")
```

### 페이지네이션 필수
```ruby
# ❌ 전체 조회 금지
User.all
Post.where(published: true)

# ✅ 페이지네이션 필수
User.page(params[:page]).per(20)
Post.where(published: true).page(params[:page])
```

### Raw SQL 금지
```ruby
# ❌ SQL Injection 위험
User.where("email = '#{params[:email]}'")

# ✅ 파라미터화된 쿼리
User.where("email = ?", params[:email])
User.where(email: params[:email])
```

## 컨트롤러 규칙

### Strong Parameters 필수
```ruby
# ❌ 절대 금지 - Mass Assignment 취약점
params.permit!
user.update(params[:user])

# ✅ 명시적 허용
def user_params
  params.require(:user).permit(:name, :email, :bio)
end
# 절대 허용 금지: :admin, :role, :is_admin
```

### 비즈니스 로직 분리
```ruby
# ❌ 컨트롤러에 비즈니스 로직 금지
def create
  @user = User.new(user_params)
  @user.send_welcome_email
  @user.create_default_settings
  @user.notify_admin
  # ...
end

# ✅ Service 객체로 분리
def create
  result = Users::RegistrationService.new(user_params).call
  # ...
end
```

## 모델 규칙

### Callback 최소화
```ruby
# ❌ 과도한 콜백 금지
after_save :send_email, :update_cache, :notify_admin, :sync_external

# ✅ 최대 3개, 복잡하면 Service 분리
after_save :update_counter_cache
```

### God Object 방지
```ruby
# ❌ 200줄 이상 모델 금지
class User < ApplicationRecord
  # 1000줄의 코드...
end

# ✅ Concern으로 분리
class User < ApplicationRecord
  include Authenticatable
  include Searchable
  include OAuthable
end
```

## 프로덕션 환경 금지 명령어

```bash
# ❌ 절대 금지 (데이터 손실)
rails db:reset
rails db:drop
User.destroy_all
Post.delete_all

# ❌ force push 금지
git push --force origin main
```

## 로깅 규칙

```ruby
# ❌ 민감정보 로깅 금지
Rails.logger.info "Password: #{password}"
Rails.logger.info "Token: #{api_token}"
Rails.logger.info "Card: #{card_number}"

# ✅ 컨텍스트만 로깅
Rails.logger.info "[AUTH] User##{user.id} logged in"
Rails.logger.error "[PAYMENT] Order##{order.id} failed: #{e.class}"
```
