# Database Design

## 문서 정보
- **프로젝트**: Startup Community Platform
- **DBMS**: SQLite3 (dev) / PostgreSQL (prod)
- **ORM**: ActiveRecord (Rails 8.1)

---

## 1. ERD (Entity Relationship Diagram)

```
┌──────────────────────┐
│       users          │
├──────────────────────┤
│ id (PK)              │
│ email                │◄────┐
│ password_digest      │     │
│ name                 │     │
│ role                 │     │
│ created_at           │     │
│ updated_at           │     │
└──────────────────────┘     │
                             │
                             │ has_many
                             │
                    ┌────────┴────────┐
                    │                 │
         ┌──────────▼────────┐        │
         │      posts        │        │
         ├───────────────────┤        │
         │ id (PK)           │        │
         │ user_id (FK)      │────────┘
         │ title             │
         │ content           │
         │ status            │
         │ created_at        │
         │ updated_at        │
         └───────────────────┘

[여기에 추가 테이블 관계도 작성]
```

---

## 2. 테이블 스키마

### 2.1 users (사용자)

```ruby
create_table :users do |t|
  t.string :email, null: false
  t.string :password_digest, null: false
  t.string :name, null: false
  t.integer :role, default: 0, null: false  # enum
  t.datetime :last_sign_in_at

  t.timestamps
end

add_index :users, :email, unique: true
```

**컬럼 설명**:
- `email`: 로그인 ID (unique)
- `password_digest`: bcrypt 암호화된 비밀번호
- `name`: 사용자 표시 이름
- `role`: 권한 (0: user, 1: admin)
- `last_sign_in_at`: 마지막 로그인 시각

**모델 관계**:
```ruby
class User < ApplicationRecord
  has_secure_password

  has_many :posts, dependent: :destroy

  enum role: { user: 0, admin: 1 }

  validates :email, presence: true, uniqueness: true
  validates :name, presence: true
end
```

---

### 2.2 posts (게시글)

```ruby
create_table :posts do |t|
  t.references :user, null: false, foreign_key: true
  t.string :title, null: false
  t.text :content, null: false
  t.integer :status, default: 0, null: false  # enum
  t.integer :views_count, default: 0

  t.timestamps
end

add_index :posts, [:user_id, :created_at]
add_index :posts, :status
```

**컬럼 설명**:
- `user_id`: 작성자 (FK)
- `title`: 제목 (max 255자)
- `content`: 본문 (text)
- `status`: 상태 (0: draft, 1: published, 2: archived)
- `views_count`: 조회수

**모델 관계**:
```ruby
class Post < ApplicationRecord
  belongs_to :user

  enum status: { draft: 0, published: 1, archived: 2 }

  validates :title, presence: true, length: { maximum: 255 }
  validates :content, presence: true

  scope :published, -> { where(status: :published) }
  scope :recent, -> { order(created_at: :desc) }
end
```

---

### 2.3 [추가 테이블]

[프로젝트 요구사항에 맞게 테이블 추가]

**예시: comments (댓글)**
```ruby
create_table :comments do |t|
  t.references :post, null: false, foreign_key: true
  t.references :user, null: false, foreign_key: true
  t.text :content, null: false

  t.timestamps
end

add_index :comments, [:post_id, :created_at]
```

---

## 3. 인덱스 전략

### 3.1 Primary Index
- 모든 테이블: `id` (자동 생성)

### 3.2 Unique Index
```ruby
add_index :users, :email, unique: true
```

### 3.3 Foreign Key Index
```ruby
add_index :posts, :user_id
add_index :comments, :post_id
add_index :comments, :user_id
```

### 3.4 Composite Index
```ruby
# 정렬 + 필터링 쿼리 최적화
add_index :posts, [:user_id, :created_at]
add_index :posts, [:status, :created_at]
```

### 3.5 Full-text Search Index (PostgreSQL)
```ruby
# 추후 프로덕션 전환 시
add_index :posts, :title, using: :gin,
          opclass: :gin_trgm_ops  # trigram 검색
```

---

## 4. 데이터 타입 가이드

### 4.1 Rails 데이터 타입 매핑

| Rails Type | SQLite | PostgreSQL | 용도 |
|------------|--------|------------|------|
| `:string` | TEXT | VARCHAR(255) | 짧은 텍스트 |
| `:text` | TEXT | TEXT | 긴 텍스트 |
| `:integer` | INTEGER | INTEGER | 정수 |
| `:bigint` | INTEGER | BIGINT | 큰 정수 (ID) |
| `:decimal` | REAL | DECIMAL | 고정소수점 |
| `:float` | REAL | FLOAT | 부동소수점 |
| `:boolean` | INTEGER | BOOLEAN | 참/거짓 |
| `:datetime` | TEXT | TIMESTAMP | 날짜+시간 |
| `:date` | TEXT | DATE | 날짜만 |
| `:json` | TEXT | JSON | JSON 데이터 |

### 4.2 권장 사항
- **ID**: `bigint` (Rails 기본값)
- **금액**: `decimal` (정확도 필요)
- **퍼센트**: `float` or `decimal`
- **Enum**: `integer` + Rails enum
- **파일 경로**: `string`
- **설명/본문**: `text`

---

## 5. 마이그레이션 규칙

### 5.1 작성 원칙
```ruby
# ✅ Good: 롤백 가능
class AddStatusToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :status, :integer, default: 0
  end
end

# ❌ Bad: 롤백 불가능
class UpdateAllPostsStatus < ActiveRecord::Migration[8.1]
  def up
    Post.update_all(status: 1)
  end
end
```

### 5.2 안전한 마이그레이션
```ruby
# 컬럼 추가 (default 설정)
add_column :users, :role, :integer, default: 0, null: false

# 컬럼 삭제 (데이터 백업 후)
remove_column :users, :deprecated_field

# 인덱스 추가 (동시성 고려 - PostgreSQL)
add_index :posts, :user_id, algorithm: :concurrently

# 외래키 추가
add_foreign_key :posts, :users
```

### 5.3 데이터 마이그레이션
```ruby
# 별도 Rake Task로 분리
# lib/tasks/data_migration.rake
namespace :data do
  desc "Migrate old data format"
  task migrate_posts: :environment do
    Post.where(old_format: true).find_each do |post|
      post.update!(new_format: transform(post))
    end
  end
end
```

---

## 6. 쿼리 최적화

### 6.1 N+1 쿼리 방지
```ruby
# ❌ Bad: N+1 쿼리
@posts = Post.all
@posts.each { |post| puts post.user.name }

# ✅ Good: Eager loading
@posts = Post.includes(:user).all
@posts.each { |post| puts post.user.name }
```

### 6.2 카운터 캐시
```ruby
# posts 테이블에 comments_count 추가
add_column :posts, :comments_count, :integer, default: 0

# Comment 모델
class Comment < ApplicationRecord
  belongs_to :post, counter_cache: true
end

# 쿼리
post.comments_count  # DB 카운트 없이 즉시 반환
```

### 6.3 페이지네이션
```ruby
# Kaminari
@posts = Post.page(params[:page]).per(20)

# Pagy (더 빠름)
@pagy, @posts = pagy(Post.all)
```

---

## 7. 백업 & 복구

### 7.1 SQLite 백업
```bash
# 백업
sqlite3 storage/production.sqlite3 ".backup storage/backup.sqlite3"

# 복구
cp storage/backup.sqlite3 storage/production.sqlite3
```

### 7.2 PostgreSQL 백업 (프로덕션)
```bash
# 백업
pg_dump -Fc database_name > backup.dump

# 복구
pg_restore -d database_name backup.dump
```

---

## 8. 데이터 시딩

### 8.1 seeds.rb
```ruby
# db/seeds.rb

# 개발 환경 전용
if Rails.env.development?
  # 관리자 계정
  User.create!(
    email: 'admin@example.com',
    password: 'password',
    name: 'Admin',
    role: :admin
  )

  # 테스트 사용자
  5.times do |i|
    User.create!(
      email: "user#{i}@example.com",
      password: 'password',
      name: "User #{i}"
    )
  end

  # 샘플 게시글
  User.all.each do |user|
    3.times do
      user.posts.create!(
        title: Faker::Lorem.sentence,
        content: Faker::Lorem.paragraph,
        status: :published
      )
    end
  end
end
```

---

## 9. 참고 쿼리

### 9.1 자주 사용하는 패턴
```ruby
# 최신 게시글 10개
Post.order(created_at: :desc).limit(10)

# 특정 사용자의 게시글
User.find(id).posts

# 검색 (LIKE)
Post.where("title LIKE ?", "%#{keyword}%")

# 날짜 범위
Post.where(created_at: 1.week.ago..Time.current)

# 집계
Post.group(:user_id).count
User.joins(:posts).group('users.name').count
```

---

## 10. 프로덕션 전환 체크리스트

### PostgreSQL 마이그레이션
- [ ] `gem 'pg'` 추가
- [ ] `database.yml` 프로덕션 설정
- [ ] 환경변수 설정 (`DATABASE_URL`)
- [ ] 마이그레이션 실행
- [ ] 인덱스 재생성
- [ ] Full-text search 설정 (필요 시)
- [ ] 백업 자동화 설정

---

## 변경 이력

| 날짜 | 변경사항 | 작성자 |
|------|----------|--------|
| 2025-11-25 | 초안 작성 | - |
