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

    # 멱등성(idempotent): 사용자가 이미 존재하면 기존 사용자 반환
    existing_user = User.find_by(email: email)
    if existing_user
      # 이메일 인증이 없으면 추가
      ensure_email_verified(email)

      return render json: {
        success: true,
        message: "User already exists",
        user: {
          id: existing_user.id,
          email: existing_user.email,
          name: existing_user.name
        }
      }, status: :ok
    end

    # 새 사용자 생성
    user = User.create!(
      email: email,
      password: password,
      name: name
    )

    # 이메일 인증 완료 상태로 EmailVerification 생성
    ensure_email_verified(email)

    render json: {
      success: true,
      user: {
        id: user.id,
        email: user.email,
        name: user.name
      }
    }, status: :created
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
    # 모든 예외를 JSON으로 반환 (406 방지)
    render json: {
      success: false,
      error: e.message
    }, status: :unprocessable_entity
  end

  # POST /test/create_post
  # 테스트용 게시글 생성
  #
  # 요청 예시:
  # {
  #   "title": "테스트 게시글",
  #   "content": "테스트 내용입니다.",
  #   "user_email": "test@example.com",
  #   "post_type": "community"  # community, outsourcing
  # }
  def create_post
    user = User.find_by(email: params[:user_email] || "test@example.com")
    unless user
      render json: { success: false, error: "User not found. Create user first." }, status: :unprocessable_entity
      return
    end

    # post_type에 따라 기본 카테고리 결정
    post_type = params[:post_type] || "community"
    default_category = post_type == "outsourcing" ? "hiring" : "free"

    post = Post.create!(
      title: params[:title] || "테스트 게시글",
      content: params[:content] || "E2E 테스트를 위한 게시글입니다.",
      user: user,
      post_type: post_type,
      category: params[:category] || default_category
    )

    render json: {
      success: true,
      post: {
        id: post.id,
        title: post.title,
        post_type: post.post_type
      }
    }, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { success: false, error: e.message }, status: :unprocessable_entity
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
    # test/development 환경에서만 동작 허용
    # production에서는 라우트 자체가 등록되지 않지만, 이중 보호
    return if Rails.env.test? || Rails.env.development?

    render json: { error: "Not allowed in #{Rails.env} environment" }, status: :not_found
  end

  # 이메일 인증이 없으면 verified 상태로 생성
  # 트랜잭션 락으로 경쟁 상태 방지
  def ensure_email_verified(email)
    EmailVerification.transaction do
      return if EmailVerification.exists?(email: email, verified: true)

      # 기존 미인증 레코드 삭제
      EmailVerification.where(email: email).delete_all

      # verified 상태로 생성
      EmailVerification.create!(
        email: email,
        code: EmailVerification.generate_code,
        expires_at: 1.year.from_now,
        verified: true
      )
    end
  rescue ActiveRecord::RecordNotUnique
    # 동시 요청 시 무시 (이미 생성됨)
  end
end
