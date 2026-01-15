# frozen_string_literal: true

module ChatRoomsHelper
  # 검색 결과용 아바타 URL (익명 모드 지원)
  def avatar_url_for_search(user)
    if user.using_anonymous_avatar?
      "/anonymous#{user.avatar_type + 1}-.png"
    elsif user.avatar.attached?
      url_for(user.avatar)
    else
      nil
    end
  end
end
