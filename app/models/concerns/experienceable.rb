# frozen_string_literal: true

# Experience Timeline (경력/학력/프로젝트) 관련 기능
# 사용: include Experienceable
#
# 제공 메서드:
# - experiences_array: Experience 배열 반환
# - grouped_experiences: 타입별로 그룹화된 경험
# - sorted_experiences: 정렬된 경험 (현재 진행 중 우선)
# - has_experiences?: Experience가 있는지 확인
# - current_experiences: 현재 진행 중인 경험만 반환
# - experiences_by_type(type): 특정 타입의 경험만 반환
module Experienceable
  extend ActiveSupport::Concern

  included do
    # Experience 타입 정의
    # 구조: [{ type: "work|education|project", title: "직책/학위",
    #          organization: "회사/학교", period: "2023.03 - 현재",
    #          description: "설명", is_current: true/false }]
    EXPERIENCE_TYPES = {
      "work" => { icon: "briefcase", label: "경력", color: "bg-blue-100 text-blue-700" },
      "education" => { icon: "academic-cap", label: "학력", color: "bg-purple-100 text-purple-700" },
      "project" => { icon: "rocket-launch", label: "프로젝트", color: "bg-orange-100 text-orange-700" },
      "award" => { icon: "trophy", label: "수상", color: "bg-amber-100 text-amber-700" },
      "certification" => { icon: "check-badge", label: "자격증", color: "bg-green-100 text-green-700" }
    }.freeze
  end

  # Experience 배열 반환 (nil 방지)
  def experiences_array
    experiences || []
  end

  # 타입별로 그룹화된 경험 반환
  def grouped_experiences
    experiences_array.group_by { |exp| exp["type"] || "work" }
  end

  # 정렬된 경험 반환 (현재 진행 중인 것 우선, 그 다음 최신순)
  def sorted_experiences
    experiences_array.sort_by do |exp|
      [
        exp["is_current"] ? 0 : 1,  # 현재 진행 중인 것 우선
        -(exp["sort_order"] || 999) # sort_order 역순
      ]
    end
  end

  # Experience가 있는지 확인
  def has_experiences?
    experiences_array.any?
  end

  # 현재 진행 중인 경험만 반환
  def current_experiences
    experiences_array.select { |exp| exp["is_current"] }
  end

  # 특정 타입의 경험만 반환
  def experiences_by_type(type)
    experiences_array.select { |exp| exp["type"] == type.to_s }
  end
end
