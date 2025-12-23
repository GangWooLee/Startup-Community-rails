class ChatRoomsController < ApplicationController
  before_action :require_login
  before_action :set_chat_room, only: [ :show, :confirm_deal, :cancel_deal ]
  before_action :hide_floating_button

  def index
    @chat_rooms = current_user.chat_rooms
                              .includes(:users, :source_post, messages: :sender)
                              .order(last_message_at: :desc)
  end

  def show
    # 권한 확인
    unless @chat_room.users.include?(current_user)
      redirect_to chat_rooms_path, alert: "접근 권한이 없습니다."
      return
    end

    # 읽음 처리
    @participant = @chat_room.participants.find_by(user: current_user)
    @participant.mark_as_read!

    @messages = @chat_room.messages.includes(:sender).order(:created_at)
    @other_user = @chat_room.other_participant(current_user)
  end

  # 프로필에서 채팅 시작 (컨텍스트 없음)
  def create
    other_user_id = params[:user_id] || params[:id]
    other_user = User.find_by(id: other_user_id)

    if other_user.nil?
      redirect_back fallback_location: root_path, alert: "사용자를 찾을 수 없습니다."
      return
    end

    if other_user.id == current_user.id
      redirect_back fallback_location: root_path, alert: "자신과 대화할 수 없습니다."
      return
    end

    @chat_room = ChatRoom.find_or_create_between(current_user, other_user, initiator: current_user)
    redirect_to @chat_room
  end

  # 게시글에서 채팅 시작 (컨텍스트 포함)
  def create_from_post
    post = Post.find_by(id: params[:id])

    if post.nil?
      redirect_back fallback_location: root_path, alert: "게시글을 찾을 수 없습니다."
      return
    end

    if post.user_id == current_user.id
      redirect_back fallback_location: root_path, alert: "자신의 게시글에는 문의할 수 없습니다."
      return
    end

    @chat_room = ChatRoom.find_or_create_for_post(
      post: post,
      initiator: current_user,
      post_author: post.user
    )

    redirect_to @chat_room
  end

  # 거래 확정
  def confirm_deal
    if @chat_room.confirm_deal!(current_user)
      respond_to do |format|
        format.turbo_stream {
          render turbo_stream: [
            turbo_stream.replace("deal-actions", partial: "chat_rooms/deal_actions", locals: { chat_room: @chat_room }),
            turbo_stream.append("messages", partial: "messages/message", locals: { message: @chat_room.messages.last })
          ]
        }
        format.html { redirect_to @chat_room, notice: "거래가 확정되었습니다." }
      end
    else
      redirect_to @chat_room, alert: "거래 확정 권한이 없습니다."
    end
  end

  # 거래 취소
  def cancel_deal
    if @chat_room.cancel_deal!(current_user)
      respond_to do |format|
        format.turbo_stream {
          render turbo_stream: [
            turbo_stream.replace("deal-actions", partial: "chat_rooms/deal_actions", locals: { chat_room: @chat_room }),
            turbo_stream.append("messages", partial: "messages/message", locals: { message: @chat_room.messages.last })
          ]
        }
        format.html { redirect_to @chat_room, notice: "거래가 취소되었습니다." }
      end
    else
      redirect_to @chat_room, alert: "거래 취소 권한이 없습니다."
    end
  end

  private

  def set_chat_room
    @chat_room = ChatRoom.find(params[:id])
  end
end
