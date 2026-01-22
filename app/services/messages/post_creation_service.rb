# frozen_string_literal: true

module Messages
  # 메시지 생성 후 필요한 작업들을 처리하는 오케스트레이터 서비스
  #
  # 처리 순서 (순서 중요!):
  # 1. 발신자 읽음 상태 업데이트
  # 2. 수신자 미읽음 수 증가
  # 3. Turbo Streams 브로드캐스트
  # 4. 알림 생성 (시스템 메시지 제외)
  # 5. 숨긴 참여자 복구
  #
  # 사용 예:
  #   Messages::PostCreationService.call(message)
  class PostCreationService
    def self.call(message)
      new(message).call
    end

    def initialize(message)
      @message = message
      @chat_room = message.chat_room
      @sender_id = message.sender_id
    end

    def call
      # 1. 데이터 업데이트 (실패 시 예외 발생 - 정상 동작)
      # 트랜잭션 내부: 반드시 성공해야 하는 핵심 데이터 업데이트
      ActiveRecord::Base.transaction do
        mark_sender_as_read
        increment_recipient_unread_count
      end

      # 2. 부수효과 (실패해도 에러 삼킴 - "best effort")
      # 트랜잭션 외부: 실패해도 메시지는 이미 저장됨
      safe_execute(:broadcast) { broadcast_message }
      safe_execute(:notify) { notify_recipients } unless @message.system_message?
      safe_execute(:resurrect) { resurrect_hidden_participants }
    end

    private

    # 발신자의 읽음 상태 업데이트
    def mark_sender_as_read
      participant = @chat_room.participants.find_by(user_id: @sender_id)
      # update_columns로 callback/validation 없이 직접 업데이트 (성능 최적화)
      participant&.update_columns(last_read_at: Time.current, unread_count: 0)
    end

    # 수신자들의 unread_count 증가
    # Row-level locking으로 Race Condition 방지 (동시 메시지 전송 시)
    def increment_recipient_unread_count
      @chat_room.participants
                .lock("FOR UPDATE")
                .where.not(user_id: @sender_id)
                .update_all("unread_count = unread_count + 1")
    end

    # Turbo Streams 브로드캐스트
    def broadcast_message
      Messages::Broadcaster.call(@message)
    end

    # 알림 생성
    def notify_recipients
      Messages::NotificationHandler.call(@message)
    end

    # 숨긴 참여자 복구
    def resurrect_hidden_participants
      Messages::ParticipantResurrector.call(@message)
    end

    # 부수효과 안전 실행 - 실패 시 로깅만 하고 계속 진행
    # @param name [Symbol] 작업 식별자 (로깅용)
    # @yield 실행할 부수효과 블록
    def safe_execute(name)
      yield
    rescue StandardError => e
      Rails.logger.error "[PostCreationService:#{name}] #{e.class}: #{e.message}"
      Rails.logger.error e.backtrace&.first(3)&.join("\n")
      Sentry.capture_exception(e, tags: { service: "post_creation", step: name.to_s }) if defined?(Sentry)
      # 에러 삼킴 - 데이터는 이미 저장됨
    end
  end
end
