# frozen_string_literal: true

module OnboardingHelper
  # Feature section icons for landing page
  FEATURE_ICONS = {
    "lightbulb" => <<~SVG.strip,
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z"/>
    SVG
    "pencil" => <<~SVG.strip,
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z"/>
    SVG
    "users" => <<~SVG.strip,
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"/>
    SVG
    "rocket" => <<~SVG.strip
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"/>
    SVG
  }.freeze

  # Render a feature icon by name
  # @param icon_name [String] Icon name (lightbulb, pencil, users, rocket)
  # @param options [Hash] Additional options
  # @option options [String] :class CSS classes for the SVG
  # @return [String] SVG HTML
  def render_feature_icon(icon_name, options = {})
    icon_path = FEATURE_ICONS[icon_name.to_s]
    return "" unless icon_path

    css_class = options[:class] || "w-5 h-5 landing-text-primary"

    content_tag(:svg, icon_path.html_safe, {
      class: css_class,
      fill: "none",
      stroke: "currentColor",
      viewBox: "0 0 24 24",
      "aria-hidden": "true"
    })
  end

  # Landing page features data
  def landing_features
    [
      {
        icon: "lightbulb",
        title: "다듬지 않은 생각도 환영해요",
        description: "완벽한 피치덱 없이도 시작할 수 있어요"
      },
      {
        icon: "pencil",
        title: "스케치하듯 함께 만들어요",
        description: "혼자 끙끙대지 말고, 같이 그려가요"
      },
      {
        icon: "users",
        title: "실행하는 사람들이 모여요",
        description: "말만 하는 게 아니라 진짜 만드는 커뮤니티"
      },
      {
        icon: "rocket",
        title: "가볍게 시작, 진지하게 실행",
        description: "부담 없이 던지고, 단단하게 쌓아가요"
      }
    ]
  end
end
