# frozen_string_literal: true

# OAuth 인증 관련 기능
# 사용: include Oauthable
#
# 제공 메서드:
# - from_omniauth(auth): OAuth 사용자 생성/조회
# - oauth_user?: OAuth로 가입한 사용자인지 확인
# - local_user?: 일반 로그인 사용자인지 확인
# - oauth_only?: OAuth만으로 가입한 사용자인지 확인
# - can_reset_password?: 비밀번호 재설정 가능한지 확인
# - connected_providers: 연결된 OAuth provider 목록
module Oauthable
  extend ActiveSupport::Concern

  included do
    # OAuth associations
    has_many :oauth_identities, dependent: :destroy

    # Scopes
    scope :oauth_users, -> { joins(:oauth_identities).distinct }
    scope :local_users, -> { left_joins(:oauth_identities).where(oauth_identities: { id: nil }) }
  end

  class_methods do
    # OAuth 사용자 생성 또는 찾기
    # 1. oauth_identities에서 provider + uid로 기존 연결 찾기
    # 2. 없으면 이메일로 기존 사용자 찾고, OAuth 연결 추가
    # 3. 없으면 새 사용자 생성 + OAuth 연결 추가
    # 보안: 트랜잭션으로 데이터 무결성 보장
    # 반환: { user:, deleted:, new_user: } - new_user가 true면 신규 가입자 (약관 동의 필요)
    def from_omniauth(auth)
      email = auth.info.email&.downcase
      provider = auth.provider
      uid = auth.uid

      # 1. oauth_identities에서 찾기 (트랜잭션 외부 - 읽기만)
      identity = OauthIdentity.find_by(provider: provider, uid: uid)
      if identity
        user = identity.user

        # 이메일 변경 감지 및 로깅 (Phase 2.1 - 보안 감사)
        if email.present? && user.email != email
          Rails.logger.warn "[OAuth] Email mismatch detected: User##{user.id} " \
                            "(stored: #{user.email}, oauth: #{email}, provider: #{provider})"
          Sentry.capture_message(
            "OAuth email mismatch",
            level: :warning,
            extra: { user_id: user.id, provider: provider }
          ) if defined?(Sentry)
        end

        # 탈퇴한 사용자 확인
        return { user: user, deleted: user.deleted?, new_user: false }
      end

      # 2, 3단계는 트랜잭션으로 묶어서 원자성 보장
      transaction do
        # 2. 이메일로 기존 사용자 찾기 (삭제된 사용자 포함)
        user = unscoped.find_by(email: email)

        if user
          # 탈퇴한 사용자 확인
          if user.deleted?
            return { user: user, deleted: true, new_user: false }
          end

          # 기존 사용자에게 새 OAuth 연결 추가
          user.oauth_identities.create!(provider: provider, uid: uid)
          # 프로필 사진이 없을 때만 OAuth 사진 사용
          user.update(avatar_url: auth.info.image) if user.avatar_url.blank? && auth.info.image.present?
          return { user: user, deleted: false, new_user: false }
        end

        # 3. 새 사용자 생성 + OAuth 연결 (최초 가입 시에만 OAuth 사진 사용)
        # 약관 동의 필드는 비워둠 - OAuth 약관 동의 페이지에서 설정
        user = create!(
          email: email,
          name: auth.info.name || auth.info.nickname || "User",
          password: SecureRandom.hex(20),
          avatar_url: auth.info.image
        )
        user.oauth_identities.create!(provider: provider, uid: uid)
        { user: user, deleted: false, new_user: true }
      end
    end
  end

  # OAuth 사용자인지 확인
  def oauth_user?
    oauth_identities.exists?
  end

  # 일반 로그인 사용자인지 확인
  def local_user?
    !oauth_user?
  end

  # OAuth만으로 가입한 사용자인지 확인 (비밀번호 재설정 불가)
  def oauth_only?
    oauth_user? && provider.present?
  end

  # 비밀번호 재설정이 가능한지 확인
  def can_reset_password?
    !oauth_only?
  end

  # 연결된 OAuth provider 목록
  def connected_providers
    oauth_identities.pluck(:provider)
  end
end
