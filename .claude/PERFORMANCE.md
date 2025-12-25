# 성능 최적화 가이드

## 문서 정보
- **프로젝트**: Startup Community Platform
- **작성일**: 2025-12-25
- **목적**: 현재 적용된 성능 최적화 패턴 및 개선점 정리

---

## 현재 적용된 최적화

### 1. Counter Cache

데이터베이스 카운트 쿼리를 피하기 위해 카운터 캐시 적용.

**적용된 모델**:
```ruby
# Comment → Post
belongs_to :post, counter_cache: true
# posts.comments_count 자동 업데이트

# Like → Likeable (polymorphic)
belongs_to :likeable, polymorphic: true, counter_cache: true
# posts.likes_count, comments.likes_count 자동 업데이트

# Message → ChatRoom
belongs_to :chat_room, counter_cache: true, touch: :last_message_at
# chat_rooms.messages_count 자동 업데이트
```

**효과**:
```ruby
# Before (N+1 쿼리)
post.comments.count  # COUNT 쿼리 실행

# After (즉시 반환)
post.comments_count  # 캐시된 값 반환
```

---

### 2. Concern 모듈화

공통 기능을 Concern으로 분리하여 코드 재사용성 향상.

**Likeable Concern**:
```ruby
# app/models/concerns/likeable.rb
module Likeable
  extend ActiveSupport::Concern

  included do
    has_many :likes, as: :likeable, dependent: :destroy
  end

  def liked_by?(user)
    likes.exists?(user: user)
  end

  def toggle_like(user)
    # 비관적 잠금으로 race condition 방지
    with_lock do
      if liked_by?(user)
        likes.find_by(user: user).destroy
      else
        likes.create(user: user)
      end
    end
  end
end
```

**Bookmarkable Concern**:
```ruby
# app/models/concerns/bookmarkable.rb
module Bookmarkable
  # 동일한 패턴으로 북마크 기능 구현
end
```

---

### 3. Turbo Streams (부분 페이지 업데이트)

전체 페이지 새로고침 대신 부분 업데이트로 성능 향상.

**사용 패턴**:
```ruby
# 컨트롤러
respond_to do |format|
  format.turbo_stream do
    render turbo_stream: [
      turbo_stream.replace("chat_list_panel", partial: "chat_rooms/chat_list_panel"),
      turbo_stream.append("messages", partial: "messages/message", locals: { message: @message })
    ]
  end
  format.html { redirect_to @chat_room }
end
```

**효과**:
- 네트워크 트래픽 감소
- DOM 부분 업데이트로 렌더링 최적화
- 사용자 경험 향상 (깜빡임 없음)

---

### 4. Action Cable (WebSocket)

HTTP 폴링 대신 WebSocket으로 실시간 통신.

**채팅 메시지 브로드캐스트**:
```ruby
# app/models/message.rb
after_create_commit :broadcast_message

def broadcast_message
  chat_room.participants.each do |participant|
    broadcast_append_to(
      "chat_room_#{chat_room.id}_user_#{participant.user_id}",
      target: "messages",
      partial: "messages/message",
      locals: { message: self }
    )
  end
end
```

**효과**:
- 실시간 메시지 전송
- 서버 부하 감소 (폴링 대비)
- 즉각적인 사용자 피드백

---

### 5. Solid Suite (프로덕션 캐싱)

Rails 8의 Solid Suite로 외부 서비스 없이 캐싱/큐/WebSocket 지원.

**설정 (production.rb)**:
```ruby
# 캐시
config.cache_store = :solid_cache_store

# 백그라운드 작업
config.active_job.queue_adapter = :solid_queue

# WebSocket
config.action_cable.adapter = :solid_cable
```

**데이터베이스 분리**:
```yaml
# config/database.yml
production:
  primary:
    database: storage/production.sqlite3
  cache:
    database: storage/production_cache.sqlite3
    migrations_paths: db/cache_migrate
  queue:
    database: storage/production_queue.sqlite3
    migrations_paths: db/queue_migrate
  cable:
    database: storage/production_cable.sqlite3
    migrations_paths: db/cable_migrate
```

---

### 6. Import Maps (번들러 없음)

Webpack/Esbuild 없이 ES Module 직접 사용.

**장점**:
- 빌드 시간 없음
- 개발 서버 빠른 시작
- 의존성 관리 단순화

**설정**:
```ruby
# config/importmap.rb
pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin_all_from "app/javascript/controllers", under: "controllers"
```

---

### 7. Database 인덱스

자주 조회되는 컬럼에 인덱스 적용.

**적용된 인덱스**:
```ruby
# 사용자 검색
add_index :users, :email, unique: true
add_index :users, :name

# 게시글 조회
add_index :posts, :user_id
add_index :posts, [:user_id, :created_at]
add_index :posts, :status
add_index :posts, :category

# 채팅
add_index :messages, :chat_room_id
add_index :chat_room_participants, [:user_id, :chat_room_id]

# Polymorphic 관계
add_index :likes, [:likeable_type, :likeable_id]
add_index :bookmarks, [:bookmarkable_type, :bookmarkable_id]
```

---

## 개선 필요 영역

### 1. N+1 쿼리 문제

**현재 문제**:
많은 컨트롤러에서 `includes`가 적용되지 않아 N+1 쿼리 발생.

**해결 방법**:
```ruby
# Before (N+1)
@posts = Post.all
# 각 post마다 user, likes, bookmarks 추가 쿼리

# After (Eager Loading)
@posts = Post.includes(:user, :likes, :bookmarks)
             .order(created_at: :desc)
             .page(params[:page])
```

**적용 대상 컨트롤러**:
- `posts_controller.rb`
- `chat_rooms_controller.rb`
- `profiles_controller.rb`
- `search_controller.rb`

---

### 2. 이미지 Variants (썸네일)

**현재 문제**:
원본 이미지를 그대로 로드하여 대역폭 낭비.

**해결 방법**:
```ruby
# app/models/user.rb
def avatar_thumbnail
  avatar.variant(resize_to_fill: [100, 100])
end

def avatar_medium
  avatar.variant(resize_to_fill: [300, 300])
end

# 뷰에서 사용
<%= image_tag user.avatar_thumbnail %>
```

---

### 3. 배경 작업 활용

**현재 문제**:
알림, 이메일 등이 동기적으로 처리되어 응답 지연.

**해결 방법**:
```ruby
# app/jobs/notification_job.rb
class NotificationJob < ApplicationJob
  queue_as :default

  def perform(notification_id)
    notification = Notification.find(notification_id)
    # 알림 처리 로직
  end
end

# 컨트롤러에서 비동기 호출
NotificationJob.perform_later(@notification.id)
```

---

### 4. Fragment Caching

**현재 문제**:
동일한 뷰 fragment가 반복 렌더링.

**해결 방법**:
```erb
<%# app/views/posts/_post.html.erb %>
<% cache post do %>
  <div class="post-card">
    <%= post.title %>
    <%= post.user.name %>
  </div>
<% end %>
```

---

### 5. 검색 최적화

**현재 문제**:
LIKE 쿼리로 전체 테이블 스캔.

**해결 방법 (향후)**:
```ruby
# PostgreSQL 전환 후
gem 'pg_search'

# 또는 Elasticsearch
gem 'searchkick'
```

---

## 모니터링 도구

### 개발 환경

**Bullet Gem** (N+1 쿼리 감지):
```ruby
# Gemfile
gem 'bullet', group: :development

# config/environments/development.rb
config.after_initialize do
  Bullet.enable = true
  Bullet.alert = true
  Bullet.console = true
end
```

### 프로덕션 환경 (향후)

- **New Relic / Scout**: APM 모니터링
- **Sentry**: 에러 트래킹
- **Skylight**: 성능 프로파일링

---

## 성능 체크리스트

### 코드 작성 시
- [ ] `includes`로 연관 모델 eager loading
- [ ] Counter cache 활용 가능한지 확인
- [ ] 뷰에서 N+1 쿼리 발생하지 않는지 확인
- [ ] 이미지는 적절한 variant 사용

### 배포 전
- [ ] Bullet gem으로 N+1 쿼리 체크
- [ ] 개발 로그에서 쿼리 수 확인
- [ ] 이미지 최적화 확인
- [ ] 캐시 설정 확인

### 프로덕션
- [ ] 응답 시간 모니터링
- [ ] 데이터베이스 쿼리 시간 확인
- [ ] 메모리 사용량 확인
- [ ] 에러 로그 확인

---

## 벤치마크 기준

| 지표 | 목표 | 현재 |
|------|------|------|
| 페이지 로드 시간 | < 2초 | 측정 필요 |
| Time to First Byte | < 200ms | 측정 필요 |
| 데이터베이스 쿼리 수 | < 20/요청 | 개선 필요 |
| 메모리 사용량 | < 512MB | 측정 필요 |

---

## 참고 자료

- [Rails Performance Best Practices](https://guides.rubyonrails.org/active_record_querying.html#eager-loading-associations)
- [Bullet Gem](https://github.com/flyerhzm/bullet)
- [Hotwire Performance](https://hotwired.dev)
- [SQLite Performance in Rails 8](https://rubyonrails.org/2024/11/7/rails-8-no-paas-required)
