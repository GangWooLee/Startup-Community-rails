# 관리자 채팅방 컨트롤러
# 채팅 내용 열람 (Read Only - 감청 모드)
class Admin::ChatRoomsController < Admin::BaseController
  # GET /admin/chat_rooms/:id
  # 채팅방 전체 대화 내용 열람
  def show
    @chat_room = ChatRoom.find(params[:id])

    # 참여자 정보
    @participants = @chat_room.users.to_a

    # 시간순 정렬된 전체 메시지 (N+1 방지)
    @messages = @chat_room.messages
                          .includes(:sender)
                          .order(created_at: :asc)

    # 채팅방 통계
    @messages_count = @messages.count
    @first_message_at = @messages.first&.created_at
    @last_message_at = @messages.last&.created_at
  end
end
