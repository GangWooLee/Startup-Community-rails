class Post < ApplicationRecord
  # Concerns
  include Likeable
  include Bookmarkable

  # Associations
  belongs_to :user
  has_many :comments, dependent: :destroy
  has_many :notifications, as: :notifiable, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :reports, as: :reportable, dependent: :destroy

  # Active Storage - 이미지 첨부 (최대 5개)
  has_many_attached :images

  # 이미지 파일 검증 (보안: 악성 파일 업로드 방지)
  MAX_IMAGES = 5
  MAX_IMAGE_SIZE = 5.megabytes
  ALLOWED_IMAGE_TYPES = ["image/jpeg", "image/png", "image/gif", "image/webp"].freeze

  validates :images,
    content_type: {
      in: ALLOWED_IMAGE_TYPES,
      message: "는 JPEG, PNG, GIF, WebP 형식만 허용됩니다"
    },
    size: {
      less_than: MAX_IMAGE_SIZE,
      message: "는 5MB 이하만 허용됩니다"
    }
  validate :images_count_within_limit

  # 이미지 개수 제한 검증
  def images_count_within_limit
    return unless images.attached?
    if images.count > MAX_IMAGES
      errors.add(:images, "는 최대 #{MAX_IMAGES}개까지만 첨부할 수 있습니다")
    end
  end

  # Enums
  enum :status, { draft: 0, published: 1, archived: 2 }, default: :draft

  # 카테고리: 커뮤니티 + 외주 통합
  enum :category, {
    free: 0,        # 자유게시판
    question: 1,    # 질문
    promotion: 2,   # 홍보
    hiring: 3,      # 외주 (구인 - 사람 찾아요)
    seeking: 4      # 외주 (구직 - 일 해드려요)
  }, default: :free

  # 서비스 분야 상수 (외주용)
  SERVICE_TYPES = {
    "planning" => "기획",
    "design" => "디자인",
    "development" => "개발",
    "marketing" => "마케팅",
    "video" => "영상",
    "other" => "기타"
  }.freeze

  # 진행 방식 상수
  WORK_TYPES = {
    "remote" => "재택(원격)",
    "onsite" => "오프라인(상주)",
    "hybrid" => "혼합(협의)"
  }.freeze

  # 카테고리 라벨 (한글)
  CATEGORY_LABELS = {
    "free" => "자유",
    "question" => "질문",
    "promotion" => "홍보",
    "hiring" => "구인",
    "seeking" => "구직"
  }.freeze

  # Validations
  validates :title, presence: true, length: { minimum: 1, maximum: 255 }
  validates :content, presence: true, length: { minimum: 1 }
  validates :status, presence: true
  validates :category, presence: true

  # 외주 글 공통 검증
  validates :service_type, presence: { message: "를 선택해주세요" }, if: :outsourcing?
  validates :price, numericality: { greater_than_or_equal_to: 0, allow_nil: true }

  # 구인(Hiring) 글일 때 추가 검증
  with_options if: :hiring? do |post|
    post.validates :work_type, presence: { message: "을 선택해주세요" }
  end

  # 구직(Seeking) 글일 때 추가 검증 (포트폴리오는 선택사항으로 유지)
  with_options if: :seeking? do |post|
    # portfolio_url은 권장하지만 필수는 아님 (신규 유저 진입장벽 낮춤)
    post.validates :portfolio_url, format: {
      with: URI::DEFAULT_PARSER.make_regexp(%w[http https]),
      message: "은 유효한 URL 형식이어야 합니다",
      allow_blank: true
    }
  end

  # Scopes
  scope :published, -> { where(status: :published) }
  scope :recent, -> { order(created_at: :desc) }
  scope :popular, -> { order(likes_count: :desc, views_count: :desc) }
  scope :community, -> { where(category: [:free, :question, :promotion]) }
  scope :outsourcing, -> { where(category: [:hiring, :seeking]) }
  scope :by_category, ->(cat) { where(category: cat) if cat.present? }

  # Instance methods
  def increment_views!
    increment!(:views_count)
  end

  # 외주 글인지 확인
  def outsourcing?
    hiring? || seeking?
  end

  # 커뮤니티 글인지 확인
  def community?
    free? || question? || promotion?
  end

  # 카테고리 한글 라벨
  def category_label
    CATEGORY_LABELS[category] || category
  end

  # 서비스 타입 한글 라벨
  def service_type_label
    SERVICE_TYPES[service_type] || service_type
  end

  # 가격 표시 (협의 가능 포함)
  def price_display
    return "협의" if price_negotiable? || price.nil? || price.zero?
    "#{price.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}원"
  end

  # 진행 방식 한글 라벨
  def work_type_label
    WORK_TYPES[work_type] || work_type
  end

  # 기술 스택 배열로 변환
  def skills_array
    skills.to_s.split(",").map(&:strip).reject(&:blank?)
  end

  # 작업 가능 상태 라벨
  def availability_label
    available_now? ? "작업 가능" : "작업 불가"
  end

  # 작업 가능 상태 색상 클래스
  def availability_color_class
    available_now? ? "text-green-600 bg-green-100" : "text-gray-500 bg-gray-100"
  end

  # 예산 표시 (채팅 컨텍스트 카드용)
  def budget
    price_display
  end

  # 기간 표시 (채팅 컨텍스트 카드용)
  def duration
    work_period.presence
  end

  # 검색용 본문 스니펫 생성 (검색어 주변 텍스트 추출)
  def content_snippet(query = nil, max_length: 100)
    return content.truncate(max_length) if query.blank?

    # 검색어가 포함된 위치 찾기
    query_pos = content.downcase.index(query.downcase)

    if query_pos
      # 검색어 앞뒤로 텍스트 추출
      start_pos = [query_pos - 30, 0].max
      end_pos = [query_pos + query.length + 70, content.length].min

      snippet = content[start_pos...end_pos]
      snippet = "..." + snippet if start_pos > 0
      snippet = snippet + "..." if end_pos < content.length
      snippet
    else
      content.truncate(max_length)
    end
  end

  # ===== 결제 관련 메서드 =====

  # 결제 가능한 글인지 확인 (외주 글 + 가격이 설정됨)
  def payable?
    outsourcing? && price.present? && price.positive?
  end

  # 특정 사용자가 이 글에 대해 주문을 했는지 확인 (취소된 주문 제외)
  def ordered_by?(user)
    return false unless user

    orders.where(user: user).where.not(status: :cancelled).exists?
  end

  # 특정 사용자가 이 글에 대해 결제 완료했는지 확인
  def paid_by?(user)
    return false unless user

    orders.paid.where(user: user).exists?
  end

  # 작성자 본인 글인지 확인
  def owned_by?(user)
    return false unless user

    user_id == user.id
  end

  # 결제 가능 상태인지 (본인 글 아님 + 결제 가능 + 아직 결제 안함)
  def can_be_ordered_by?(user)
    return false unless user
    return false if owned_by?(user)
    return false unless payable?
    return false if paid_by?(user)

    true
  end
end
