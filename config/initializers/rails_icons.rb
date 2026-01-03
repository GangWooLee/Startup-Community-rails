# frozen_string_literal: true

RailsIcons.configure do |config|
  config.default_library = "heroicons"
  config.default_variant = "outline"

  # Heroicons 기본 설정
  config.libraries.heroicons.default_variant = "outline"

  # Outline 아이콘 (24x24)
  config.libraries.heroicons.outline.default.css = "size-5"
  config.libraries.heroicons.outline.default.stroke_width = "1.5"

  # Solid 아이콘 (24x24)
  config.libraries.heroicons.solid.default.css = "size-5"

  # Mini 아이콘 (20x20)
  config.libraries.heroicons.mini.default.css = "size-4"

  # Micro 아이콘 (16x16)
  config.libraries.heroicons.micro.default.css = "size-3"
end
