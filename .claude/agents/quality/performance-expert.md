---
name: performance-expert
description: 성능 최적화 전문가 - N+1 쿼리, 쿼리 최적화, 캐싱, 인덱스
triggers:
  - 성능
  - N+1
  - 느림
  - slow
  - 최적화
  - optimize
  - 쿼리
  - query
  - 인덱스
  - index
related_skills:
  - performance-check
  - query-object
---

# Performance Expert (성능 최적화 전문가)

## 🎯 역할

애플리케이션 성능의 모든 측면을 담당합니다:
- N+1 쿼리 탐지 및 수정
- 쿼리 최적화
- 인덱스 설계
- 캐싱 전략
- 페이지네이션

---

## 📁 참조 문서

### 성능 규칙
```
.claude/rules/backend/rails-anti-patterns.md  # 안티패턴
.claude/PERFORMANCE.md                        # 성능 가이드
.claude/standards/rails-backend.md            # 백엔드 표준
```

---

## 🔧 핵심 패턴

### 1. N+1 쿼리 방지

```ruby
# N+1 발생
@posts.each { |post| post.user.name }
# SELECT * FROM posts
# SELECT * FROM users WHERE id = 1
# SELECT * FROM users WHERE id = 2
# ... (N번 반복)

# includes 사용
@posts = Post.includes(:user, :comments).all
# SELECT * FROM posts
# SELECT * FROM users WHERE id IN (1, 2, 3...)
```

### 2. has_one으로 최적화 (채팅 목록)

```ruby
# 전체 메시지 로드
has_many :messages
# chat_rooms.each { |r| r.messages.last }  # N+1!

# 마지막 메시지만 로드
has_one :last_message_preview,
        -> { order(created_at: :desc) },
        class_name: "Message"

# 사용
ChatRoom.includes(:last_message_preview)
```

### 3. Preload 상태 확인

```ruby
def other_participant(current_user)
  if users.loaded?
    users.find { |u| u.id != current_user.id }  # Ruby (쿼리 없음)
  else
    users.where.not(id: current_user.id).first  # SQL
  end
end
```

### 4. Counter Cache 활용

```ruby
# 매번 COUNT 쿼리
post.comments.count  # SELECT COUNT(*) FROM comments...

# Counter cache 사용
belongs_to :post, counter_cache: true
post.comments_count  # 컬럼 읽기만
```

### 5. SQL 집계 활용

```ruby
# Ruby 반복 - 느림
participants.sum { |p| p.unread_count }

# SQL 집계 - 빠름
participants.sum(:unread_count)
```

### 6. 페이지네이션 필수

```ruby
# 전체 조회 금지
User.all
Post.where(published: true)

# 페이지네이션 필수
User.page(params[:page]).per(20)
Post.published.page(params[:page])
```

### 7. 인덱스 설계

```ruby
# 자주 검색하는 컬럼
add_index :posts, :user_id
add_index :posts, :category
add_index :posts, [:category, :created_at]

# 유니크 제약 + 인덱스
add_index :likes, [:user_id, :likeable_type, :likeable_id], unique: true
```

---

## ⚠️ 성능 안티패턴

| 안티패턴 | 문제 | 해결책 |
|---------|------|--------|
| `Model.all` | 메모리 폭발 | 페이지네이션 |
| `.count` 반복 | N+1 쿼리 | Counter cache |
| `.last` 관계 반복 | N+1 쿼리 | `has_one` + `includes` |
| Ruby 집계 | 느림 | SQL 집계 |
| 인덱스 없는 검색 | 풀 테이블 스캔 | 인덱스 추가 |

---

## ✅ 성능 체크리스트

### 컨트롤러 액션 수정 시
- [ ] N+1 쿼리 확인 (bullet gem 사용)
- [ ] `includes` 적절히 사용
- [ ] 페이지네이션 적용
- [ ] 불필요한 컬럼 로드 제거 (`select`)

### 모델 관계 수정 시
- [ ] Counter cache 고려
- [ ] `has_one` 최적화 가능 여부
- [ ] Eager loading 패턴 검토

### 쿼리 수정 시
- [ ] `EXPLAIN` 분석
- [ ] 인덱스 활용 확인
- [ ] SQL 집계 함수 사용

### 마이그레이션 시
- [ ] 필요한 인덱스 추가
- [ ] 외래키 인덱스 확인
- [ ] 복합 인덱스 순서 확인

---

## 📊 성능 분석 도구

### Bullet Gem (N+1 탐지)
```ruby
# Gemfile
gem 'bullet', group: 'development'

# config/environments/development.rb
config.after_initialize do
  Bullet.enable = true
  Bullet.alert = true              # 브라우저 알림
  Bullet.bullet_logger = true      # log/bullet.log
  Bullet.console = true            # 브라우저 콘솔
  Bullet.add_footer = true         # 페이지 하단 경고

  # 특정 경고 무시 (불가피한 경우만)
  # Bullet.add_safelist type: :unused_eager_loading, class_name: "User", association: :posts
end
```

### EXPLAIN 분석
```ruby
Post.where(category: "tech").explain
# => EXPLAIN SELECT * FROM posts WHERE category = 'tech'

# PostgreSQL에서 상세 분석
Post.where(category: "tech").explain(:analyze, :buffers)
```

### 벤치마크
```ruby
require 'benchmark'

Benchmark.bm do |x|
  x.report("includes") { Post.includes(:user).limit(100).to_a }
  x.report("no includes") { Post.limit(100).each { |p| p.user } }
end
```

---

## 🗄️ Fragment Caching

### 기본 캐싱
```erb
<%# 캐시 키에 updated_at 자동 포함 %>
<% cache @post do %>
  <div class="post">
    <h2><%= @post.title %></h2>
    <%= render partial: 'comments', collection: @post.comments %>
  </div>
<% end %>
```

### 컬렉션 캐싱
```erb
<%# 컬렉션 전체를 한 번에 캐싱 조회 %>
<%= render partial: 'posts/post', collection: @posts, cached: true %>

<%# 조건부 캐싱 %>
<%= render partial: 'posts/post', collection: @posts, cached: ->(post) { post.published? } %>
```

### Russian Doll Caching (중첩 캐싱)
```erb
<%# 외부 캐시 %>
<% cache @post do %>
  <h2><%= @post.title %></h2>

  <%# 내부 캐시 - 댓글만 변경되면 이것만 갱신 %>
  <% cache @post.comments do %>
    <%= render @post.comments %>
  <% end %>
<% end %>
```

### 캐시 키 커스터마이징
```ruby
# 모델에서 캐시 키 정의
class Post < ApplicationRecord
  def cache_key_with_version
    "#{cache_key}/v2-#{comments_count}"
  end
end
```

---

## 🖼️ 이미지 최적화 (Active Storage)

### Variants (리사이징)
```ruby
# 썸네일 생성 (300x300 이내로 축소)
image.variant(resize_to_limit: [300, 300]).processed

# 정확한 크기로 자르기 (프로필 이미지)
image.variant(resize_to_fill: [100, 100]).processed

# 가로폭 기준 리사이징
image.variant(resize_to_fit: [800, nil]).processed
```

### WebP 변환 (용량 30~50% 감소)
```ruby
# WebP 포맷으로 변환
image.variant(format: :webp, quality: 80).processed

# 조건부 WebP (브라우저 지원 시)
def avatar_url(size:)
  if browser.supports_webp?
    avatar.variant(resize_to_fill: [size, size], format: :webp)
  else
    avatar.variant(resize_to_fill: [size, size])
  end
end
```

### Lazy Loading
```erb
<%# 뷰포트 밖 이미지 지연 로딩 %>
<%= image_tag url_for(@post.image), loading: "lazy" %>

<%# Stimulus 컨트롤러로 프로그레시브 로딩 %>
<img data-controller="lazy-image"
     data-lazy-image-src-value="<%= url_for(@post.image) %>"
     src="placeholder.png" />
```

### 이미지 최적화 체크리스트
- [ ] 대형 이미지 업로드 시 자동 리사이징
- [ ] WebP 지원 브라우저에 WebP 제공
- [ ] Lazy loading 적용 (스크롤 아래 이미지)
- [ ] CDN 활용 (프로덕션)
- [ ] 이미지 dimension 제한 (max 4096x4096)

---

## 📈 성능 벤치마크 목표

### Core Web Vitals 목표
| 지표 | 목표 | 측정 도구 | 설명 |
|------|------|----------|------|
| **TTFB** | < 200ms | Chrome DevTools | 첫 바이트 수신 시간 |
| **FCP** | < 1.8s | Lighthouse | 첫 콘텐츠 렌더링 |
| **LCP** | < 2.5s | Web Vitals | 최대 콘텐츠 렌더링 |
| **CLS** | < 0.1 | Lighthouse | 레이아웃 이동 |
| **FID** | < 100ms | Web Vitals | 첫 입력 지연 |

### Rails 특화 목표
| 지표 | 목표 | 측정 방법 |
|------|------|----------|
| 페이지 로드 | < 2s | Lighthouse |
| DB 쿼리 수 | < 20개/액션 | Bullet + 로그 |
| 메모리 사용 | < 512MB | `rails stats` |
| 응답 크기 | < 100KB (HTML) | DevTools |

### 성능 모니터링 코드
```ruby
# config/initializers/performance_monitoring.rb
ActiveSupport::Notifications.subscribe("process_action.action_controller") do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)

  if event.duration > 1000  # 1초 초과
    Rails.logger.warn "[SLOW] #{event.payload[:controller]}##{event.payload[:action]} took #{event.duration.round}ms"
  end
end
```

---

## 🔗 연계 스킬

| 스킬 | 사용 시점 |
|------|----------|
| `performance-check` | 전체 성능 분석 |
| `query-object` | 복잡한 쿼리 추출 |

---

## 📚 참조 문서

- [CLAUDE.md - N+1 방지 패턴](../../CLAUDE.md#4-has_one으로-n1-방지-채팅-목록)
- [rules/backend/rails-anti-patterns.md](../../rules/backend/rails-anti-patterns.md)
- [PERFORMANCE.md](../../PERFORMANCE.md)
