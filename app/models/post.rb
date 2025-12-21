class Post < ApplicationRecord
  # Associations
  belongs_to :user
  has_many :comments, dependent: :destroy
  has_many :likes, as: :likeable, dependent: :destroy
  has_many :bookmarks, as: :bookmarkable, dependent: :destroy

  # Active Storage - 이미지 첨부 (최대 5개)
  has_many_attached :images

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

  # 특정 사용자가 이 글에 좋아요를 눌렀는지 확인
  def liked_by?(user)
    return false unless user
    likes.exists?(user_id: user.id)
  end

  # 좋아요 토글 (좋아요 추가/취소)
  def toggle_like!(user)
    return nil unless user

    existing_like = likes.find_by(user_id: user.id)
    if existing_like
      existing_like.destroy
      false # 좋아요 취소됨
    else
      likes.create!(user_id: user.id)
      true # 좋아요 추가됨
    end
  end

  # 특정 사용자가 이 글을 스크랩했는지 확인
  def bookmarked_by?(user)
    return false unless user
    bookmarks.exists?(user_id: user.id)
  end

  # 스크랩 토글 (스크랩 추가/취소)
  def toggle_bookmark!(user)
    return nil unless user

    existing_bookmark = bookmarks.find_by(user_id: user.id)
    if existing_bookmark
      existing_bookmark.destroy
      false # 스크랩 취소됨
    else
      bookmarks.create!(user_id: user.id)
      true # 스크랩 추가됨
    end
  end

  # 스크랩 수
  def bookmarks_count
    bookmarks.count
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
end
