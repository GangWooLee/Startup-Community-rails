# frozen_string_literal: true

# PagesController
#
# Static pages for legal documents and policies.
# These pages don't require authentication.
#
class PagesController < ApplicationController
  # 법적 페이지는 로그인 불필요
  skip_before_action :require_login, only: [ :terms, :privacy, :refund, :guidelines ], raise: false

  def shadcn_test
    # shadcn 컴포넌트 테스트 페이지 (개발 환경에서만 접근 가능)
  end

  # 이용약관
  def terms
  end

  # 개인정보처리방침
  def privacy
  end

  # 환불정책
  def refund
  end

  # 커뮤니티 가이드라인
  def guidelines
  end
end
