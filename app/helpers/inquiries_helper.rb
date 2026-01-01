# frozen_string_literal: true

module InquiriesHelper
  # 문의 카테고리에 따른 뱃지 클래스
  def inquiry_category_badge_class(category)
    case category
    when "bug"
      "bg-red-100 text-red-700"
    when "feature"
      "bg-green-100 text-green-700"
    when "improvement"
      "bg-blue-100 text-blue-700"
    else
      "bg-gray-100 text-gray-700"
    end
  end

  # 문의 상태에 따른 뱃지 클래스
  def inquiry_status_badge_class(status)
    case status
    when "pending"
      "bg-yellow-100 text-yellow-700"
    when "in_progress"
      "bg-blue-100 text-blue-700"
    when "resolved"
      "bg-green-100 text-green-700"
    when "closed"
      "bg-gray-100 text-gray-700"
    else
      "bg-gray-100 text-gray-700"
    end
  end
end
