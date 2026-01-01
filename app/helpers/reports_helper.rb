# frozen_string_literal: true

module ReportsHelper
  # 신고 대상 유형에 따른 뱃지 클래스
  def report_type_badge_class(reportable_type)
    case reportable_type
    when "Post"
      "bg-indigo-100 text-indigo-700"
    when "User"
      "bg-purple-100 text-purple-700"
    when "ChatRoom"
      "bg-teal-100 text-teal-700"
    else
      "bg-gray-100 text-gray-700"
    end
  end

  # 신고 상태에 따른 뱃지 클래스
  def report_status_badge_class(status)
    case status
    when "pending"
      "bg-yellow-100 text-yellow-700"
    when "reviewed"
      "bg-blue-100 text-blue-700"
    when "resolved"
      "bg-green-100 text-green-700"
    when "dismissed"
      "bg-gray-100 text-gray-700"
    else
      "bg-gray-100 text-gray-700"
    end
  end

  # 신고 사유에 따른 뱃지 클래스
  def report_reason_badge_class(reason)
    case reason
    when "spam"
      "bg-orange-100 text-orange-700"
    when "harassment"
      "bg-red-100 text-red-700"
    when "inappropriate"
      "bg-pink-100 text-pink-700"
    when "scam"
      "bg-purple-100 text-purple-700"
    else
      "bg-gray-100 text-gray-700"
    end
  end
end
