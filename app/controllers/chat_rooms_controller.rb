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
                   .with_attached_avatar  # ✅ 최적화: Active Storage N+1 방지
                   .where("name LIKE ? OR email LIKE ? OR nickname LIKE ?",
                          "%#{query}%", "%#{query}%", "%#{query}%")
                   .limit(10)
    else
      @users = []
    end

    # JSON 응답 - 익명 모드 지원
    render json: @users.map { |u|
      {
        id: u.id,
        name: u.display_name,  # 익명 모드면 닉네임, 아니면 실명
        role_title: u.is_anonymous? ? nil : u.role_title,  # 익명이면 역할 숨김
        avatar_url: avatar_url_for_search(u),  # 익명이면 익명 아바타
        is_anonymous: u.is_anonymous?
      }
    }
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

    # 성능 최적화: 최근 50개 메시지만 로드 (페이지네이션)
    # 역순으로 가져온 후 정순 정렬하여 UI에 표시
    @messages = @chat_room.messages
                          .includes(:sender)
                          .with_attached_image  # 이미지 첨부 N+1 방지
                          .order(created_at: :desc)
                          .limit(50)
                          .reverse
    @has_more_messages = @chat_room.messages.count > 50
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
      service = ChatRooms::CreateWithMessageService.call(
        current_user: current_user,
        other_user: other_user,
        content: params[:initial_message]
      )
      @chat_room = service.chat_room

      track_ga4_event("chat_start", { chat_room_id: @chat_room.id, from_post: false })

      respond_to do |format|
        format.turbo_stream { render_chat_room_with_list(service) }
        format.html { redirect_to @chat_room }
      end
      return
    end

    # 프로필 페이지에서 '대화하기' 버튼 클릭 시
    # 기존 채팅방이 있는지 먼저 확인
    existing_room = ChatRoom.find_existing_between(current_user, other_user)

    if existing_room
      # 기존 채팅방이 있으면 바로 해당 채팅방으로 이동
      redirect_to chat_room_path(existing_room)
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

    # GA4 채팅 시작 이벤트 (게시글에서 시작)
    track_ga4_event("chat_start", { chat_room_id: @chat_room.id, from_post: true, post_id: post.id })

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

    # nil 체크: 참여자가 없거나 탈퇴한 경우 방어
    if @user.nil?
      head :not_found
      return
    end

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

  # 실시간 메시지 수신 시 읽음 처리 (클라이언트에서 호출)
  def mark_as_read
    @chat_room = ChatRoom.find(params[:id])
    participant = @chat_room.participants.find_by(user: current_user)

    if participant
      participant.mark_as_read!
      head :ok
    else
      head :forbidden
    end
  end

  private

  def set_chat_room
    @chat_room = ChatRoom.find(params[:id])
  end

  # 검색 결과용 아바타 URL (익명 모드 지원)
  def avatar_url_for_search(user)
    if user.using_anonymous_avatar?
      "/anonymous#{user.avatar_type + 1}-.png"
    elsif user.avatar.attached?
      url_for(user.avatar)
    else
      nil
    end
  end

  def render_chat_room_with_list(service)
    prepare_chat_list_data
    render turbo_stream: [
      turbo_stream.replace("chat_list_panel", partial: "chat_rooms/chat_list_panel",
        locals: {
          filter: @filter, search: @search, total_unread: @total_unread,
          received_unread: @received_unread, sent_unread: @sent_unread,
          chat_rooms: @chat_rooms, current_chat_room: @chat_room
        }),
      turbo_stream.replace("chat_room_content", partial: "chat_rooms/chat_room_content",
        locals: {
          chat_room: @chat_room,
          messages: service.messages,
          other_user: service.other_participant
        })
    ]
  end

  def prepare_chat_list_data
    @filter = params[:filter] || "all"
    @search = params[:search]

    query = ChatRooms::ListQuery.call(
      user: current_user,
      filter: @filter,
      search: @search
    )

    @chat_rooms = query.chat_rooms
    @total_unread = query.total_unread
    @received_unread = query.received_unread
    @sent_unread = query.sent_unread
  end
end
