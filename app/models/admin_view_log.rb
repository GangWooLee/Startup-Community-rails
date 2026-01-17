# 관리자 감사 로그 (Admin Audit Log)
# - 모든 민감한 관리자 작업을 추적
# - 법적 의무 준수 증빙
# - 보안 감사(Audit Trail)용
#
# 사용 예:
#   AdminViewLog.log_action(
#     admin: current_user,
#     action: :force_logout,
#     target: user,
#     reason: "의심스러운 활동",
#     request: request
#   )
#
class AdminViewLog < ApplicationRecord
  belongs_to :admin, class_name: "User"
  belongs_to :target, polymorphic: true

  # Validations
  validates :action, presence: true
  validates :reason, presence: true, length: { minimum: 5, message: "는 최소 5자 이상 입력해주세요" }

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_admin, ->(admin_id) { where(admin_id: admin_id) }
  scope :for_target, ->(target) { where(target: target) }
  scope :by_action, ->(action) { where(action: action) }
  scope :today, -> { where("created_at >= ?", Time.current.beginning_of_day) }
  scope :this_week, -> { where("created_at >= ?", 1.week.ago) }
  scope :sensitive_actions, -> { where(action: SENSITIVE_ACTIONS) }

  # ============================================================================
  # 액션 타입 정의
  # ============================================================================

  # 개인정보 관련 액션
  PERSONAL_DATA_ACTIONS = %w[
    reveal_personal_info
    view_snapshot
    export_data
  ].freeze

  # 사용자 관리 액션
  USER_MANAGEMENT_ACTIONS = %w[
    force_logout_session
    force_logout_all_sessions
    delete_user_post
    delete_user_comment
    suspend_user
    restore_user
    change_user_role
  ].freeze

  # 콘텐츠 관리 액션
  CONTENT_MANAGEMENT_ACTIONS = %w[
    delete_post
    hide_post
    restore_post
    delete_comment
    hide_comment
    approve_report
    dismiss_report
  ].freeze

  # 시스템 설정 액션
  SYSTEM_ACTIONS = %w[
    update_api_key
    rotate_api_key
    delete_api_key
    bulk_action
    sudo_mode_enabled
  ].freeze

  # 민감한 액션 (재인증 필요)
  SENSITIVE_ACTIONS = %w[
    reveal_personal_info
    export_data
    delete_user_post
    delete_user_comment
    force_logout_all_sessions
    suspend_user
    change_user_role
    update_api_key
    delete_api_key
    bulk_action
  ].freeze

  # 모든 액션 타입
  ACTIONS = (
    PERSONAL_DATA_ACTIONS +
    USER_MANAGEMENT_ACTIONS +
    CONTENT_MANAGEMENT_ACTIONS +
    SYSTEM_ACTIONS
  ).freeze

  # ============================================================================
  # 클래스 메서드
  # ============================================================================

  # 편리한 로깅 메서드
  # @param admin [User] 관리자
  # @param action [String, Symbol] 액션 타입
  # @param target [ActiveRecord::Base] 대상 레코드
  # @param reason [String] 사유
  # @param request [ActionDispatch::Request, nil] 요청 객체 (IP, User-Agent 자동 추출)
  # @param metadata [Hash] 추가 메타데이터
  def self.log_action(admin:, action:, target:, reason:, request: nil, metadata: {})
    create!(
      admin: admin,
      action: action.to_s,
      target: target,
      reason: build_reason(reason, metadata),
      ip_address: request&.remote_ip,
      user_agent: request&.user_agent
    )
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "[AdminAuditLog] Failed to create log: #{e.message}"
    raise
  end

  # 민감한 액션인지 확인
  def self.sensitive_action?(action)
    SENSITIVE_ACTIONS.include?(action.to_s)
  end

  # ============================================================================
  # 인스턴스 메서드
  # ============================================================================

  # 한국어 액션 이름
  def action_label
    I18N_ACTIONS[action] || action.humanize
  end

  # 민감한 액션 여부
  def sensitive?
    SENSITIVE_ACTIONS.include?(action)
  end

  # ============================================================================
  # Private
  # ============================================================================

  private_class_method def self.build_reason(reason, metadata)
    return reason if metadata.blank?

    parts = [ reason ]
    metadata.each do |key, value|
      parts << "#{key}: #{value}"
    end
    parts.join(" | ")
  end

  # 한국어 액션 레이블
  I18N_ACTIONS = {
    "reveal_personal_info" => "개인정보 열람",
    "view_snapshot" => "스냅샷 열람",
    "export_data" => "데이터 내보내기",
    "force_logout_session" => "세션 강제 종료",
    "force_logout_all_sessions" => "전체 세션 강제 종료",
    "delete_user_post" => "게시글 삭제",
    "delete_user_comment" => "댓글 삭제",
    "suspend_user" => "사용자 정지",
    "restore_user" => "사용자 복원",
    "change_user_role" => "역할 변경",
    "delete_post" => "게시글 삭제",
    "hide_post" => "게시글 숨김",
    "restore_post" => "게시글 복원",
    "delete_comment" => "댓글 삭제",
    "hide_comment" => "댓글 숨김",
    "approve_report" => "신고 승인",
    "dismiss_report" => "신고 기각",
    "update_api_key" => "API 키 수정",
    "rotate_api_key" => "API 키 갱신",
    "delete_api_key" => "API 키 삭제",
    "bulk_action" => "일괄 작업",
    "sudo_mode_enabled" => "재인증 완료"
  }.freeze
end
