# 회원 탈퇴 처리 서비스
# - 암호화된 개인정보 보관 (법적 의무)
# - User 테이블 즉시 익명화
# - 재가입 방지용 해시 생성
module Users
  class DeletionService
    Result = Struct.new(:success?, :user_deletion, :errors, keyword_init: true) do
      def failure?
        !success?
      end
    end

    def initialize(user:, reason_category: nil, reason_detail: nil, ip_address: nil, user_agent: nil)
      @user = user
      @reason_category = reason_category
      @reason_detail = reason_detail
      @ip_address = ip_address
      @user_agent = user_agent
      @errors = []
    end

    def call
      validate!
      return failure_result if @errors.any?

      ActiveRecord::Base.transaction do
        # 1. 암호화된 보관 레코드 생성 (법적 보관용)
        create_encrypted_deletion_record!

        # 2. User 테이블 즉시 익명화
        anonymize_user!

        # 3. 연관 데이터 정리
        cleanup_user_data!
      end

      Rails.logger.info "[UserDeletion] User #{@user.id} successfully anonymized"

      Result.new(
        success?: true,
        user_deletion: @user_deletion,
        errors: []
      )
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "[UserDeletion] Validation failed: #{e.message}"
      @errors << e.message
      failure_result
    rescue StandardError => e
      Rails.logger.error "[UserDeletion] Error: #{e.class} - #{e.message}\n#{e.backtrace.first(5).join("\n")}"
      @errors << "탈퇴 처리 중 오류가 발생했습니다."
      failure_result
    end

    private

    def validate!
      @errors << "사용자를 찾을 수 없습니다." unless @user
      @errors << "이미 탈퇴한 사용자입니다." if @user&.deleted?

      # 기존 pending 레코드 정리 (레거시 데이터)
      cleanup_legacy_pending_deletions! if @user&.user_deletions&.pending&.exists?
    end

    def cleanup_legacy_pending_deletions!
      @user.user_deletions.pending.destroy_all
    end

    # 암호화된 보관 레코드 생성
    def create_encrypted_deletion_record!
      @user_deletion = UserDeletion.create!(
        user: @user,
        # 암호화되어 저장됨 (Rails Active Record Encryption)
        email_original: @user.email,
        name_original: @user.name,
        phone_original: nil,  # 전화번호 컬럼이 없으면 nil
        snapshot_data: build_snapshot.to_json,
        # 재가입 방지용 단방향 해시
        email_hash: Digest::SHA256.hexdigest(@user.email.to_s.downcase.strip),
        # 메타 정보
        reason_category: @reason_category,
        reason_detail: @reason_detail,
        status: "completed",
        # 기존 호환성 (user_snapshot, activity_stats)
        user_snapshot: build_snapshot,
        activity_stats: build_activity_stats,
        requested_at: Time.current,
        permanently_deleted_at: Time.current,
        # destroy_scheduled_at은 모델의 before_create 콜백에서 자동 설정
        ip_address: @ip_address,
        user_agent: @user_agent
      )
    end

    # User 테이블 즉시 익명화
    def anonymize_user!
      @user.update!(
        email: generate_anonymous_email,
        name: "(탈퇴한 회원)",
        password_digest: generate_invalid_password_digest,
        bio: nil,
        role_title: nil,
        affiliation: nil,
        skills: nil,
        achievements: nil,
        avatar_url: nil,
        linkedin_url: nil,
        github_url: nil,
        portfolio_url: nil,
        open_chat_url: nil,
        availability_statuses: [],
        custom_status: nil,
        deleted_at: Time.current
      )
    end

    # 연관 데이터 정리
    def cleanup_user_data!
      # Active Storage 아바타 삭제
      @user.avatar.purge if @user.avatar.attached?

      # OAuth 연결 삭제
      @user.oauth_identities.destroy_all

      # 알림 삭제 (선택적)
      # @user.notifications.destroy_all
    end

    # 익명 이메일 생성
    def generate_anonymous_email
      "deleted_#{@user.id}_#{SecureRandom.hex(4)}@void.platform"
    end

    # 유효하지 않은 password_digest 생성 (로그인 원천 차단)
    def generate_invalid_password_digest
      "deleted_#{SecureRandom.hex(16)}"
    end

    # 사용자 스냅샷 생성
    def build_snapshot
      {
        id: @user.id,
        email: @user.email,
        name: @user.name,
        bio: @user.bio,
        role_title: @user.role_title,
        affiliation: @user.affiliation,
        skills: @user.skills,
        achievements: @user.achievements,
        avatar_url: @user.avatar_url,
        linkedin_url: @user.linkedin_url,
        github_url: @user.github_url,
        portfolio_url: @user.portfolio_url,
        open_chat_url: @user.open_chat_url,
        availability_statuses: @user.availability_statuses,
        custom_status: @user.custom_status,
        is_admin: @user.is_admin,
        created_at: @user.created_at&.iso8601,
        last_sign_in_at: @user.last_sign_in_at&.iso8601,
        oauth_providers: @user.connected_providers
      }
    end

    # 활동 통계 생성
    def build_activity_stats
      {
        total_posts: @user.posts.count,
        total_comments: @user.comments.count,
        total_likes_given: @user.likes.count,
        total_likes_received: calculate_likes_received,
        total_bookmarks: @user.bookmarks.count,
        total_chat_rooms: @user.chat_rooms.count,
        total_messages_sent: @user.sent_messages.count,
        total_idea_analyses: @user.idea_analyses.count,
        total_orders: @user.orders.count,
        account_age_days: calculate_account_age,
        last_activity_at: calculate_last_activity&.iso8601
      }
    end

    def calculate_likes_received
      post_likes = @user.posts.sum(:likes_count) rescue 0
      comment_likes = @user.comments.sum(:likes_count) rescue 0
      post_likes + comment_likes
    end

    def calculate_account_age
      return 0 unless @user.created_at
      ((Time.current - @user.created_at) / 1.day).round
    end

    def calculate_last_activity
      [
        @user.posts.maximum(:created_at),
        @user.comments.maximum(:created_at),
        @user.sent_messages.maximum(:created_at),
        @user.last_sign_in_at
      ].compact.max
    end

    def failure_result
      Result.new(
        success?: false,
        user_deletion: nil,
        errors: @errors
      )
    end
  end
end
