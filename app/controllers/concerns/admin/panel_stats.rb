# frozen_string_literal: true

# 관리자 패널 공통 통계 계산
# 대시보드와 회원 관리에서 공유되는 사용자 타입별 통계 로직
#
# 사용법:
#   class Admin::DashboardController < Admin::BaseController
#     include Admin::PanelStats
#
#     def index
#       calculate_user_type_stats
#       # 추가 통계 계산...
#     end
#   end
#
module Admin
  module PanelStats
    extend ActiveSupport::Concern

    private

    # 사용자 타입별 통계 계산 (공통 로직)
    # @param total [Integer, nil] 전체 사용자 수 (nil이면 내부에서 계산)
    # @return [Hash] 통계 데이터
    def calculate_user_type_stats(total = nil)
      total ||= User.count
      return {} if total.zero?

      admin_count = User.where(is_admin: true).count
      oauth_count = User.joins(:oauth_identities).distinct.count
      normal_count = total - admin_count - oauth_count

      {
        total: total,
        admin_count: admin_count,
        oauth_count: oauth_count,
        normal_count: normal_count,
        admin_percentage: ((admin_count.to_f / total) * 100).round(1),
        oauth_percentage: ((oauth_count.to_f / total) * 100).round(1),
        normal_percentage: (100 - ((admin_count.to_f / total) * 100).round(1) - ((oauth_count.to_f / total) * 100).round(1)).round(1)
      }
    end

    # 도넛 차트용 SVG stroke-dasharray 계산
    # @param stats [Hash] calculate_user_type_stats 결과
    # @param circumference [Float] 원 둘레 (기본: 251.2 = 2 * π * 40)
    # @return [Hash] SVG 속성값
    def calculate_donut_chart_values(stats, circumference = 251.2)
      return {} if stats.empty?

      normal_dash = ((stats[:normal_percentage] / 100.0) * circumference).round(1)
      oauth_dash = ((stats[:oauth_percentage] / 100.0) * circumference).round(1)
      admin_dash = ((stats[:admin_percentage] / 100.0) * circumference).round(1)

      {
        normal_dash: normal_dash,
        oauth_dash: oauth_dash,
        admin_dash: admin_dash,
        oauth_offset: -normal_dash,
        admin_offset: -(normal_dash + oauth_dash)
      }
    end
  end
end
