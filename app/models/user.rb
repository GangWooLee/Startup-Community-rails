class User < ApplicationRecord
  # ==========================================================================
  # Concerns - 기능별 모듈 분리
  # ==========================================================================
  include Authenticatable       # Remember Me 인증
  include Deletable             # 회원 탈퇴 관련
  include Oauthable             # OAuth 인증 (Google, GitHub)
  include Profileable           # 프로필 (익명, 아바타, 스킬 등)
  include Experienceable        # 경력/학력/프로젝트 타임라인
  include AvailabilityStatusable # 활동 상태 (외주 가능, 팀원 모집)
  include AiAnalyzable          # AI 분석 사용량 관리
  include Termable              # 약관 동의
  include ApiTokenable          # API 토큰 (n8n 연동용, 제거 가능)
  include Messageable           # 읽지 않은 메시지 카운트
  include Followable            # 팔로우 관계
  include ActivityFeedable      # 활동 피드
  include Notifiable            # 알림 관련

  # ==========================================================================
  # Security & Configuration
  # ==========================================================================

  # OAuth 사용자는 비밀번호가 없을 수 있으므로 validations: false
  has_secure_password validations: false

  # 비밀번호 정책 상수
  MIN_PASSWORD_LENGTH = 8
  # Rails 8.1 has_secure_password는 자동으로 generates_token_for :password_reset 제공 (15분 만료)

  # ==========================================================================
  # Active Storage - 프로필/커버 이미지
  # ==========================================================================
  has_one_attached :avatar
  has_one_attached :cover_image

  # ActionText - Rich Text 상세 소개
  has_rich_text :detailed_bio

  # 파일 업로드 보안 상수
  MAX_AVATAR_SIZE = 2.megabytes
  MAX_COVER_SIZE = 5.megabytes
  ALLOWED_AVATAR_TYPES = [ "image/jpeg", "image/png", "image/gif", "image/webp" ].freeze

  # ==========================================================================
  # Associations
  # ==========================================================================

  # 게시글/댓글/좋아요/스크랩
  has_many :posts, dependent: :destroy
  has_many :job_posts, dependent: :destroy
  has_many :talent_listings, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :bookmarks, dependent: :destroy
  has_many :bookmarked_posts, through: :bookmarks, source: :bookmarkable, source_type: "Post"
  has_many :liked_posts, through: :likes, source: :likeable, source_type: "Post"
  has_many :commented_posts, -> { distinct }, through: :comments, source: :post

  # 알림 (받은 알림, 보낸 알림)
  has_many :notifications, foreign_key: :recipient_id, dependent: :destroy
  has_many :sent_notifications, class_name: "Notification", foreign_key: :actor_id, dependent: :destroy

  # 채팅
  has_many :chat_room_participants, dependent: :destroy
  has_many :chat_rooms, through: :chat_room_participants
  has_many :active_chat_room_participants, -> { active }, class_name: "ChatRoomParticipant"
  has_many :active_chat_rooms, through: :active_chat_room_participants, source: :chat_room
  has_many :sent_messages, class_name: "Message", foreign_key: :sender_id, dependent: :destroy

  # 결제/주문
  has_many :orders, dependent: :destroy                                              # 구매 내역
  has_many :sales, class_name: "Order", foreign_key: :seller_id, dependent: :destroy # 판매 내역
  has_many :payments, dependent: :destroy

  # AI 아이디어 분석
  has_many :idea_analyses, dependent: :destroy

  # 신고/문의
  has_many :reports, foreign_key: :reporter_id, dependent: :destroy  # 내가 한 신고
  has_many :received_reports, class_name: "Report", as: :reportable, dependent: :destroy  # 나를 신고
  has_many :inquiries, dependent: :destroy  # 내 문의

  # 팔로우 관계 (Self-Referential)
  has_many :active_follows, class_name: "Follow", foreign_key: :follower_id, dependent: :destroy
  has_many :passive_follows, class_name: "Follow", foreign_key: :followed_id, dependent: :destroy
  has_many :following, through: :active_follows, source: :followed
  has_many :followers, through: :passive_follows, source: :follower

  # ==========================================================================
  # Validations
  # ==========================================================================

  # 아바타 파일 검증 (보안: 악성 파일 업로드 방지)
  validates :avatar,
    content_type: {
      in: ALLOWED_AVATAR_TYPES,
      message: "는 JPEG, PNG, GIF, WebP 형식만 허용됩니다"
    },
    size: {
      less_than: MAX_AVATAR_SIZE,
      message: "는 2MB 이하만 허용됩니다"
    }

  validates :cover_image,
    content_type: {
      in: ALLOWED_AVATAR_TYPES,
      message: "는 JPEG, PNG, GIF, WebP 형식만 허용됩니다"
    },
    size: {
      less_than: MAX_COVER_SIZE,
      message: "는 5MB 이하만 허용됩니다"
    }

  # 기본 필드 검증
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true, length: { minimum: 1, maximum: 50 }

  # 일반 로그인 사용자만 비밀번호 필수 (최소 8자, 영문+숫자 조합 권장)
  validates :password,
    length: { minimum: MIN_PASSWORD_LENGTH, message: "는 최소 #{MIN_PASSWORD_LENGTH}자 이상이어야 합니다" },
    if: -> { password.present? && provider.blank? }
  validate :password_complexity, if: -> { password.present? && provider.blank? }

  # 프로필 필드 검증
  validates :bio, length: { maximum: 500 }, allow_blank: true
  # 닉네임 검증: 선택사항이지만 입력 시 유일성/길이 체크
  validates :nickname,
    uniqueness: { message: "이(가) 이미 사용 중입니다", allow_blank: true },
    length: { minimum: 2, maximum: 20, message: "은(는) 2자 이상 20자 이하여야 합니다" },
    if: -> { profile_completed? && nickname.present? }
  validates :role_title, length: { maximum: 50 }, allow_blank: true
  validates :affiliation, length: { maximum: 50 }, allow_blank: true
  validates :skills, length: { maximum: 200 }, allow_blank: true
  validates :custom_status, length: { maximum: 10 }, allow_blank: true
  validates :status_message, length: { maximum: 100 }, allow_blank: true
  validates :looking_for, length: { maximum: 200 }, allow_blank: true
  validates :location, length: { maximum: 50 }, allow_blank: true

  # URL 형식 검증 (빈 값 허용)
  validates :linkedin_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL" }, allow_blank: true
  validates :github_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL" }, allow_blank: true
  validates :portfolio_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL" }, allow_blank: true
  validates :open_chat_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL" }, allow_blank: true

  # ==========================================================================
  # Callbacks
  # ==========================================================================
  before_save :downcase_email

  # ==========================================================================
  # Scopes
  # ==========================================================================
  scope :recent, -> { order(created_at: :desc) }

  # ==========================================================================
  # Instance Methods
  # ==========================================================================

  # 관리자인지 확인
  def admin?
    is_admin == true
  end

  # ==========================================================================
  # 결제 관련 메서드
  # ==========================================================================

  # 토스페이먼츠 고객 키 (결제 시 사용)
  def toss_customer_key
    "CUST-#{Digest::SHA256.hexdigest("#{id}-#{created_at.to_i}")[0..15].upcase}"
  end

  # 해당 Post에 대한 대기 중인 주문이 있는지 확인
  def has_pending_order_for?(post)
    orders.pending.where(post: post).exists?
  end

  # 해당 Post에 대한 주문 가져오기
  def order_for(post)
    orders.find_by(post: post)
  end

  private

  def downcase_email
    self.email = email.downcase if email.present?
  end

  # 비밀번호 복잡성 검증 (영문+숫자 조합 필수)
  def password_complexity
    return if password.blank?

    unless password.match?(/[a-zA-Z]/) && password.match?(/\d/)
      errors.add(:password, "는 영문과 숫자를 모두 포함해야 합니다")
    end

    # 너무 단순한 패턴 방지 (같은 문자 연속 4개 이상)
    if password.match?(/(.)\1{3,}/)
      errors.add(:password, "에 같은 문자를 4개 이상 연속 사용할 수 없습니다")
    end
  end
end
