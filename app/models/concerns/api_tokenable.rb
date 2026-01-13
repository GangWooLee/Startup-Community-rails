# frozen_string_literal: true

# API 토큰 관련 기능
# 용도: n8n 등 외부 서비스 연동
# 제거: 이 파일 삭제 + User 모델에서 include 제거 + 마이그레이션 롤백
module ApiTokenable
  extend ActiveSupport::Concern

  # API 토큰 생성 (관리자 또는 Rails console에서만)
  # @return [String] 생성된 64자 hex 토큰
  def generate_api_token!
    self.api_token = SecureRandom.hex(32)
    save!
    api_token
  end

  # API 토큰 폐기
  def revoke_api_token!
    update!(api_token: nil)
  end

  # API 토큰 존재 여부
  def api_token?
    api_token.present?
  end
end
