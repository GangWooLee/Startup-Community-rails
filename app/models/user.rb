class User < ApplicationRecord
  # OAuth 사용자는 비밀번호가 없을 수 있으므로 validations: false
  has_secure_password validations: false

  # Active Storage - 프로필 이미지
  has_one_attached :avatar

  # 활동 상태 옵션 (다중 선택 가능)
  AVAILABILITY_OPTIONS = {
    "available_for_work" => { label: "외주 가능", color: "bg-green-500" },
    "looking_for_team" => { label: "팀 구하는 중", color: "bg-blue-500" },
    "hiring" => { label: "팀원 모집 중", color: "bg-purple-500" },
    "open_to_collaborate" => { label: "협업 환영", color: "bg-teal-500" },
    "employed" => { label: "재직 중", color: "bg-gray-500" },
    "student" => { label: "학생", color: "bg-orange-500" }
  }.freeze

  # Associations
  has_many :oauth_identities, dependent: :destroy
  has_many :posts, dependent: :destroy
  has_many :job_posts, dependent: :destroy
  has_many :talent_listings, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :bookmarks, dependent: :destroy

  # Validations
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true, length: { minimum: 1, maximum: 50 }
  # 일반 로그인 사용자만 비밀번호 필수
  validates :password, length: { minimum: 6 }, if: -> { password.present? && provider.blank? }
  validates :bio, length: { maximum: 500 }, allow_blank: true
  validates :role_title, length: { maximum: 50 }, allow_blank: true
  validates :affiliation, length: { maximum: 50 }, allow_blank: true
  validates :skills, length: { maximum: 200 }, allow_blank: true
  validates :custom_status, length: { maximum: 30 }, allow_blank: true

  # Callbacks
  before_save :downcase_email

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :oauth_users, -> { joins(:oauth_identities).distinct }
  scope :local_users, -> { left_joins(:oauth_identities).where(oauth_identities: { id: nil }) }

  # OAuth 사용자 생성 또는 찾기
  # 1. oauth_identities에서 provider + uid로 기존 연결 찾기
  # 2. 없으면 이메일로 기존 사용자 찾고, OAuth 연결 추가
  # 3. 없으면 새 사용자 생성 + OAuth 연결 추가
  def self.from_omniauth(auth)
    email = auth.info.email&.downcase
    provider = auth.provider
    uid = auth.uid

    # 1. oauth_identities에서 찾기
    identity = OauthIdentity.find_by(provider: provider, uid: uid)
    if identity
      # 기존 사용자는 프로필 사진 덮어쓰지 않음 (사용자가 직접 관리)
      return identity.user
    end

    # 2. 이메일로 기존 사용자 찾기
    user = find_by(email: email)

    if user
      # 기존 사용자에게 새 OAuth 연결 추가
      user.oauth_identities.create!(provider: provider, uid: uid)
      # 프로필 사진이 없을 때만 OAuth 사진 사용
      user.update(avatar_url: auth.info.image) if user.avatar_url.blank? && auth.info.image.present?
      return user
    end

    # 3. 새 사용자 생성 + OAuth 연결 (최초 가입 시에만 OAuth 사진 사용)
    user = create!(
      email: email,
      name: auth.info.name || auth.info.nickname || "User",
      password: SecureRandom.hex(20),
      avatar_url: auth.info.image
    )
    user.oauth_identities.create!(provider: provider, uid: uid)
    user
  end

  # OAuth 사용자인지 확인
  def oauth_user?
    oauth_identities.exists?
  end

  # 일반 로그인 사용자인지 확인
  def local_user?
    !oauth_user?
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

  private

  def downcase_email
    self.email = email.downcase if email.present?
  end
end
