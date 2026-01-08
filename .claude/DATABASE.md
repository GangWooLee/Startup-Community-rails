# Database Design

## 문서 정보
- **프로젝트**: Startup Community Platform
- **DBMS**: SQLite3 (dev) / PostgreSQL (prod)
- **ORM**: ActiveRecord (Rails 8.1)
- **업데이트**: 2026-01-08

---

## 1. ERD (Entity Relationship Diagram)

```
┌─────────────────────┐
│       users         │
├─────────────────────┤
│ id (PK)             │◄──────────┐
│ email               │           │ has_many
│ password_digest     │           │
│ name                │           │
│ role_title          │           │
│ bio                 │           │
│ avatar_url          │           │
│ created_at          │           │
│ updated_at          │           │
└─────────────────────┘           │
         │                        │
         │ has_many               │
         │                        │
         ├────────────────────────┼────────────┐
         │                        │            │
         │                        │            │
┌────────▼──────────┐  ┌─────────▼───────┐  ┌▼───────────────┐
│      posts        │  │   job_posts     │  │ talent_listings│
├───────────────────┤  ├─────────────────┤  ├────────────────┤
│ id (PK)           │  │ id (PK)         │  │ id (PK)        │
│ user_id (FK)      │  │ user_id (FK)    │  │ user_id (FK)   │
│ title             │  │ title           │  │ title          │
│ content           │  │ description     │  │ description    │
│ status            │  │ category        │  │ category       │
│ views_count       │  │ project_type    │  │ project_type   │
│ created_at        │  │ budget          │  │ rate           │
│ updated_at        │  │ status          │  │ status         │
└───────────────────┘  │ views_count     │  │ views_count    │
         │             │ created_at      │  │ created_at     │
         │ has_many    │ updated_at      │  │ updated_at     │
         │             └─────────────────┘  └────────────────┘
┌────────▼──────────┐
│     comments      │
├───────────────────┤
│ id (PK)           │
│ post_id (FK)      │◄─────┐
│ user_id (FK)      │      │ belongs_to
│ content           │      │
│ created_at        │      │
│ updated_at        │      │
└───────────────────┘      │
                           │
┌──────────────────┐       │
│      likes       │       │
├──────────────────┤       │
│ id (PK)          │       │
│ user_id (FK)     │       │
│ likeable_id      │───────┘
│ likeable_type    │  (polymorphic)
│ created_at       │
└──────────────────┘

┌──────────────────┐
│    bookmarks     │
├──────────────────┤
│ id (PK)          │
│ user_id (FK)     │
│ bookmarkable_id  │───────┐
│ bookmarkable_type│       │ (polymorphic)
│ created_at       │       │
└──────────────────┘       │
                           │
                   (posts, job_posts,
                    talent_listings)
```

---

## 2. 테이블 스키마

### 2.1 users (사용자)

```ruby
create_table :users do |t|
  t.string :email, null: false
  t.string :password_digest, null: false
  t.string :name, null: false
  t.string :role_title            # 역할: Founder, Developer, Designer 등
  t.text :bio                     # 한줄 소개
  t.string :avatar_url            # 프로필 사진 (Active Storage 사용 시 불필요)
  t.datetime :last_sign_in_at
  t.boolean :is_admin, default: false  # 관리자 여부 (Admin 패널 접근 권한)

  # 프로필 확장 필드
  t.string :affiliation           # 소속
  t.text :skills                  # 기술 스택 (쉼표 구분)
  t.string :open_chat_url         # 오픈채팅 URL
  t.string :github_url            # GitHub URL
  t.string :portfolio_url         # 포트폴리오 URL
  t.text :activity_status         # 활동 상태 (JSON, 다중 선택)
  t.string :custom_status         # 기타 활동 상태

  # 회원 탈퇴 관련
  t.datetime :deleted_at            # Soft Delete (탈퇴 시각)

  t.timestamps
end

add_index :users, :email, unique: true
add_index :users, :is_admin
add_index :users, :deleted_at        # 탈퇴 회원 필터링
```

**컬럼 설명**:
- `email`: 로그인 ID (unique)
- `password_digest`: bcrypt 암호화된 비밀번호
- `name`: 사용자 표시 이름
- `role_title`: 직무/역할 (Founder, Developer, Designer, PM 등)
- `bio`: 간단한 자기소개
- `avatar_url`: 프로필 이미지 URL
- `last_sign_in_at`: 마지막 로그인 시각
- `is_admin`: 관리자 여부 (Admin 패널 접근 권한)
- `affiliation`: 소속 (회사, 학교 등)
- `skills`: 기술 스택 (쉼표로 구분된 문자열)
- `open_chat_url`: 오픈채팅 URL
- `github_url`: GitHub 프로필 URL
- `portfolio_url`: 포트폴리오 URL
- `activity_status`: 활동 상태 (JSON, 다중 선택 - 외주 가능, 팀 구하는 중 등)
- `custom_status`: 사용자 정의 활동 상태
- `deleted_at`: 탈퇴 시각 (NULL이면 활동 중, 값이 있으면 탈퇴)

**모델 관계**:
```ruby
class User < ApplicationRecord
  has_secure_password

  has_many :posts, dependent: :destroy
  has_many :job_posts, dependent: :destroy
  has_many :talent_listings, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :bookmarks, dependent: :destroy

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :password, length: { minimum: 6 }, if: -> { password.present? }
end
```

---

### 2.2 posts (커뮤니티 게시글)

```ruby
create_table :posts do |t|
  t.references :user, null: false, foreign_key: true
  t.string :title, null: false
  t.text :content, null: false
  t.integer :status, default: 0, null: false  # enum: draft, published, archived
  t.integer :views_count, default: 0
  t.integer :likes_count, default: 0         # counter_cache
  t.integer :comments_count, default: 0      # counter_cache

  t.timestamps
end

add_index :posts, [:user_id, :created_at]
add_index :posts, :status
add_index :posts, :created_at
```

**컬럼 설명**:
- `user_id`: 작성자 (FK)
- `title`: 제목 (max 255자)
- `content`: 본문 (text)
- `status`: 상태 (0: draft, 1: published, 2: archived)
- `views_count`: 조회수
- `likes_count`: 좋아요 수 (counter_cache)
- `comments_count`: 댓글 수 (counter_cache)

**모델 관계**:
```ruby
class Post < ApplicationRecord
  belongs_to :user
  has_many :comments, dependent: :destroy
  has_many :likes, as: :likeable, dependent: :destroy
  has_many :bookmarks, as: :bookmarkable, dependent: :destroy

  enum status: { draft: 0, published: 1, archived: 2 }

  validates :title, presence: true, length: { maximum: 255 }
  validates :content, presence: true

  scope :published, -> { where(status: :published) }
  scope :recent, -> { order(created_at: :desc) }
  scope :popular, -> { order(likes_count: :desc, views_count: :desc) }
end
```

---

### 2.3 comments (댓글)

```ruby
create_table :comments do |t|
  t.references :post, null: false, foreign_key: true
  t.references :user, null: false, foreign_key: true
  t.text :content, null: false

  t.timestamps
end

add_index :comments, [:post_id, :created_at]
add_index :comments, :user_id
```

**컬럼 설명**:
- `post_id`: 게시글 (FK)
- `user_id`: 작성자 (FK)
- `content`: 댓글 내용

**모델 관계**:
```ruby
class Comment < ApplicationRecord
  belongs_to :post, counter_cache: true
  belongs_to :user

  validates :content, presence: true, length: { minimum: 1, maximum: 1000 }

  scope :recent, -> { order(created_at: :desc) }
end
```

---

### 2.4 job_posts (구인 공고)

```ruby
create_table :job_posts do |t|
  t.references :user, null: false, foreign_key: true
  t.string :title, null: false
  t.text :description, null: false
  t.integer :category, default: 0, null: false     # enum
  t.integer :project_type, default: 0, null: false # enum
  t.string :budget                                  # optional
  t.integer :status, default: 0, null: false        # enum
  t.integer :views_count, default: 0

  t.timestamps
end

add_index :job_posts, [:user_id, :created_at]
add_index :job_posts, :category
add_index :job_posts, :status
add_index :job_posts, :created_at
```

**컬럼 설명**:
- `user_id`: 작성자 (FK)
- `title`: 공고 제목
- `description`: 상세 설명
- `category`: 카테고리 (0: development, 1: design, 2: pm, 3: marketing)
- `project_type`: 프로젝트 타입 (0: short_term, 1: long_term, 2: one_time)
- `budget`: 예산 (optional, string)
- `status`: 상태 (0: open, 1: closed, 2: filled)
- `views_count`: 조회수

**모델 관계**:
```ruby
class JobPost < ApplicationRecord
  belongs_to :user
  has_many :bookmarks, as: :bookmarkable, dependent: :destroy

  enum category: { development: 0, design: 1, pm: 2, marketing: 3 }
  enum project_type: { short_term: 0, long_term: 1, one_time: 2 }
  enum status: { open: 0, closed: 1, filled: 2 }

  validates :title, presence: true, length: { maximum: 255 }
  validates :description, presence: true

  scope :open_positions, -> { where(status: :open) }
  scope :recent, -> { order(created_at: :desc) }
end
```

---

### 2.5 talent_listings (구직 정보)

```ruby
create_table :talent_listings do |t|
  t.references :user, null: false, foreign_key: true
  t.string :title, null: false
  t.text :description, null: false
  t.integer :category, default: 0, null: false     # enum
  t.integer :project_type, default: 0, null: false # enum
  t.string :rate                                    # 희망 시급/일당 (optional)
  t.integer :status, default: 0, null: false        # enum
  t.integer :views_count, default: 0

  t.timestamps
end

add_index :talent_listings, [:user_id, :created_at]
add_index :talent_listings, :category
add_index :talent_listings, :status
add_index :talent_listings, :created_at
```

**컬럼 설명**:
- `user_id`: 작성자 (FK)
- `title`: 제목 (예: "풀스택 개발자 구직합니다")
- `description`: 상세 설명 (경력, 포트폴리오 등)
- `category`: 카테고리 (development, design, pm, marketing)
- `project_type`: 선호 프로젝트 타입
- `rate`: 희망 시급/일당
- `status`: 상태 (0: available, 1: unavailable)
- `views_count`: 조회수

**모델 관계**:
```ruby
class TalentListing < ApplicationRecord
  belongs_to :user
  has_many :bookmarks, as: :bookmarkable, dependent: :destroy

  enum category: { development: 0, design: 1, pm: 2, marketing: 3 }
  enum project_type: { short_term: 0, long_term: 1, one_time: 2 }
  enum status: { available: 0, unavailable: 1 }

  validates :title, presence: true, length: { maximum: 255 }
  validates :description, presence: true

  scope :available, -> { where(status: :available) }
  scope :recent, -> { order(created_at: :desc) }
end
```

---

### 2.6 likes (좋아요) - Polymorphic

```ruby
create_table :likes do |t|
  t.references :user, null: false, foreign_key: true
  t.references :likeable, polymorphic: true, null: false

  t.timestamps
end

add_index :likes, [:user_id, :likeable_type, :likeable_id], unique: true, name: 'index_likes_on_user_and_likeable'
add_index :likes, [:likeable_type, :likeable_id]
```

**컬럼 설명**:
- `user_id`: 좋아요를 누른 사용자 (FK)
- `likeable_id`: 좋아요 대상 ID
- `likeable_type`: 좋아요 대상 타입 (Post 등)

**모델 관계**:
```ruby
class Like < ApplicationRecord
  belongs_to :user
  belongs_to :likeable, polymorphic: true, counter_cache: true

  validates :user_id, uniqueness: { scope: [:likeable_type, :likeable_id] }
end
```

---

### 2.7 bookmarks (스크랩) - Polymorphic

```ruby
create_table :bookmarks do |t|
  t.references :user, null: false, foreign_key: true
  t.references :bookmarkable, polymorphic: true, null: false

  t.timestamps
end

add_index :bookmarks, [:user_id, :bookmarkable_type, :bookmarkable_id], unique: true, name: 'index_bookmarks_on_user_and_bookmarkable'
add_index :bookmarks, [:bookmarkable_type, :bookmarkable_id]
add_index :bookmarks, [:user_id, :created_at]
```

**컬럼 설명**:
- `user_id`: 스크랩한 사용자 (FK)
- `bookmarkable_id`: 스크랩 대상 ID
- `bookmarkable_type`: 스크랩 대상 타입 (Post, JobPost, TalentListing)

**모델 관계**:
```ruby
class Bookmark < ApplicationRecord
  belongs_to :user
  belongs_to :bookmarkable, polymorphic: true

  validates :user_id, uniqueness: { scope: [:bookmarkable_type, :bookmarkable_id] }

  scope :recent, -> { order(created_at: :desc) }
end
```

---

### 2.8 user_deletions (회원 탈퇴 기록)

```ruby
create_table :user_deletions do |t|
  t.references :user, null: false, foreign_key: true
  t.string :status, default: "completed", null: false  # completed (즉시 익명화)
  t.string :reason_category                             # 탈퇴 사유 카테고리
  t.text :reason_detail                                 # 상세 사유
  t.datetime :requested_at, null: false                 # 탈퇴 요청 시각
  t.datetime :permanently_deleted_at                    # 완전 삭제 시각
  t.datetime :destroy_scheduled_at                      # 5년 후 자동 파기 예정일

  # 암호화된 개인정보 (Rails Active Record Encryption)
  t.string :email_original                              # encrypts - 원본 이메일
  t.string :name_original                               # encrypts - 원본 이름
  t.string :phone_original                              # encrypts - 원본 전화번호
  t.text :snapshot_data                                 # encrypts - 프로필 스냅샷 (JSON)
  t.string :email_hash                                  # encrypts deterministic - 검색용

  # 활동 통계
  t.json :user_snapshot, null: false                    # 탈퇴 시점 사용자 정보
  t.json :activity_stats                                # 활동 통계 (게시글, 댓글 수 등)

  # 메타 정보
  t.string :ip_address                                  # 탈퇴 요청 IP
  t.string :user_agent                                  # 탈퇴 요청 브라우저
  t.integer :admin_view_count, default: 0               # 관리자 열람 횟수
  t.datetime :last_viewed_at                            # 마지막 열람 시각
  t.integer :last_viewed_by                             # 마지막 열람 관리자 ID

  t.timestamps
end

add_index :user_deletions, :user_id
add_index :user_deletions, :status
add_index :user_deletions, :destroy_scheduled_at
add_index :user_deletions, :email_hash                  # deterministic 암호화로 검색 가능
```

**컬럼 설명**:
- `status`: 탈퇴 상태 (completed: 즉시 익명화 완료)
- `reason_category`: 탈퇴 사유 카테고리 (not_using, privacy_concern 등)
- `email_original`: 암호화된 원본 이메일 (Rails encrypts)
- `email_hash`: 결정적 암호화 이메일 해시 (재가입 방지, 검색용)
- `destroy_scheduled_at`: 5년 후 자동 파기 예정일

**탈퇴 사유 카테고리**:
```ruby
REASON_CATEGORIES = {
  "not_using" => "서비스를 더 이상 사용하지 않음",
  "found_alternative" => "다른 서비스로 이동",
  "privacy_concern" => "개인정보 보호 우려",
  "too_many_notifications" => "알림이 너무 많음",
  "not_useful" => "유용한 정보가 없음",
  "technical_issues" => "기술적 문제",
  "other" => "기타"
}
```

**모델 관계**:
```ruby
class UserDeletion < ApplicationRecord
  belongs_to :user

  # Rails 7 Active Record Encryption
  encrypts :email_original
  encrypts :name_original
  encrypts :phone_original
  encrypts :snapshot_data
  encrypts :email_hash, deterministic: true  # 검색 가능

  RETENTION_PERIOD = 5.years

  before_create :set_destroy_scheduled_at

  scope :expired, -> { where("destroy_scheduled_at <= ?", Time.current) }
  scope :expiring_soon, -> { where("destroy_scheduled_at <= ?", 30.days.from_now) }

  def reason_label
    REASON_CATEGORIES[reason_category] || "미선택"
  end
end
```

---

### 2.9 admin_view_logs (관리자 열람 로그)

```ruby
create_table :admin_view_logs do |t|
  t.references :admin, null: false, foreign_key: { to_table: :users }
  t.references :target, polymorphic: true, null: false
  t.string :action, null: false                         # 열람 동작 (reveal_personal_info 등)
  t.text :reason, null: false                           # 열람 사유 (필수)
  t.string :ip_address                                  # 접근 IP
  t.string :user_agent                                  # 접근 브라우저

  t.timestamps
end

add_index :admin_view_logs, :admin_id
add_index :admin_view_logs, [:target_type, :target_id]
add_index :admin_view_logs, :created_at
```

**컬럼 설명**:
- `admin_id`: 열람한 관리자 (FK → users)
- `target_type`: 열람 대상 타입 (UserDeletion 등)
- `target_id`: 열람 대상 ID
- `action`: 수행한 동작 (reveal_personal_info)
- `reason`: 열람 사유 (필수 - 법적 분쟁 등)

**모델 관계**:
```ruby
class AdminViewLog < ApplicationRecord
  belongs_to :admin, class_name: "User"
  belongs_to :target, polymorphic: true

  validates :action, presence: true
  validates :reason, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :for_deletion, ->(deletion) { where(target: deletion) }
end
```

---

### 2.10 oauth_identities (OAuth 소셜 로그인)

```ruby
create_table :oauth_identities do |t|
  t.references :user, null: false, foreign_key: true
  t.string :provider, null: false              # google_oauth2, github
  t.string :uid, null: false                   # OAuth 제공자의 사용자 ID
  t.string :email                               # OAuth 이메일

  t.timestamps
end

add_index :oauth_identities, [:provider, :uid], unique: true
add_index :oauth_identities, :user_id
```

**컬럼 설명**:
- `provider`: OAuth 제공자 (google_oauth2, github)
- `uid`: OAuth 제공자가 부여한 고유 ID
- `email`: OAuth 계정 이메일 (동일 이메일 계정 통합에 사용)

**모델 관계**:
```ruby
class OauthIdentity < ApplicationRecord
  belongs_to :user

  validates :provider, presence: true
  validates :uid, presence: true, uniqueness: { scope: :provider }
end
```

---

### 2.11 chat_rooms (채팅방)

```ruby
create_table :chat_rooms do |t|
  t.references :sender, null: false, foreign_key: { to_table: :users }
  t.references :receiver, null: false, foreign_key: { to_table: :users }

  t.timestamps
end

add_index :chat_rooms, [:sender_id, :receiver_id], unique: true
```

**컬럼 설명**:
- `sender_id`: 채팅방을 생성한 사용자 (FK → users)
- `receiver_id`: 채팅 상대방 (FK → users)

**모델 관계**:
```ruby
class ChatRoom < ApplicationRecord
  belongs_to :sender, class_name: "User"
  belongs_to :receiver, class_name: "User"
  has_many :messages, dependent: :destroy

  # 두 사용자 간 채팅방 찾기 또는 생성
  def self.find_or_create_between(user1, user2)
    room = where(sender: user1, receiver: user2)
           .or(where(sender: user2, receiver: user1))
           .first
    room || create!(sender: user1, receiver: user2)
  end
end
```

---

### 2.12 messages (채팅 메시지)

```ruby
create_table :messages do |t|
  t.references :chat_room, null: false, foreign_key: true
  t.references :sender, null: false, foreign_key: { to_table: :users }
  t.text :content, null: false
  t.datetime :read_at                           # 읽음 표시

  t.timestamps
end

add_index :messages, [:chat_room_id, :created_at]
add_index :messages, :sender_id
add_index :messages, :read_at
```

**컬럼 설명**:
- `chat_room_id`: 채팅방 (FK)
- `sender_id`: 메시지 발신자 (FK → users)
- `content`: 메시지 내용
- `read_at`: 읽음 시각 (NULL이면 안 읽음)

**모델 관계**:
```ruby
class Message < ApplicationRecord
  belongs_to :chat_room
  belongs_to :sender, class_name: "User"

  validates :content, presence: true

  scope :unread, -> { where(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }

  after_create_commit { broadcast_message }
end
```

---

### 2.13 notifications (알림)

```ruby
create_table :notifications do |t|
  t.references :user, null: false, foreign_key: true
  t.references :actor, null: false, foreign_key: { to_table: :users }
  t.references :notifiable, polymorphic: true, null: false
  t.string :action, null: false                 # liked, commented, messaged
  t.datetime :read_at                           # 읽음 표시

  t.timestamps
end

add_index :notifications, [:user_id, :read_at]
add_index :notifications, [:user_id, :created_at]
add_index :notifications, [:notifiable_type, :notifiable_id]
```

**컬럼 설명**:
- `user_id`: 알림을 받는 사용자 (FK)
- `actor_id`: 알림을 발생시킨 사용자 (FK → users)
- `notifiable_type/id`: 알림 대상 (polymorphic - Post, Comment, Message 등)
- `action`: 알림 유형 (liked, commented, messaged)
- `read_at`: 읽음 시각

**모델 관계**:
```ruby
class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :actor, class_name: "User"
  belongs_to :notifiable, polymorphic: true

  validates :action, presence: true

  scope :unread, -> { where(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }
end
```

---

### 2.14 idea_analyses (AI 아이디어 분석)

```ruby
create_table :idea_analyses do |t|
  t.references :user, null: false, foreign_key: true
  t.text :idea, null: false                     # 입력된 아이디어
  t.json :follow_up_answers                     # 추가 질문에 대한 답변
  t.json :analysis_result                       # 5개 에이전트 분석 결과
  t.string :status, default: "pending"          # pending, analyzing, completed, failed
  t.string :current_stage                       # 현재 분석 단계 (summary, target_user, market 등)
  t.string :error_message                       # 실패 시 에러 메시지

  t.timestamps
end

add_index :idea_analyses, :user_id
add_index :idea_analyses, :status
add_index :idea_analyses, :created_at
```

**컬럼 설명**:
- `idea`: 사용자가 입력한 아이디어 텍스트
- `follow_up_answers`: 추가 질문에 대한 답변 (JSON)
- `analysis_result`: 5개 에이전트 분석 결과 (JSON)
  ```json
  {
    "summary": { "content": "...", "status": "completed" },
    "target_user": { "content": "...", "status": "completed" },
    "market_analysis": { "content": "...", "status": "completed" },
    "strategy": { "content": "...", "status": "completed" },
    "scoring": { "score": 85, "breakdown": {...}, "status": "completed" }
  }
  ```
- `status`: 분석 상태
  - `pending`: 대기 중
  - `analyzing`: 분석 중
  - `completed`: 완료
  - `failed`: 실패
- `current_stage`: 현재 진행 중인 분석 단계

**모델 관계**:
```ruby
class IdeaAnalysis < ApplicationRecord
  belongs_to :user

  validates :idea, presence: true

  enum status: {
    pending: "pending",
    analyzing: "analyzing",
    completed: "completed",
    failed: "failed"
  }

  STAGES = %w[summary target_user market_analysis strategy scoring].freeze

  def completed?
    status == "completed" && analysis_result.present?
  end

  def score
    analysis_result&.dig("scoring", "score")
  end
end
```

---

## 3. 인덱스 전략

### 3.1 Primary Index
- 모든 테이블: `id` (자동 생성)

### 3.2 Unique Index
```ruby
add_index :users, :email, unique: true
add_index :likes, [:user_id, :likeable_type, :likeable_id], unique: true
add_index :bookmarks, [:user_id, :bookmarkable_type, :bookmarkable_id], unique: true
```

### 3.3 Foreign Key Index
```ruby
# 모든 foreign key에 인덱스 추가 (t.references가 자동 생성)
add_index :posts, :user_id
add_index :comments, :post_id
add_index :comments, :user_id
add_index :job_posts, :user_id
add_index :talent_listings, :user_id
```

### 3.4 Composite Index
```ruby
# 정렬 + 필터링 쿼리 최적화
add_index :posts, [:user_id, :created_at]
add_index :posts, [:status, :created_at]
add_index :job_posts, [:user_id, :created_at]
add_index :job_posts, [:category, :status]
add_index :talent_listings, [:category, :status]
add_index :bookmarks, [:user_id, :created_at]
```

### 3.5 Enum 및 상태 컬럼
```ruby
add_index :posts, :status
add_index :job_posts, :category
add_index :job_posts, :status
add_index :talent_listings, :category
add_index :talent_listings, :status
```

---

## 4. 마이그레이션 생성 순서

```bash
# 1. User 모델
rails generate model User email:string password_digest:string name:string role_title:string bio:text avatar_url:string last_sign_in_at:datetime

# 2. Post 모델
rails generate model Post user:references title:string content:text status:integer views_count:integer likes_count:integer comments_count:integer

# 3. Comment 모델
rails generate model Comment post:references user:references content:text

# 4. JobPost 모델
rails generate model JobPost user:references title:string description:text category:integer project_type:integer budget:string status:integer views_count:integer

# 5. TalentListing 모델
rails generate model TalentListing user:references title:string description:text category:integer project_type:integer rate:string status:integer views_count:integer

# 6. Like 모델 (polymorphic)
rails generate model Like user:references likeable:references{polymorphic}

# 7. Bookmark 모델 (polymorphic)
rails generate model Bookmark user:references bookmarkable:references{polymorphic}

# 마이그레이션 실행
rails db:migrate
```

---

## 5. 쿼리 최적화 예시

### 5.1 N+1 쿼리 방지
```ruby
# ❌ Bad: N+1 쿼리
@posts = Post.all
@posts.each { |post| puts post.user.name }

# ✅ Good: Eager loading
@posts = Post.includes(:user).all
@posts.each { |post| puts post.user.name }

# ✅ Better: 필요한 것만
@posts = Post.includes(:user).select(:id, :title, :user_id, :created_at)
```

### 5.2 카운터 캐시 활용
```ruby
# posts 테이블에 likes_count, comments_count 추가
# Like, Comment 모델에서 counter_cache: true 설정

# 쿼리
post.likes_count      # DB 카운트 없이 즉시 반환
post.comments_count   # DB 카운트 없이 즉시 반환
```

### 5.3 페이지네이션
```ruby
# Pagy (추천 - 더 빠름)
@pagy, @posts = pagy(Post.published.includes(:user), items: 20)

# Kaminari
@posts = Post.published.includes(:user).page(params[:page]).per(20)
```

### 5.4 자주 사용하는 쿼리
```ruby
# 사용자의 프로필 전체 정보 (탭별)
user = User.includes(:posts, :job_posts, :talent_listings).find(id)

# 커뮤니티 피드 (최신순)
Post.published.includes(:user).order(created_at: :desc).limit(20)

# 인기 게시글
Post.published.includes(:user).order(likes_count: :desc, views_count: :desc).limit(10)

# 특정 카테고리 구인 공고
JobPost.open_positions.where(category: :development).includes(:user).recent

# 사용자의 스크랩 목록
user.bookmarks.includes(:bookmarkable).recent
```

---

## 6. 데이터 시딩

### 6.1 seeds.rb
```ruby
# db/seeds.rb

if Rails.env.development?
  # 기존 데이터 삭제
  [User, Post, Comment, JobPost, TalentListing, Like, Bookmark].each(&:destroy_all)

  # 관리자 계정
  admin = User.create!(
    email: 'admin@startup.com',
    password: 'password',
    name: 'Admin',
    role_title: 'Platform Admin',
    bio: '스타트업 커뮤니티 관리자입니다.'
  )

  # 테스트 사용자 생성 (10명)
  users = 10.times.map do |i|
    User.create!(
      email: "user#{i}@startup.com",
      password: 'password',
      name: "사용자#{i}",
      role_title: ['Founder', 'Developer', 'Designer', 'PM'].sample,
      bio: "안녕하세요, #{['Founder', 'Developer', 'Designer', 'PM'].sample}입니다."
    )
  end

  puts "✅ Created #{User.count} users"

  # 커뮤니티 게시글 생성 (30개)
  30.times do
    post = Post.create!(
      user: users.sample,
      title: ["창업 아이디어 피드백 부탁드립니다", "개발자 구합니다", "디자이너와 협업하고 싶어요",
              "마케팅 전략 조언 구합니다", "MVP 개발 어떻게 시작하나요?"].sample,
      content: "본문 내용입니다. " * 10,
      status: :published,
      views_count: rand(0..100)
    )

    # 댓글 추가 (0-5개)
    rand(0..5).times do
      Comment.create!(
        post: post,
        user: users.sample,
        content: "좋은 글이네요!"
      )
    end

    # 좋아요 추가 (0-10개)
    users.sample(rand(0..10)).each do |user|
      Like.create!(user: user, likeable: post) rescue nil
    end
  end

  puts "✅ Created #{Post.count} posts with #{Comment.count} comments and #{Like.count} likes"

  # 구인 공고 생성 (15개)
  15.times do
    JobPost.create!(
      user: users.sample,
      title: ["풀스택 개발자 구합니다", "UI/UX 디자이너 찾습니다", "마케팅 담당자 모집"].sample,
      description: "프로젝트 설명입니다. " * 5,
      category: [:development, :design, :pm, :marketing].sample,
      project_type: [:short_term, :long_term, :one_time].sample,
      budget: ["100만원", "협의 가능", "시급 3만원"].sample,
      status: :open,
      views_count: rand(0..50)
    )
  end

  puts "✅ Created #{JobPost.count} job posts"

  # 구직 정보 생성 (10개)
  10.times do
    TalentListing.create!(
      user: users.sample,
      title: ["풀스택 개발자입니다", "UI/UX 디자이너입니다", "마케팅 전문가입니다"].sample,
      description: "경력 및 포트폴리오입니다. " * 5,
      category: [:development, :design, :pm, :marketing].sample,
      project_type: [:short_term, :long_term, :one_time].sample,
      rate: ["시급 5만원", "일당 20만원", "협의 가능"].sample,
      status: :available,
      views_count: rand(0..30)
    )
  end

  puts "✅ Created #{TalentListing.count} talent listings"

  # 북마크 추가
  users.each do |user|
    Post.published.sample(rand(1..5)).each do |post|
      Bookmark.create!(user: user, bookmarkable: post) rescue nil
    end
  end

  puts "✅ Created #{Bookmark.count} bookmarks"
  puts "\n🎉 Seed data created successfully!"
  puts "📧 Admin: admin@startup.com / password"
  puts "📧 Users: user0@startup.com ~ user9@startup.com / password"
end
```

---

## 7. 프로덕션 전환 체크리스트

### PostgreSQL 마이그레이션
- [ ] `gem 'pg'` 추가
- [ ] `database.yml` 프로덕션 설정
- [ ] 환경변수 설정 (`DATABASE_URL`)
- [ ] 마이그레이션 실행
- [ ] 인덱스 재생성 확인
- [ ] Full-text search 설정 (필요 시 - pg_search gem)
- [ ] 백업 자동화 설정

---

## 변경 이력

| 날짜 | 변경사항 | 작성자 |
|------|----------|--------|
| 2025-12-31 | idea_analyses, chat_rooms, messages, notifications, oauth_identities 테이블 문서화 | Claude |
| 2025-12-30 | user_deletions, admin_view_logs 테이블 추가 (회원 탈퇴 시스템) | Claude |
| 2025-12-30 | users 테이블에 deleted_at 컬럼 추가 (Soft Delete) | Claude |
| 2025-12-27 | User 테이블에 is_admin, 프로필 확장 필드 추가 | Claude |
| 2025-11-26 | One-pager 기반 ERD 및 스키마 설계 | Claude |
