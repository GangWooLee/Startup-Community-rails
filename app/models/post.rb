class Post < ApplicationRecord
  # Associations
  belongs_to :user
  has_many :comments, dependent: :destroy
  has_many :likes, as: :likeable, dependent: :destroy
  has_many :bookmarks, as: :bookmarkable, dependent: :destroy

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
    "other" => "기타"
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

  # 외주 글일 때 추가 검증
  validates :service_type, presence: true, if: :outsourcing?
  validates :price, numericality: { greater_than_or_equal_to: 0, allow_nil: true }

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
end
