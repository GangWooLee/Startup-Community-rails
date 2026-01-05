# frozen_string_literal: true

##
# Icon Helper - rails_icons gem 래퍼
#
# 기존 커스텀 syntax를 rails_icons gem으로 위임
# 하위 호환성 유지: css_class:, variant: :outline 등
#
# 사용법:
#   <%= icon "check", css_class: "w-5 h-5 text-green-500" %>
#   <%= icon "x-mark", variant: :outline %>
#   <%= icon "heart", variant: :solid, css_class: "text-red-500" %>
#
# rails_icons + Heroicons로 300+ 아이콘 사용 가능
# 전체 목록: https://heroicons.com/
#
module IconHelper
  # Size to Tailwind class mapping
  SIZE_CLASSES = {
    "xs" => "w-3 h-3",
    "sm" => "w-4 h-4",
    "md" => "w-5 h-5",
    "lg" => "w-6 h-6",
    "xl" => "w-8 h-8"
  }.freeze

  # 기존 뷰에서 사용하던 syntax와 호환되도록 래퍼 제공
  #
  # @param name [String] 아이콘 이름 (kebab-case)
  # @param variant [Symbol, String] :outline, :solid, :mini, :micro (기본: outline)
  # @param size [String] "xs", "sm", "md", "lg", "xl" (기본: "md")
  # @param css_class [String] CSS 클래스 (기존 호환 - class:로 변환)
  # @param options [Hash] 추가 옵션 (data 속성 등)
  #
  # @return [ActiveSupport::SafeBuffer] SVG 아이콘 HTML
  #
  def icon(name, variant: "outline", size: "md", css_class: nil, **options)
    # css_class를 class로 변환 (기존 호환)
    base_class = options.delete(:class) || css_class

    # size를 Tailwind 클래스로 변환하여 추가
    size_class = SIZE_CLASSES[size.to_s] || SIZE_CLASSES["md"]
    final_class = [size_class, base_class].compact.join(" ")

    # rails_icons gem 직접 호출 (재귀 방지)
    RailsIcons::Icon.new(
      name: name.to_s,
      library: "heroicons",
      variant: variant.to_s,
      arguments: { class: final_class, **options }
    ).svg.html_safe
  end
end
