---
paths: app/**/*.rb, app/**/*.js, app/**/*.erb
---

# 코드 품질 규칙

## 복잡도 제한

| 항목 | 최대값 | 초과 시 조치 |
|------|-------|------------|
| 메서드 길이 | 20줄 | 메서드 분리 |
| 클래스 길이 | 200줄 | Concern/Service 분리 |
| 조건문 깊이 | 3단계 | Early return 활용 |
| 파라미터 수 | 4개 | 객체로 묶기 |

## DRY (Don't Repeat Yourself)

```ruby
# ❌ 중복 코드
class PostsController
  def index
    @posts = Post.where(published: true).order(created_at: :desc).limit(10)
  end
end

class HomeController
  def index
    @posts = Post.where(published: true).order(created_at: :desc).limit(10)
  end
end

# ✅ Scope로 추출
class Post
  scope :recent_published, -> { published.recent.limit(10) }
end
```

## Early Return

```ruby
# ❌ 깊은 중첩
def process(user)
  if user.present?
    if user.active?
      if user.verified?
        # 실제 로직
      end
    end
  end
end

# ✅ Early Return
def process(user)
  return unless user.present?
  return unless user.active?
  return unless user.verified?

  # 실제 로직
end
```

## 상수 사용

```ruby
# ❌ Magic Number
if user.posts.count > 10
  # ...
end

# ✅ 상수로 의미 부여
MAX_FREE_POSTS = 10

if user.posts.count > MAX_FREE_POSTS
  # ...
end
```

## 네이밍 규칙

```ruby
# 변수/메서드: snake_case
user_name = "John"
def calculate_total; end

# 클래스/모듈: CamelCase
class UserProfile; end
module PaymentGateway; end

# 상수: SCREAMING_SNAKE_CASE
MAX_RETRY_COUNT = 3
DEFAULT_PAGE_SIZE = 20

# Boolean 메서드: ?로 끝남
def active?; end
def can_edit?; end

# 위험한 메서드: !로 끝남
def save!; end  # 실패 시 예외
def destroy!; end
```

## 주석 규칙

```ruby
# ❌ 불필요한 주석
# 사용자를 찾는다
user = User.find(id)

# ✅ 필요한 주석 - "왜"를 설명
# OAuth 사용자는 비밀번호가 없으므로 건너뜀
return if user.oauth_only?

# ✅ TODO 주석
# TODO: N+1 쿼리 최적화 필요 (2026-02-01까지)
```

## 파일 구조

```
# 한 파일에 하나의 주요 클래스
# app/services/users/deletion_service.rb
module Users
  class DeletionService
    # ...
  end
end

# 관련 클래스는 같은 네임스페이스
# app/services/users/registration_service.rb
# app/services/users/profile_service.rb
```

## 에러 처리

```ruby
# ✅ 구체적인 예외 처리
begin
  external_api.call
rescue Timeout::Error => e
  Rails.logger.warn "[API] Timeout: #{e.message}"
  retry_later
rescue ExternalApi::AuthError => e
  Rails.logger.error "[API] Auth failed: #{e.message}"
  raise
end

# ❌ 모든 예외 무시 금지
begin
  risky_operation
rescue => e
  # 아무것도 안 함 - 금지!
end
```
