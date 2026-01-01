class User < ApplicationRecord
  # OAuth 사용자는 비밀번호가 없을 수 있으므로 validations: false
  has_secure_password validations: false

  # Remember Me 토큰 (DB에 저장되지 않는 가상 속성)
  attr_accessor :remember_token

  # Active Storage - 프로필 이미지
  has_one_attached :avatar

  # 아바타 파일 검증 (보안: 악성 파일 업로드 방지)
  MAX_AVATAR_SIZE = 2.megabytes
  ALLOWED_AVATAR_TYPES = ["image/jpeg", "image/png", "image/gif", "image/webp"].freeze

  validates :avatar,
    content_type: {
      in: ALLOWED_AVATAR_TYPES,
      message: "는 JPEG, PNG, GIF, WebP 형식만 허용됩니다"
    },
    size: {
      less_than: MAX_AVATAR_SIZE,
      message: "는 2MB 이하만 허용됩니다"
    }

  # 활동 상태 옵션 (다중 선택 가능)
  AVAILABILITY_OPTIONS = {
    "available_for_work" => { label: "외주 가능", color: "bg-green-500" },
    "hiring" => { label: "팀원 모집 중", color: "bg-purple-500" }
  }.freeze

  # Associations
  has_many :oauth_identities, dependent: :destroy
  has_many :posts, dependent: :destroy
  has_many :job_posts, dependent: :destroy
  has_many :talent_listings, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :bookmarks, dependent: :destroy
  has_many :bookmarked_posts, through: :bookmarks, source: :bookmarkable, source_type: "Post"

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

  # 회원 탈퇴 기록
  has_many :user_deletions, dependent: :destroy

  # 신고/문의
  has_many :reports, foreign_key: :reporter_id, dependent: :destroy  # 내가 한 신고
  has_many :received_reports, class_name: "Report", as: :reportable, dependent: :destroy  # 나를 신고
  has_many :inquiries, dependent: :destroy  # 내 문의

  # 비밀번호 정책 상수
  MIN_PASSWORD_LENGTH = 8
  # Rails 8.1 has_secure_password는 자동으로 generates_token_for :password_reset 제공 (15분 만료)

  # Validations
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true, length: { minimum: 1, maximum: 50 }
  # 일반 로그인 사용자만 비밀번호 필수 (최소 8자, 영문+숫자 조합 권장)
  validates :password,
    length: { minimum: MIN_PASSWORD_LENGTH, message: "는 최소 #{MIN_PASSWORD_LENGTH}자 이상이어야 합니다" },
    if: -> { password.present? && provider.blank? }
  validate :password_complexity, if: -> { password.present? && provider.blank? }
  validates :bio, length: { maximum: 500 }, allow_blank: true
  validates :role_title, length: { maximum: 50 }, allow_blank: true
  validates :affiliation, length: { maximum: 50 }, allow_blank: true
  validates :skills, length: { maximum: 200 }, allow_blank: true
  validates :custom_status, length: { maximum: 10 }, allow_blank: true

  # URL 형식 검증 (빈 값 허용)
  validates :linkedin_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL" }, allow_blank: true
  validates :github_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL" }, allow_blank: true
  validates :portfolio_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL" }, allow_blank: true
  validates :open_chat_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL" }, allow_blank: true

  # 재가입 방지: 탈퇴한 이메일로는 재가입 불가
  validate :check_blacklisted_email, on: :create

  # Callbacks
  before_save :downcase_email

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :oauth_users, -> { joins(:oauth_identities).distinct }
  scope :local_users, -> { left_joins(:oauth_identities).where(oauth_identities: { id: nil }) }
  scope :active, -> { where(deleted_at: nil) }
  scope :deleted, -> { where.not(deleted_at: nil) }

  # OAuth 사용자 생성 또는 찾기
  # 1. oauth_identities에서 provider + uid로 기존 연결 찾기
  # 2. 없으면 이메일로 기존 사용자 찾고, OAuth 연결 추가
  # 3. 없으면 새 사용자 생성 + OAuth 연결 추가
  # 보안: 트랜잭션으로 데이터 무결성 보장
  # 반환: { user:, deleted: } - deleted가 true면 탈퇴 처리된 사용자
  def self.from_omniauth(auth)
    email = auth.info.email&.downcase
    provider = auth.provider
    uid = auth.uid

    # 1. oauth_identities에서 찾기 (트랜잭션 외부 - 읽기만)
    identity = OauthIdentity.find_by(provider: provider, uid: uid)
    if identity
      user = identity.user
      # 탈퇴한 사용자 확인
      return { user: user, deleted: user.deleted? }
    end

    # 2, 3단계는 트랜잭션으로 묶어서 원자성 보장
    transaction do
      # 2. 이메일로 기존 사용자 찾기 (삭제된 사용자 포함)
      user = unscoped.find_by(email: email)

      if user
        # 탈퇴한 사용자 확인
        if user.deleted?
          return { user: user, deleted: true }
        end

        # 기존 사용자에게 새 OAuth 연결 추가
        user.oauth_identities.create!(provider: provider, uid: uid)
        # 프로필 사진이 없을 때만 OAuth 사진 사용
        user.update(avatar_url: auth.info.image) if user.avatar_url.blank? && auth.info.image.present?
        return { user: user, deleted: false }
      end

      # 3. 새 사용자 생성 + OAuth 연결 (최초 가입 시에만 OAuth 사진 사용)
      user = create!(
        email: email,
        name: auth.info.name || auth.info.nickname || "User",
        password: SecureRandom.hex(20),
        avatar_url: auth.info.image
      )
      user.oauth_identities.create!(provider: provider, uid: uid)
      { user: user, deleted: false }
    end
  end

  # OAuth 사용자인지 확인
  def oauth_user?
    oauth_identities.exists?
  end

  # 일반 로그인 사용자인지 확인
  def local_user?
    !oauth_user?
  end

  # OAuth만으로 가입한 사용자인지 확인 (비밀번호 재설정 불가)
  def oauth_only?
    oauth_user? && provider.present?
  end

  # 비밀번호 재설정이 가능한지 확인
  def can_reset_password?
    !oauth_only?
  end

  # Remember Me: 영구 세션용 토큰 생성 및 저장
  def remember
    self.remember_token = SecureRandom.urlsafe_base64
    update_column(:remember_digest, BCrypt::Password.create(remember_token))
  end

  # Remember Me: 토큰 삭제 (로그아웃 시)
  def forget
    update_column(:remember_digest, nil)
  end

  # Remember Me: 쿠키의 토큰이 유효한지 확인
  def authenticated?(remember_token)
    return false if remember_digest.nil?
    BCrypt::Password.new(remember_digest).is_password?(remember_token)
  end

  # 탈퇴한 사용자인지 확인
  def deleted?
    deleted_at.present?
  end

  # 활성 사용자인지 확인
  def active?
    deleted_at.nil?
  end

  # 가장 최근 탈퇴 기록 가져오기 (관리자용)
  def last_deletion
    user_deletions.order(created_at: :desc).first
  end

  # Rails 8.1 토큰 시스템 사용
  # 비밀번호 재설정: user.generate_token_for(:password_reset) / User.find_by_token_for(:password_reset, token)

  # 관리자인지 확인
  def admin?
    is_admin == true
  end

  # 연결된 OAuth provider 목록
  def connected_providers
    oauth_identities.pluck(:provider)
  end

  # 프로필 이미지 URL 반환 (Active Storage 우선, 없으면 OAuth URL, 없으면 nil)
  def profile_image_url
    if avatar.attached?
      Rails.application.routes.url_helpers.rails_blob_path(avatar, only_path: true)
    elsif avatar_url.present?
      avatar_url
    end
  end

  # 프로필 이미지가 있는지 확인
  def has_profile_image?
    avatar.attached? || avatar_url.present?
  end

  # 스킬을 배열로 반환
  def skills_array
    return [] if skills.blank?
    skills.split(",").map(&:strip).reject(&:blank?)
  end

  # 스킬 배열을 문자열로 저장
  def skills_array=(arr)
    self.skills = arr.is_a?(Array) ? arr.join(", ") : arr
  end

  # 주요 성과/포트폴리오를 배열로 반환 (줄바꿈으로 구분)
  def achievements_array
    return [] if achievements.blank?
    achievements.split("\n").map(&:strip).reject(&:blank?)
  end

  # 성과 배열을 문자열로 저장
  def achievements_array=(arr)
    self.achievements = arr.is_a?(Array) ? arr.join("\n") : arr
  end

  # 활동 상태 배열 반환 (JSON 컬럼)
  def availability_statuses_array
    availability_statuses || []
  end

  # 활동 상태가 있는지 확인
  def has_availability_status?
    availability_statuses_array.any? || custom_status.present?
  end

  # 모든 활동 상태 뱃지 정보 반환 (label, color 포함)
  def availability_badges
    badges = []

    # 선택된 기본 상태들
    availability_statuses_array.each do |status|
      if AVAILABILITY_OPTIONS[status]
        badges << {
          label: AVAILABILITY_OPTIONS[status][:label],
          color: AVAILABILITY_OPTIONS[status][:color]
        }
      end
    end

    # 기타(사용자 정의) 상태
    if custom_status.present?
      badges << {
        label: custom_status,
        color: "bg-pink-500"
      }
    end

    badges
  end

  # 특정 상태가 선택되어 있는지 확인
  def has_status?(status_key)
    availability_statuses_array.include?(status_key)
  end

  # 읽지 않은 알림 수
  def unread_notifications_count
    notifications.unread.count
  end

  # 읽지 않은 알림이 있는지 확인
  def has_unread_notifications?
    notifications.unread.exists?
  end

  # 읽지 않은 메시지 총 수
  def total_unread_messages
    chat_room_participants.sum(&:unread_count)
  end

  # 읽지 않은 메시지가 있는지 확인
  def has_unread_messages?
    total_unread_messages > 0
  end

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

  # 재가입 방지: 탈퇴한 이메일 해시와 비교
  def check_blacklisted_email
    return if email.blank?

    email_hash = Digest::SHA256.hexdigest(email.to_s.downcase.strip)
    if UserDeletion.exists?(email_hash: email_hash)
      errors.add(:email, "이전에 탈퇴한 이메일입니다. 다른 이메일로 가입하거나 고객센터에 문의해주세요.")
    end
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
