# frozen_string_literal: true

# Application Helper
#
# 애플리케이션 전역에서 사용되는 헬퍼 메서드 모음
# 기능별 헬퍼 모듈을 include하여 구성
#
# 분리된 헬퍼 모듈:
# - MetaTagsHelper: OG 메타 태그 생성
# - SearchHighlightHelper: 검색어 하이라이팅
# - PaginationHelper: 페이지네이션 범위 계산
# - AvatarHelper: 사용자 아바타 렌더링
# - UrlHelper: URL 안전성 검증 및 자동 링크 변환
# - SidebarHelper: 글로벌 사이드바 레이아웃
# - SeoHelper: Canonical URL 및 JSON-LD 구조화 데이터
module ApplicationHelper
  # ==========================================================================
  # 기능별 헬퍼 모듈 include
  # ==========================================================================
  include MetaTagsHelper
  include SearchHighlightHelper
  include PaginationHelper
  include AvatarHelper
  include UrlHelper
  include SidebarHelper
  include SeoHelper

  # ==========================================================================
  # 결제 시스템 설정
  # ==========================================================================

  # 결제 시스템 활성화 여부
  # 사업자등록 완료 후 true로 변경하면 결제 기능 활성화
  # 관련 파일: payments_controller.rb, orders_controller.rb, TossPayments 서비스
  # @return [Boolean] 결제 기능 활성화 여부
  def payment_enabled?
    false
  end

  # ==========================================================================
  # 메시지 헬퍼
  # ==========================================================================

  # 메시지 미리보기 텍스트 생성
  # @param message [Message] 메시지 객체
  # @return [String] 미리보기 텍스트
  def message_preview(message)
    case message.message_type
    when "system"
      truncate(message.content, length: 30)
    when "deal_confirm"
      "거래가 확정되었습니다"
    when "profile_card"
      "프로필을 공유했습니다"
    when "contact_card"
      "연락처를 공유했습니다"
    else
      truncate(message.content, length: 30)
    end
  end
end
