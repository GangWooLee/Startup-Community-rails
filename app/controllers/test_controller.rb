# frozen_string_literal: true

# 테스트 환경 전용 컨트롤러
# E2E 테스트 (Playwright)에서 사용자 생성 등을 위해 사용
#
# 보안:
# - 테스트 환경에서만 동작 (production에서는 404 반환)
# - routes.rb에서 제약조건으로 추가 보호
class TestController < ApplicationController
  skip_before_action :verify_authenticity_token

  before_action :ensure_test_environment

  # POST /test/create_user
  # 테스트용 사용자 생성
  #
  # 요청 예시:
  # {
  #   "email": "test@example.com",
  #   "password": "password123",
  #   "name": "테스트 유저"
  # }
  def create_user
    email = params[:email] || "test@example.com"
    password = params[:password] || "password123"
    name = params[:name] || "테스트 유저"

    # 기존 사용자가 있으면 삭제 후 재생성
    User.find_by(email: email)&.destroy

    user = User.create!(
      email: email,
      password: password,
      name: name,
      email_verified_at: Time.current # 이메일 인증 완료 상태로 생성
    )

    render json: {
      success: true,
      user: {
        id: user.id,
        email: user.email,
        name: user.name
      }
    }, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: {
      success: false,
      error: e.message
    }, status: :unprocessable_entity
  end

  # DELETE /test/cleanup
  # 테스트 데이터 정리
  def cleanup
    email_pattern = params[:email_pattern] || "%test%"

    deleted_count = User.where("email LIKE ?", email_pattern).destroy_all.size

    render json: {
      success: true,
      deleted_count: deleted_count
    }
  end

  private

  def ensure_test_environment
    return if Rails.env.test?

    render json: { error: "Not allowed in #{Rails.env} environment" }, status: :not_found
  end
end
