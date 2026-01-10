class ChatRoom < ApplicationRecord
  has_many :participants, class_name: "ChatRoomParticipant", dependent: :destroy
  has_many :users, through: :participants
  has_many :messages, dependent: :destroy
  has_many :orders, dependent: :nullify
  has_many :reports, as: :reportable, dependent: :destroy

  # 현재 활성화된 주문 (취소/환불 제외)
  has_one :active_order, -> { where.not(status: [ :cancelled, :refunded ]).order(created_at: :desc) }, class_name: "Order"

  # 컨텍스트: 어떤 게시글을 통해 시작된 대화인지
  belongs_to :source_post, class_name: "Post", optional: true
  # 대화를 먼저 시작한 사람 (지원자/문의자)
  belongs_to :initiator, class_name: "User", optional: true

  # 거래 상태
  enum :deal_status, { pending: "pending", confirmed: "confirmed", cancelled: "cancelled" }, default: :pending

  scope :recent, -> { order(last_message_at: :desc) }

  # 필터링 스코프: 받은 문의 (내 게시글에 대한 문의)
  scope :received_inquiries, ->(user) {
    joins(:source_post)
      .where(posts: { user_id: user.id })
      .where.not(initiator_id: user.id)
  }

  # 필터링 스코프: 보낸 문의 (내가 시작한 대화)
  scope :sent_inquiries, ->(user) {
    where(initiator_id: user.id)
  }

  # 검색 스코프: 상대방 이름 또는 게시글 제목으로 검색
  scope :search_by_keyword, ->(keyword, current_user) {
    return all if keyword.blank?

    joins("LEFT JOIN posts ON posts.id = chat_rooms.source_post_id")
      .joins(:users)
      .where.not(users: { id: current_user.id })
      .where("users.name LIKE :keyword OR posts.title LIKE :keyword",
             keyword: "%#{keyword}%")
      .distinct
  }

  # 게시글 컨텍스트가 있는 채팅방 찾기 또는 생성
  def self.find_or_create_for_post(post:, initiator:, post_author:)
    return nil if post.nil? || initiator.nil? || post_author.nil?
    return nil if initiator.id == post_author.id

    # 해당 게시글에 대한 두 사람 간의 기존 채팅방 찾기
    room = joins(:participants)
           .where(source_post: post)
           .where(chat_room_participants: { user_id: [ initiator.id, post_author.id ] })
           .group(:id)
           .having("COUNT(chat_room_participants.id) = 2")
           .first

    return room if room

    # 새 채팅방 생성
    transaction do
      room = create!(source_post: post, initiator: initiator)
      room.participants.create!(user: initiator)
      room.participants.create!(user: post_author)

      # 시스템 메시지 생성: 어떤 글을 통한 대화인지 알림
      room.messages.create!(
        sender: initiator,
        content: "#{initiator.name}님이 '#{post.title.truncate(30)}' 글을 통해 대화를 요청했습니다.",
        message_type: "system"
      )

      room
    end
  end

  # 두 사용자 간 기존 채팅방 찾기 (생성 없이 조회만)
  # 게시글 컨텍스트가 없는 1:1 채팅방만 검색
  def self.find_existing_between(user1, user2)
    return nil if user1.nil? || user2.nil? || user1.id == user2.id

    joins(:participants)
      .where(source_post_id: nil)
      .where(chat_room_participants: { user_id: [ user1.id, user2.id ] })
      .group(:id)
      .having("COUNT(chat_room_participants.id) = 2")
      .first
  end

  # 1:1 채팅방 찾기 또는 생성 (게시글 컨텍스트 없이 - 프로필에서 직접 대화)
  def self.find_or_create_between(user1, user2, source_post: nil, initiator: nil)
    return nil if user1.nil? || user2.nil? || user1.id == user2.id

    # 기존 채팅방 찾기 (source_post가 없는 경우만)
    if source_post.nil?
      room = joins(:participants)
             .where(source_post_id: nil)
             .where(chat_room_participants: { user_id: [ user1.id, user2.id ] })
             .group(:id)
             .having("COUNT(chat_room_participants.id) = 2")
             .first

      return room if room
    end

    # 새 채팅방 생성
    transaction do
      room = create!(source_post: source_post, initiator: initiator || user1)
      room.participants.create!(user: user1)
      room.participants.create!(user: user2)
      room
    end
  end

  # 상대방 가져오기
  # includes(:users)로 preload된 경우 추가 쿼리 없이 Ruby에서 처리
  def other_participant(current_user)
    if users.loaded?
      users.find { |u| u.id != current_user.id }
    else
      users.where.not(id: current_user.id).first
    end
  end

  # 마지막 메시지
  # includes(:messages)로 preload된 경우 추가 쿼리 없이 Ruby에서 처리
  def last_message
    if messages.loaded?
      messages.max_by(&:created_at)
    else
      messages.order(created_at: :desc).first
    end
  end

  # 특정 사용자의 안읽은 메시지 수
  # includes(:participants)로 preload된 경우 추가 쿼리 없이 Ruby에서 처리
  def unread_count_for(user)
    participant = if participants.loaded?
      participants.find { |p| p.user_id == user.id }
    else
      participants.find_by(user: user)
    end
    return 0 unless participant

    participant.unread_count
  end

  # 게시글 작성자인지 확인
  def post_author?(user)
    source_post&.user_id == user.id
  end

  # 거래 확정
  def confirm_deal!(by_user)
    return false unless post_author?(by_user)

    transaction do
      update!(deal_status: :confirmed)
      messages.create!(
        sender: by_user,
        content: "거래가 확정되었습니다. 상호 간의 약속을 지켜주세요.",
        message_type: "deal_confirm"
      )
    end
    true
  end

  # 거래 취소
  def cancel_deal!(by_user)
    return false unless post_author?(by_user)

    transaction do
      update!(deal_status: :cancelled)
      messages.create!(
        sender: by_user,
        content: "거래가 취소되었습니다.",
        message_type: "system"
      )
    end
    true
  end
end
