# frozen_string_literal: true

module ChatRooms
  # 채팅방 목록 조회 쿼리 객체
  # 필터링, 검색, 읽지 않은 메시지 카운트 로직을 캡슐화
  class ListQuery
    attr_reader :chat_rooms, :total_unread, :received_unread, :sent_unread

    def initialize(user:, filter: "all", search: nil)
      @user = user
      @filter = filter
      @search = search

      execute
    end

    def self.call(user:, filter: "all", search: nil)
      new(user: user, filter: filter, search: search)
    end

    private

    def execute
      load_chat_rooms
      calculate_unread_counts
    end

    def load_chat_rooms
      # 삭제되지 않은 채팅방만 조회
      # 성능 최적화: messages: :sender 대신 last_message_preview 사용 (전체 메시지 로드 방지)
      base_query = @user.active_chat_rooms
                        .includes(:users, :source_post, :participants, last_message_preview: :sender)

      @chat_rooms = case @filter
      when "received"
        base_query.received_inquiries(@user)
      when "sent"
        base_query.sent_inquiries(@user)
      else
        base_query
      end

      @chat_rooms = @chat_rooms.search_by_keyword(@search, @user) if @search.present?
      @chat_rooms = @chat_rooms.order(last_message_at: :desc)
    end

    def calculate_unread_counts
      # 읽지 않은 메시지 수도 삭제되지 않은 채팅방만 계산
      # SQL 집계 사용 (N+1 쿼리 방지)
      @total_unread = @user.chat_room_participants
                           .active
                           .sum(:unread_count)

      @received_unread = @user.chat_room_participants
                              .active
                              .joins(chat_room: :source_post)
                              .where("posts.user_id = ? AND chat_rooms.initiator_id != ?",
                                     @user.id, @user.id)
                              .sum(:unread_count)

      @sent_unread = @user.chat_room_participants
                          .active
                          .joins(:chat_room)
                          .where("chat_rooms.initiator_id = ?", @user.id)
                          .sum(:unread_count)
    end
  end
end
