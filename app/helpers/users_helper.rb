# 사용자 표시 관련 헬퍼
# 탈퇴한 회원 처리, 프로필 링크 등
module UsersHelper
  # 탈퇴 회원 기본 표시 이름
  DELETED_USER_NAME = "(탈퇴한 회원)".freeze

  # 사용자 이름 표시 (커뮤니티용)
  # - 탈퇴한 회원: "(탈퇴한 회원)"
  # - 익명 모드: 닉네임 (UD#1234)
  # - 실명 모드: 실제 이름
  #
  # @param user [User, nil] 사용자 객체
  # @return [String] 표시할 이름
  def display_user_name(user)
    return DELETED_USER_NAME if user.nil?
    return DELETED_USER_NAME if user.deleted?

    user.display_name
  end

  # 탈퇴 회원용 아바타 렌더링
  # 탈퇴한 회원은 유령 아이콘으로 표시
  #
  # @param user [User, nil] 사용자 객체
  # @param options [Hash] render_user_avatar와 동일한 옵션
  # @return [String] 아바타 HTML
  def display_user_avatar(user, options = {})
    if user.nil? || user.deleted?
      render_deleted_user_avatar(options)
    else
      render_user_avatar(user, options)
    end
  end

  # 탈퇴 회원 기본 아바타 렌더링
  # 회색 배경에 유령(?) 아이콘 표시
  #
  # @param options [Hash]
  #   :size - "xs" | "sm" | "md" | "lg" | "xl" | "2xl" (기본: "md")
  #   :class - 추가 CSS 클래스
  # @return [String] 아바타 HTML
  def render_deleted_user_avatar(options = {})
    size = options.fetch(:size, "md")
    extra_class = options.fetch(:class, "")

    size_classes = {
      "xs" => { container: "h-5 w-5", icon: "w-3 h-3" },
      "sm" => { container: "h-8 w-8", icon: "w-4 h-4" },
      "md" => { container: "h-10 w-10", icon: "w-5 h-5" },
      "lg" => { container: "h-12 w-12", icon: "w-6 h-6" },
      "xl" => { container: "h-16 w-16", icon: "w-8 h-8" },
      "2xl" => { container: "h-20 w-20", icon: "w-10 h-10" }
    }

    sizes = size_classes[size] || size_classes["md"]
    container_class = [
      sizes[:container],
      "rounded-full overflow-hidden flex items-center justify-center flex-shrink-0",
      "bg-gray-200",
      extra_class
    ].reject(&:blank?).join(" ")

    # 물음표 또는 유령 아이콘
    icon_html = content_tag(:span, "?", class: "text-gray-400 font-medium")

    content_tag(:div, icon_html, class: container_class)
  end

  # 사용자 프로필 링크 생성
  # 탈퇴한 회원은 링크 없이 이름만 표시
  #
  # @param user [User, nil] 사용자 객체
  # @param options [Hash]
  #   :class - 링크에 적용할 CSS 클래스
  # @return [String] 링크 또는 텍스트 HTML
  def link_to_user_profile(user, options = {})
    css_class = options.fetch(:class, "hover:underline")

    if user.nil? || user.deleted?
      content_tag(:span, DELETED_USER_NAME, class: "text-gray-400")
    else
      link_to user.display_name, profile_path(user), class: css_class
    end
  end

  # 사용자 아바타 + 이름 조합 표시
  # 탈퇴한 회원 처리 포함
  #
  # @param user [User, nil] 사용자 객체
  # @param options [Hash]
  #   :size - 아바타 사이즈
  #   :link - 프로필 링크 여부 (기본: true)
  #   :class - 컨테이너 CSS 클래스
  # @return [String] 아바타 + 이름 HTML
  def user_card_mini(user, options = {})
    size = options.fetch(:size, "sm")
    with_link = options.fetch(:link, true)
    css_class = options.fetch(:class, "flex items-center gap-2")

    avatar_html = display_user_avatar(user, size: size)

    name_html = if with_link && user.present? && !user.deleted?
      link_to user.display_name, profile_path(user), class: "hover:underline font-medium"
    else
      content_tag(:span, display_user_name(user), class: user&.deleted? ? "text-gray-400" : "font-medium")
    end

    content_tag(:div, avatar_html + name_html, class: css_class)
  end
end
