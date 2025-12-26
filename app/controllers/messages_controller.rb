class MessagesController < ApplicationController
  before_action :require_login
  before_action :set_chat_room
  before_action :authorize_participant

  def create
    @message = @chat_room.messages.build(message_params)
    @message.sender = current_user
    @message.message_type = :text

    if @message.save
      mark_as_read!

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @chat_room }
      end
    else
      head :unprocessable_entity
    end
  end

  # 내 프로필 전송
  def send_profile
    profile_url = profile_url(current_user)
    content = build_profile_card_content

    @message = @chat_room.messages.create!(
      sender: current_user,
      content: content,
      message_type: :profile_card,
      metadata: {
        user_id: current_user.id,
        name: current_user.name,
        role_title: current_user.role_title,
        affiliation: current_user.affiliation,
        profile_url: profile_url
      }
    )

    mark_as_read!

    respond_to do |format|
      # 메시지는 Message 모델의 broadcast_message에서 브로드캐스트됨
      # 여기서 중복으로 append하면 메시지가 두 번 나타남
      format.turbo_stream { head :ok }
      format.html { redirect_to @chat_room }
    end
  end

  # 연락처 전송
  def send_contact
    contact_info = build_contact_info
    return head(:unprocessable_entity) if contact_info.blank?

    @message = @chat_room.messages.create!(
      sender: current_user,
      content: contact_info[:content],
      message_type: :contact_card,
      metadata: contact_info[:metadata]
    )

    mark_as_read!

    respond_to do |format|
      # 메시지는 Message 모델의 broadcast_message에서 브로드캐스트됨
      # 여기서 중복으로 append하면 메시지가 두 번 나타남
      format.turbo_stream { head :ok }
      format.html { redirect_to @chat_room }
    end
  end

  # 거래 제안 전송
  def send_offer
    offer_data = offer_params
    return head(:unprocessable_entity) if offer_data[:amount].blank? || offer_data[:title].blank?

    # 금액에서 콤마 제거 후 정수 변환
    amount = offer_data[:amount].to_s.gsub(/[^\d]/, "").to_i
    return head(:unprocessable_entity) if amount <= 0

    @message = @chat_room.messages.create!(
      sender: current_user,
      content: "거래 제안이 도착했습니다",
      message_type: :offer_card,
      metadata: {
        amount: amount,
        title: offer_data[:title].to_s.truncate(100),
        description: offer_data[:description].to_s.truncate(1000),
        deadline: offer_data[:deadline],
        refund_policy: offer_data[:refund_policy] || "no_refund",
        status: "pending"
      }
    )

    mark_as_read!

    respond_to do |format|
      format.turbo_stream { head :ok }
      format.html { redirect_to @chat_room }
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "[MessagesController#send_offer] Failed: #{e.message}"
    head :unprocessable_entity
  end

  private

  def set_chat_room
    @chat_room = ChatRoom.find(params[:chat_room_id])
  end

  def authorize_participant
    unless @chat_room.users.include?(current_user)
      head :forbidden
    end
  end

  def mark_as_read!
    participant = @chat_room.participants.find_by(user: current_user)
    participant&.mark_as_read!
  end

  def message_params
    params.require(:message).permit(:content)
  end

  def offer_params
    params.require(:offer).permit(:amount, :title, :description, :deadline, :refund_policy)
  end

  def build_profile_card_content
    parts = [ current_user.name ]
    parts << current_user.role_title if current_user.role_title.present?
    parts << "@#{current_user.affiliation}" if current_user.affiliation.present?
    "#{parts.join(' | ')} 프로필을 공유했습니다."
  end

  def build_contact_info
    metadata = {}
    content_parts = []

    if current_user.email.present?
      metadata[:email] = current_user.email
      content_parts << "이메일: #{current_user.email}"
    end

    if current_user.open_chat_url.present?
      metadata[:open_chat_url] = current_user.open_chat_url
      content_parts << "오픈채팅: #{current_user.open_chat_url}"
    end

    return nil if content_parts.empty?

    {
      content: content_parts.join("\n"),
      metadata: metadata
    }
  end
end
