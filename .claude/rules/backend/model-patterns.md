---
paths: app/models/**/*.rb
---

# 모델 작성 패턴

## 선언 순서 (필수 준수)

```ruby
class Post < ApplicationRecord
  # 1. 상수
  CATEGORIES = %w[free question promo hiring seeking].freeze
  MAX_TITLE_LENGTH = 100

  # 2. Concerns/Modules
  include Searchable

  # 3. Associations (belongs_to → has_many → has_one 순)
  belongs_to :user
  has_many :comments, dependent: :destroy
  has_many :likes, as: :likeable, dependent: :destroy
  has_one_attached :image

  # 4. Validations
  validates :title, presence: true, length: { maximum: MAX_TITLE_LENGTH }
  validates :content, presence: true
  validates :category, inclusion: { in: CATEGORIES }

  # 5. Callbacks (최소화!)
  before_save :sanitize_content

  # 6. Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :published, -> { where(published: true) }

  # 7. Class Methods
  def self.search(query)
    where("title LIKE ?", "%#{query}%")
  end

  # 8. Instance Methods
  def published?
    published_at.present?
  end

  private

  def sanitize_content
    self.content = ActionController::Base.helpers.sanitize(content)
  end
end
```

## Association 규칙

### dependent 옵션 필수
```ruby
# ❌ 고아 레코드 발생 위험
has_many :comments

# ✅ dependent 명시
has_many :comments, dependent: :destroy
has_many :likes, dependent: :delete_all  # 콜백 불필요 시
```

### Counter Cache 활용
```ruby
# 댓글 수 등 빈번한 카운팅에 사용
belongs_to :post, counter_cache: true

# Migration
add_column :posts, :comments_count, :integer, default: 0
```

## Validation 규칙

### 길이 제한 명시
```ruby
# ❌ 무제한 입력 허용 위험
validates :bio, presence: true

# ✅ 길이 제한 필수
validates :bio, presence: true, length: { maximum: 500 }
validates :name, length: { minimum: 1, maximum: 50 }
```

### 에러 메시지 한국어
```ruby
validates :email,
  presence: { message: "을(를) 입력해주세요" },
  uniqueness: { message: "이(가) 이미 사용 중입니다" }
```

## Scope 규칙

### 체이닝 가능하게
```ruby
# ✅ 체이닝 가능 - ActiveRecord::Relation 반환
scope :active, -> { where(deleted_at: nil) }
scope :recent, -> { order(created_at: :desc) }

# 사용: Post.active.recent.limit(10)

# ❌ 체이닝 불가 - 배열 반환 금지
scope :bad, -> { all.to_a }
```

## Enum 정의

```ruby
enum :status, {
  draft: 0,
  pending: 1,
  published: 2,
  archived: 3
}, prefix: true

# 사용: post.status_published?
#       post.status_published!
```
