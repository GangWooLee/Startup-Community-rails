class ChatRoomsController < ApplicationController
  before_action :require_login
  before_action :set_chat_room, only: [ :show, :confirm_deal, :cancel_deal, :profile_overlay ]
  before_action :hide_floating_button

  def new
    # 새 메시지 작성 - 대상 검색 패널
    # recipient_id가 전달된 경우 미리 선택된 수신자 정보를 전달
    if params[:recipient_id].present?
      @preselected_recipient = User.find_by(id: params[:recipient_id])
    end
  end

  def search_users
    query = params[:query].to_s.strip

    if query.present? && query.length >= 1
      @users = User.where.not(id: current_user.id)
                   .where("name LIKE ? OR email LIKE ?", "%#{query}%", "%#{query}%")
                   .limit(10)
    else
      @users = []
    end

    # JSON 응답만 지원 (JavaScript fetch에서 사용)
    render json: @users.map { |u| { id: u.id, name: u.name, role_title: u.role_title, avatar_url: u.avatar.attached? ? url_for(u.avatar) : nil } }
  end

  def index
    prepare_chat_list_data
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
  # 시나리오 1: 기존 채팅방이 있으면 해당 채팅방으로 이동
  # 시나리오 2: 기존 채팅방이 없으면 새 메시지 패널로 이동 (수신자 미리 선택)
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

    # 새 메시지 패널에서 사용자 선택 후 메시지 전송하는 경우
    if params[:initial_message].present?
      @chat_room = ChatRoom.find_or_create_between(current_user, other_user, initiator: current_user)
      @chat_room.messages.create!(
        sender: current_user,
        content: params[:initial_message]
      )
      @chat_room.touch(:last_message_at)

      respond_to do |format|
        format.turbo_stream {
          prepare_chat_list_data
          render turbo_stream: [
            turbo_stream.replace("chat_list_panel", partial: "chat_rooms/chat_list_panel",
              locals: {
                filter: @filter,
                search: @search,
                total_unread: @total_unread,
                received_unread: @received_unread,
                sent_unread: @sent_unread,
                chat_rooms: @chat_rooms,
                current_chat_room: @chat_room
              }),
            turbo_stream.replace("chat_room_content", partial: "chat_rooms/chat_room_content",
              locals: { chat_room: @chat_room, messages: @chat_room.messages.includes(:sender).order(:created_at), other_user: @chat_room.other_participant(current_user) })
          ]
        }
        format.html { redirect_to @chat_room }
      end
      return
    end

    # 프로필 페이지에서 '대화하기' 버튼 클릭 시
    # 기존 채팅방이 있는지 먼저 확인
    existing_room = ChatRoom.find_existing_between(current_user, other_user)

    if existing_room
      # 기존 채팅방이 있으면 바로 해당 채팅방으로 이동
      redirect_to existing_room
    else
      # 기존 채팅방이 없으면 새 메시지 패널로 이동 (수신자 미리 선택)
      redirect_to new_chat_room_path(recipient_id: other_user.id)
    end
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
          # 메시지는 Message 모델의 broadcast_message에서 브로드캐스트됨
          # 여기서 중복으로 append하면 메시지가 두 번 나타남
          render turbo_stream: turbo_stream.replace("deal-actions", partial: "chat_rooms/deal_actions", locals: { chat_room: @chat_room })
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
          # 메시지는 Message 모델의 broadcast_message에서 브로드캐스트됨
          # 여기서 중복으로 append하면 메시지가 두 번 나타남
          render turbo_stream: turbo_stream.replace("deal-actions", partial: "chat_rooms/deal_actions", locals: { chat_room: @chat_room })
        }
        format.html { redirect_to @chat_room, notice: "거래가 취소되었습니다." }
      end
    else
      redirect_to @chat_room, alert: "거래 취소 권한이 없습니다."
    end
  end

  # 상대방 프로필 오버레이 표시
  def profile_overlay
    unless @chat_room.users.include?(current_user)
      head :forbidden
      return
    end

    @user = @chat_room.other_participant(current_user)

    respond_to do |format|
      format.turbo_stream {
        render turbo_stream: turbo_stream.append("profile-overlay-container",
                                                  partial: "chat_rooms/profile_overlay",
                                                  locals: { user: @user })
      }
    end
  end

  # 채팅방 나가기 (소프트 삭제 - 해당 사용자에게만 숨김)
  # 상대방은 여전히 대화를 볼 수 있고, 상대방이 메시지를 보내면 다시 나타남
  def leave
    @chat_room = ChatRoom.find(params[:id])
    participant = @chat_room.participants.find_by(user: current_user)

    unless participant
      redirect_to chat_rooms_path, alert: "채팅방을 찾을 수 없습니다."
      return
    end

    # 소프트 삭제 (나에게만 숨김)
    participant.soft_delete!

    respond_to do |format|
      format.turbo_stream {
        render turbo_stream: [
          # 목록에서 해당 방 제거 (fade out 애니메이션)
          turbo_stream.remove("chat_room_#{@chat_room.id}"),
          # 우측 화면을 빈 상태로 교체
          turbo_stream.replace("chat_room_content", partial: "chat_rooms/empty_state"),
          # 토스트 메시지 표시
          turbo_stream.append("toast-container", partial: "shared/toast",
            locals: { message: "채팅방을 나갔습니다.", type: "success" })
        ]
      }
      format.html {
        redirect_to chat_rooms_path, notice: "채팅방을 나갔습니다."
      }
    end
  end

  private

  def set_chat_room
    @chat_room = ChatRoom.find(params[:id])
  end

  def prepare_chat_list_data
    @filter = params[:filter] || "all"
    @search = params[:search]

    # 삭제되지 않은 채팅방만 조회
    base_query = current_user.active_chat_rooms
                             .includes(:users, :source_post, :participants, messages: :sender)

    @chat_rooms = case @filter
    when "received"
      base_query.received_inquiries(current_user)
    when "sent"
      base_query.sent_inquiries(current_user)
    else
      base_query
    end

    if @search.present?
      @chat_rooms = @chat_rooms.search_by_keyword(@search, current_user)
    end

    @chat_rooms = @chat_rooms.order(last_message_at: :desc)

    # 읽지 않은 메시지 수도 삭제되지 않은 채팅방만 계산
    all_rooms = current_user.active_chat_rooms.includes(:participants, :source_post, messages: :sender)
    @total_unread = all_rooms.sum { |room| room.unread_count_for(current_user) }
    @received_unread = all_rooms.select { |room| room.source_post&.user_id == current_user.id && room.initiator_id != current_user.id }.sum { |room| room.unread_count_for(current_user) }
    @sent_unread = all_rooms.select { |room| room.initiator_id == current_user.id }.sum { |room| room.unread_count_for(current_user) }
  end
end
