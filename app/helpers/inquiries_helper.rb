# frozen_string_literal: true

module InquiriesHelper
  # FAQ 항목 (추후 DB 이동 가능)
  FAQ_ITEMS = [
    {
      question: "문의 답변은 얼마나 걸리나요?",
      answer: "문의 내용에 따라 다르지만, 보통 영업일 기준 1-2일 이내에 답변드리고 있습니다. 복잡한 기술 문의의 경우 조금 더 시간이 소요될 수 있습니다."
    },
    {
      question: "버그 신고는 어떻게 하나요?",
      answer: "새 문의를 작성하실 때 '버그 신고' 카테고리를 선택하시고, 발생 상황과 사용하신 브라우저 정보를 함께 작성해주시면 빠른 확인이 가능합니다."
    },
    {
      question: "기능 제안은 어떻게 반영되나요?",
      answer: "제안해주신 기능은 내부 검토를 거쳐 개발 우선순위에 반영됩니다. 많은 분들이 요청하신 기능은 더 빠르게 개발될 수 있으며, 반영 여부는 문의 답변을 통해 안내드립니다."
    },
    {
      question: "계정 관련 문의는 어떻게 하나요?",
      answer: "로그인, 비밀번호 변경, 회원 탈퇴 등 계정 관련 문의는 '기타' 카테고리로 문의해주세요. 본인 확인이 필요한 경우 가입 시 사용한 이메일로 연락드릴 수 있습니다."
    }
  ].freeze

  # FAQ 항목 조회
  def faq_items
    FAQ_ITEMS
  end

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

  # 문의 상태에 따른 뱃지 클래스 (Organic Modern 스타일)
  def inquiry_status_badge_class(status)
    case status.to_s
    when "pending"
      "bg-stone-100 text-stone-600 border border-stone-200"  # Gray - 중립적 대기 상태
    when "in_progress"
      "bg-blue-100 text-blue-700 border border-blue-200"
    when "resolved", "closed"
      "bg-emerald-100 text-emerald-700 border border-emerald-200"
    else
      "bg-stone-100 text-stone-600 border border-stone-200"
    end
  end

  # 문의 상태 라벨 (한글)
  def inquiry_status_label(status)
    case status.to_s
    when "pending" then "대기중"
    when "in_progress" then "처리중"
    when "resolved" then "답변완료"
    when "closed" then "종료"
    else "알 수 없음"
    end
  end

  # 문의가 대기 상태인지 확인
  def inquiry_pending?(inquiry)
    %w[pending in_progress].include?(inquiry.status.to_s)
  end

  # 문의가 답변 완료 상태인지 확인
  def inquiry_answered?(inquiry)
    %w[resolved closed].include?(inquiry.status.to_s)
  end

  # 카테고리 아이콘 이모지
  def inquiry_category_icon(category)
    case category.to_s
    when "bug" then "🐛"
    when "feature" then "💡"
    when "improvement" then "⚡"
    else "💬"
    end
  end

  # 상태에 따른 아이콘 배경색
  def inquiry_status_icon_bg(inquiry)
    inquiry_pending?(inquiry) ? "bg-stone-100" : "bg-emerald-100"
  end

  # 상태에 따른 아이콘 텍스트색
  def inquiry_status_icon_color(inquiry)
    inquiry_pending?(inquiry) ? "text-stone-600" : "text-emerald-600"
  end
end
