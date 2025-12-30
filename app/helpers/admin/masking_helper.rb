# 관리자 페이지용 개인정보 마스킹 헬퍼
# 기본적으로 마스킹된 상태로 표시, 명시적 열람 시에만 원본 노출
module Admin::MaskingHelper
  # 이메일 마스킹 (예: tes***@gmail.com)
  def mask_email(email)
    return "***" if email.blank?

    parts = email.split("@")
    return email if parts.length != 2

    local = parts[0]
    domain = parts[1]

    if local.length <= 3
      masked_local = local[0] + "*" * (local.length - 1)
    else
      masked_local = local[0..2] + "*" * [local.length - 3, 3].min
    end

    "#{masked_local}@#{domain}"
  end

  # 이름 마스킹 (예: 홍*동)
  def mask_name(name)
    return "***" if name.blank?

    chars = name.chars
    return name if chars.length <= 1

    if chars.length == 2
      "#{chars[0]}*"
    else
      "#{chars[0]}#{'*' * (chars.length - 2)}#{chars[-1]}"
    end
  end

  # 전화번호 마스킹 (예: 010-****-5678)
  def mask_phone(phone)
    return "***" if phone.blank?

    # 다양한 형식 지원
    digits = phone.gsub(/\D/, "")
    return phone if digits.length < 7

    if digits.length == 11  # 010-1234-5678
      "#{digits[0..2]}-****-#{digits[-4..]}"
    elsif digits.length == 10  # 02-1234-5678
      "#{digits[0..1]}-****-#{digits[-4..]}"
    else
      phone.gsub(/\d(?=\d{4})/, "*")
    end
  end

  # 마스킹된 정보 + 열람 버튼 렌더링
  def masked_field_with_reveal(field_name:, masked_value:, deletion_id:, field_type:)
    content_tag(:div, class: "flex items-center gap-2", data: { controller: "reveal-info" }) do
      # 마스킹된 값
      masked_span = content_tag(:span, masked_value,
        class: "text-sm text-gray-600",
        data: { "reveal-info-target": "masked" })

      # 원본 값 (숨김)
      original_span = content_tag(:span, "",
        class: "text-sm text-gray-900 hidden",
        data: { "reveal-info-target": "original" })

      # 열람 버튼
      reveal_button = button_tag(
        type: "button",
        class: "p-1 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded transition",
        title: "전체 보기",
        data: {
          action: "click->reveal-info#reveal",
          "deletion-id": deletion_id,
          "field-type": field_type
        }
      ) do
        icon("eye", variant: :outline, class: "w-4 h-4")
      end

      masked_span + original_span + reveal_button
    end
  end

  # 열람 확인 모달용 데이터
  def reveal_confirmation_data(deletion)
    {
      controller: "reveal-confirm",
      "reveal-confirm-url-value": reveal_admin_user_deletion_path(deletion)
    }
  end
end
