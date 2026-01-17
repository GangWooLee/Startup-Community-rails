# frozen_string_literal: true

# 사용자 아바타 렌더링 헬퍼
#
# 다양한 컨텍스트에서 일관된 아바타 렌더링을 제공
# (shadcn render_avatar와 구분하기 위해 render_user_avatar로 명명)
module AvatarHelper
  # 아바타 사이즈별 클래스 매핑
  AVATAR_SIZE_CLASSES = {
    "xs" => { container: "h-5 w-5", text: "text-[10px]" },
    "sm" => { container: "h-8 w-8", text: "text-sm" },
    "md" => { container: "h-10 w-10", text: "text-lg" },
    "lg" => { container: "h-12 w-12", text: "text-xl" },
    "xl" => { container: "h-16 w-16", text: "text-2xl" },
    "2xl" => { container: "h-20 w-20", text: "text-2xl" }
  }.freeze

  # 아바타 배경색 팔레트
  AVATAR_COLORS = %w[
    bg-red-500 bg-orange-500 bg-amber-500 bg-yellow-500
    bg-lime-500 bg-green-500 bg-emerald-500 bg-teal-500
    bg-cyan-500 bg-sky-500 bg-blue-500 bg-indigo-500
    bg-violet-500 bg-purple-500 bg-fuchsia-500 bg-pink-500
  ].freeze

  # 아바타 배경색 생성 (이름 기반)
  # 이름의 첫 글자를 기반으로 일관된 색상 반환
  # @param name [String] 사용자 이름
  # @return [String] Tailwind 배경색 클래스
  def avatar_bg_color(name)
    return "bg-gray-400" if name.blank?

    index = name.chars.first.ord % AVATAR_COLORS.length
    AVATAR_COLORS[index]
  end

  # 사용자 아바타 렌더링
  #
  # @param user [User] 사용자 객체
  # @param options [Hash] 옵션
  #   :size - "xs" | "sm" | "md" | "lg" | "xl" | "2xl" (기본: "md")
  #   :class - 컨테이너에 추가할 CSS 클래스
  #   :ring - 링 스타일 (예: "ring-2 ring-background")
  #   :fallback_bg - 폴백 배경색 (기본: "bg-secondary")
  #   :fallback_text_color - 폴백 텍스트 색상 (기본: "text-muted-foreground")
  #   :variant - 이미지 variant (예: :thumb)
  #
  # @example 기본 사용
  #   <%= render_user_avatar(@user) %>
  #
  # @example 커스텀 사이즈와 링
  #   <%= render_user_avatar(@user, size: "lg", ring: "ring-4 ring-background") %>
  #
  # @return [ActiveSupport::SafeBuffer] 아바타 HTML
  def render_user_avatar(user, options = {})
    return "" unless user

    size = options.fetch(:size, "md")
    extra_class = options.fetch(:class, "")
    ring_class = options.fetch(:ring, "")
    fallback_bg = options.fetch(:fallback_bg, "bg-secondary")
    fallback_text_color = options.fetch(:fallback_text_color, "text-muted-foreground")
    variant = options[:variant]

    sizes = AVATAR_SIZE_CLASSES[size] || AVATAR_SIZE_CLASSES["md"]

    # 익명 모드일 때는 흰색 배경 + 테두리 사용
    is_anonymous = user.respond_to?(:using_anonymous_avatar?) && user.using_anonymous_avatar?
    bg_class = is_anonymous ? "bg-white border border-gray-200" : fallback_bg

    container_class = [
      sizes[:container],
      "rounded-full overflow-hidden flex items-center justify-center flex-shrink-0",
      bg_class,
      ring_class,
      extra_class
    ].reject(&:blank?).join(" ")

    content = render_avatar_content(user, sizes, fallback_text_color, is_anonymous, variant)
    content_tag(:div, content, class: container_class)
  end

  private

  # 아바타 내용 렌더링 (이미지 또는 폴백)
  def render_avatar_content(user, sizes, fallback_text_color, is_anonymous, variant)
    if is_anonymous
      render_anonymous_avatar(user)
    elsif user.respond_to?(:avatar) && user.avatar.attached?
      render_attached_avatar(user, variant)
    elsif user.respond_to?(:avatar_url) && user.avatar_url.present?
      render_url_avatar(user)
    else
      render_fallback_avatar(user, sizes, fallback_text_color)
    end
  end

  def render_anonymous_avatar(user)
    avatar_type = user.respond_to?(:avatar_type) ? user.avatar_type.to_i : 0
    image_tag("/anonymous#{avatar_type + 1}-.png",
              alt: user.display_name,
              loading: "lazy",
              class: "h-full w-full object-cover")
  end

  def render_attached_avatar(user, variant)
    img_src = variant ? user.avatar.variant(variant) : user.avatar
    image_tag(img_src, alt: user.display_name, loading: "lazy", class: "h-full w-full object-cover")
  end

  def render_url_avatar(user)
    image_tag(user.avatar_url, alt: user.display_name, loading: "lazy", class: "h-full w-full object-cover")
  end

  def render_fallback_avatar(user, sizes, fallback_text_color)
    display = user.respond_to?(:display_name) ? user.display_name : user.name
    initial = display&.first&.upcase || "?"
    content_tag(:span, initial, class: "#{sizes[:text]} font-semibold #{fallback_text_color}")
  end
end
