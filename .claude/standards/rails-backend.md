# Rails Backend Standards

> Agent OS 스타일 표준 규칙 - Rails 백엔드 개발 시 준수해야 할 규칙들

## 1. 아키텍처 원칙

### MVC 패턴
```
Controller (얇게)     → 요청 처리, 파라미터 검증, 응답 포맷
Model (두껍게)        → 비즈니스 로직, 검증, 스코프
View (단순하게)       → 표시 로직만, 복잡한 로직은 헬퍼로
Service Object       → 복잡한 비즈니스 로직 (2개 이상 모델 조작)
Query Object         → 복잡한 쿼리 로직
```

### 디렉토리 구조
```
app/
├── controllers/
│   ├── concerns/           # 컨트롤러 공통 모듈
│   └── admin/              # 관리자 네임스페이스
├── models/
│   └── concerns/           # 모델 공통 모듈
├── services/
│   ├── ai/                 # AI 관련 서비스
│   │   ├── agents/         # 멀티에이전트
│   │   ├── orchestrators/  # 오케스트레이터
│   │   └── tools/          # AI 도구
│   └── users/              # 사용자 관련 서비스
├── jobs/                   # 백그라운드 작업 (Solid Queue)
└── queries/                # 쿼리 객체 (복잡한 쿼리)
```

## 2. 컨트롤러 규칙

### 기본 구조
```ruby
class PostsController < ApplicationController
  before_action :require_login, except: [:index, :show]
  before_action :set_post, only: [:show, :edit, :update, :destroy]
  before_action :authorize_post, only: [:edit, :update, :destroy]

  def index
    @posts = Post.includes(:user, :comments).recent.page(params[:page])
  end

  def create
    @post = current_user.posts.build(post_params)

    if @post.save
      redirect_to @post, notice: "게시글이 작성되었습니다."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def authorize_post
    redirect_to root_path, alert: "권한이 없습니다." unless @post.user == current_user
  end

  def post_params
    params.require(:post).permit(:title, :content, :category)
  end
end
```

### Strong Parameters 필수
```ruby
# ✅ 올바른 방법
def user_params
  params.require(:user).permit(:name, :email, :bio, skills: [])
end

# ❌ 금지
params.permit!  # 모든 파라미터 허용 금지
```

### N+1 쿼리 방지
```ruby
# ✅ includes 사용
@posts = Post.includes(:user, :comments).all

# ✅ joins + select (집계용)
@posts = Post.joins(:comments)
             .select("posts.*, COUNT(comments.id) as comments_count")
             .group("posts.id")

# ❌ N+1 발생
@posts.each { |post| post.user.name }  # user 쿼리 N번 실행
```

## 3. 모델 규칙

### 기본 구조
```ruby
class Post < ApplicationRecord
  # 1. 상수
  CATEGORIES = %w[free question promo hiring seeking].freeze

  # 2. Concerns/Modules
  include Searchable

  # 3. Associations
  belongs_to :user
  has_many :comments, dependent: :destroy
  has_many :likes, as: :likeable, dependent: :destroy

  # 4. Validations
  validates :title, presence: true, length: { maximum: 100 }
  validates :content, presence: true
  validates :category, inclusion: { in: CATEGORIES }

  # 5. Callbacks (최소화)
  before_save :sanitize_content

  # 6. Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :published, -> { where(published: true) }
  scope :by_category, ->(cat) { where(category: cat) }

  # 7. Class Methods
  def self.search(query)
    where("title LIKE ? OR content LIKE ?", "%#{query}%", "%#{query}%")
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

### Validation 규칙
```ruby
# 필수 필드
validates :email, presence: true, uniqueness: true

# 길이 제한 (항상 명시)
validates :name, length: { minimum: 1, maximum: 50 }
validates :bio, length: { maximum: 500 }

# 형식 검증
validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
validates :url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }, allow_blank: true

# 커스텀 에러 메시지 (한국어)
validates :password, length: { minimum: 8, message: "는 최소 8자 이상이어야 합니다" }
```

### Scope 활용
```ruby
# ✅ 체이닝 가능한 스코프
scope :active, -> { where(deleted_at: nil) }
scope :recent, -> { order(created_at: :desc) }
scope :limit_to, ->(n) { limit(n) }

# 사용: Post.active.recent.limit_to(10)

# ❌ 스코프에서 배열 반환 금지
scope :bad, -> { all.to_a }  # 체이닝 불가
```

## 4. 서비스 객체 패턴

### 기본 구조
```ruby
# app/services/users/deletion_service.rb
module Users
  class DeletionService
    attr_reader :user, :reason, :errors

    def initialize(user, reason: nil)
      @user = user
      @reason = reason
      @errors = []
    end

    def call
      return false unless valid?

      ActiveRecord::Base.transaction do
        create_deletion_record
        anonymize_user
        cleanup_associations
      end

      true
    rescue => e
      @errors << e.message
      false
    end

    private

    def valid?
      if user.nil?
        @errors << "사용자를 찾을 수 없습니다"
        return false
      end
      true
    end

    def create_deletion_record
      UserDeletion.create!(user: user, reason: reason)
    end

    def anonymize_user
      user.update!(
        email: "deleted_#{user.id}@deleted.local",
        name: "탈퇴한 사용자",
        deleted_at: Time.current
      )
    end

    def cleanup_associations
      user.oauth_identities.destroy_all
    end
  end
end
```

### 사용 시점
- 2개 이상의 모델을 조작할 때
- 외부 API 호출이 포함될 때
- 트랜잭션이 필요할 때
- 복잡한 비즈니스 로직이 있을 때

## 5. 마이그레이션 규칙

### 기본 원칙
```ruby
class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      # 외래키는 반드시 인덱스 추가
      t.references :user, null: false, foreign_key: true

      # 검색/정렬 컬럼에 인덱스
      t.string :title, null: false
      t.text :content
      t.string :category, null: false, default: "free"

      t.timestamps
    end

    # 복합 인덱스 (자주 함께 조회되는 컬럼)
    add_index :posts, [:user_id, :created_at]
    add_index :posts, :category
  end
end
```

### 롤백 가능하게 작성
```ruby
# ✅ 롤백 가능
def change
  add_column :users, :role, :string, default: "user"
end

# ✅ up/down 분리 (복잡한 경우)
def up
  execute "UPDATE users SET role = 'admin' WHERE is_admin = true"
end

def down
  execute "UPDATE users SET is_admin = true WHERE role = 'admin'"
end
```

### 데이터 마이그레이션 분리
```ruby
# 스키마 변경과 데이터 변경은 별도 마이그레이션으로
# 1. 스키마 변경
class AddStatusToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :status, :string, default: "draft"
  end
end

# 2. 데이터 마이그레이션 (별도 파일)
class BackfillPostStatus < ActiveRecord::Migration[8.1]
  def up
    Post.where(published: true).update_all(status: "published")
  end
end
```

## 6. 인증/보안 규칙

### 세션 관리
```ruby
# Session Fixation 방지
def log_in(user)
  reset_session  # 세션 ID 재생성
  session[:user_id] = user.id
end

# 완전한 로그아웃
def log_out
  reset_session
  @current_user = nil
end
```

### Remember Me 패턴
```ruby
# 토큰 생성 (평문)
user.remember_token = SecureRandom.urlsafe_base64

# DB에는 해시만 저장
user.update_column(:remember_digest, BCrypt::Password.create(token))

# 검증
BCrypt::Password.new(digest).is_password?(token)
```

### CSRF 보호
```ruby
# application_controller.rb
protect_from_forgery with: :exception

# API용 (JSON 응답)
protect_from_forgery with: :null_session
```

## 7. 백그라운드 작업 (Solid Queue)

### Job 구조
```ruby
# app/jobs/ai_analysis_job.rb
class AiAnalysisJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 3
  discard_on ActiveRecord::RecordNotFound

  def perform(analysis_id)
    analysis = IdeaAnalysis.find(analysis_id)

    result = AI::Orchestrators::AnalysisOrchestrator.new(
      idea: analysis.idea,
      follow_up_answers: analysis.follow_up_answers
    ).analyze

    analysis.update!(
      analysis_result: result,
      status: :completed
    )
  end
end
```

### 큐 우선순위
```ruby
# 우선순위 높은 작업
queue_as :critical  # 결제, 알림

# 일반 작업
queue_as :default   # AI 분석, 이메일

# 배치 작업
queue_as :low       # 통계, 정리 작업
```

## 8. 로깅 규칙

### 구조화된 로깅
```ruby
# ✅ 컨텍스트 포함
Rails.logger.info "[AUTH] User##{user.id} logged in from #{request.remote_ip}"
Rails.logger.warn "[PAYMENT] Order##{order.id} payment failed: #{error.message}"
Rails.logger.error "[AI] Analysis##{id} failed: #{e.message}"

# ❌ 민감정보 로깅 금지
Rails.logger.info "Password: #{password}"  # 절대 금지
Rails.logger.info "Token: #{api_token}"    # 절대 금지
```

### 로그 레벨
```
DEBUG  → 개발용 상세 정보
INFO   → 정상 동작 기록
WARN   → 잠재적 문제 (복구됨)
ERROR  → 오류 발생 (복구 필요)
FATAL  → 심각한 오류 (서비스 중단)
```

## 9. 에러 처리

### 컨트롤러 레벨
```ruby
class ApplicationController < ActionController::Base
  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
  rescue_from ActionController::InvalidAuthenticityToken, with: :handle_csrf_error

  private

  def handle_not_found
    respond_to do |format|
      format.html { render "errors/404", status: :not_found }
      format.json { render json: { error: "Not found" }, status: :not_found }
    end
  end
end
```

### 서비스 레벨
```ruby
class PaymentService
  class PaymentError < StandardError; end
  class InsufficientFundsError < PaymentError; end

  def charge(amount)
    raise InsufficientFundsError, "잔액이 부족합니다" if balance < amount
    # ...
  end
end
```

## 10. 금지 사항

### 절대 금지
```ruby
# ❌ SQL Injection
User.where("name = '#{params[:name]}'")  # 금지
User.where("name = ?", params[:name])     # ✅

# ❌ Mass Assignment
user.update(params[:user])               # 금지
user.update(user_params)                 # ✅

# ❌ 무한 루프 쿼리
User.all.each { |u| u.posts.count }      # N+1
User.includes(:posts).each { ... }        # ✅

# ❌ 프로덕션에서 금지
User.destroy_all
Post.delete_all
rails db:reset
rails db:drop
```

### 지양
```ruby
# 콜백 남용
after_save :send_email, :update_cache, :notify_admin  # 복잡

# God Object
class User
  # 1000줄 이상의 코드... → 분리 필요
end

# Magic Number
if user.posts.count > 10  # 의미 불명확
MAX_POSTS = 10
if user.posts.count > MAX_POSTS  # ✅
```
