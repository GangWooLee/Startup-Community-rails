# frozen_string_literal: true

# 활동 상태 관련 기능 (외주 가능, 팀원 모집 중 등)
# 사용: include AvailabilityStatusable
#
# 제공 메서드:
# - availability_statuses_array: 활동 상태 배열 반환
# - has_availability_status?: 활동 상태가 있는지 확인
# - availability_badges: 모든 활동 상태 뱃지 정보 반환
# - has_status?(status_key): 특정 상태가 선택되어 있는지 확인
# - available_for_work?: 외주 가능 상태인지 확인
module AvailabilityStatusable
  extend ActiveSupport::Concern

  included do
    # 활동 상태 옵션 (다중 선택 가능)
    AVAILABILITY_OPTIONS = {
      "available_for_work" => { label: "외주 가능", color: "bg-green-500" },
      "hiring" => { label: "팀원 모집 중", color: "bg-purple-500" }
    }.freeze
  end

  # 활동 상태 배열 반환 (JSON 컬럼)
  def availability_statuses_array
    availability_statuses || []
  end

  # 활동 상태가 있는지 확인
  def has_availability_status?
    availability_statuses_array.any? || custom_status.present?
  end

  # 모든 활동 상태 뱃지 정보 반환 (label, color 포함)
  def availability_badges
    badges = []

    # 선택된 기본 상태들
    availability_statuses_array.each do |status|
      if AVAILABILITY_OPTIONS[status]
        badges << {
          label: AVAILABILITY_OPTIONS[status][:label],
          color: AVAILABILITY_OPTIONS[status][:color]
        }
      end
    end

    # 기타(사용자 정의) 상태
    if custom_status.present?
      badges << {
        label: custom_status,
        color: "bg-pink-500"
      }
    end

    badges
  end

  # 특정 상태가 선택되어 있는지 확인
  def has_status?(status_key)
    availability_statuses_array.include?(status_key)
  end

  # 외주 가능 상태인지 확인
  def available_for_work?
    has_status?("available_for_work")
  end
end
