module Components::DropdownHelper
  # Dropdown 메뉴 컴포넌트 - undrew-design 스타일
  #
  # 사용 예시:
  #   <%= render_dropdown do |dropdown| %>
  #     <% dropdown.trigger do %>
  #       <%= render_button "옵션", variant: :outline %>
  #     <% end %>
  #     <% dropdown.menu do %>
  #       <%= dropdown_item "프로필", href: profile_path %>
  #       <%= dropdown_item "설정", href: settings_path %>
  #       <%= dropdown_separator %>
  #       <%= dropdown_item "로그아웃", href: logout_path, variant: :destructive %>
  #     <% end %>
  #   <% end %>
  #
  # Options:
  #   - align: :left, :right, :center (기본: :right)
  #   - side: :bottom, :top (기본: :bottom)
  #
  def render_dropdown(align: :right, side: :bottom, **options, &block)
    builder = DropdownBuilder.new(self)
    capture(builder, &block) if block

    align_classes = case align.to_sym
    when :left then "left-0"
    when :right then "right-0"
    when :center then "left-1/2 -translate-x-1/2"
    end

    side_classes = case side.to_sym
    when :bottom then "top-full mt-1"
    when :top then "bottom-full mb-1"
    end

    render "components/ui/dropdown",
           trigger_content: builder.trigger_content,
           menu_content: builder.menu_content,
           align_classes: align_classes,
           side_classes: side_classes,
           **options
  end

  # Dropdown 아이템
  def dropdown_item(label, href: nil, variant: :default, icon: nil, **options, &block)
    item_classes = "flex items-center gap-2 w-full px-3 py-2 text-sm rounded-md transition-colors cursor-pointer"

    variant_classes = case variant.to_sym
    when :default
      "text-foreground hover:bg-accent hover:text-accent-foreground"
    when :destructive
      "text-destructive hover:bg-destructive/10"
    end

    item_classes = tw(item_classes, variant_classes, options[:class])
    content = block ? capture(&block) : label

    if href.present?
      link_to(href, class: item_classes, **options.except(:class)) do
        safe_join([
          icon.present? ? content_tag(:span, raw(icon), class: "flex-shrink-0") : nil,
          content_tag(:span, content)
        ].compact)
      end
    else
      content_tag(:button, type: "button", class: item_classes, **options.except(:class)) do
        safe_join([
          icon.present? ? content_tag(:span, raw(icon), class: "flex-shrink-0") : nil,
          content_tag(:span, content)
        ].compact)
      end
    end
  end

  # Dropdown 구분선
  def dropdown_separator
    content_tag(:div, "", class: "h-px bg-border my-1")
  end

  # Dropdown 라벨 (그룹 헤더)
  def dropdown_label(text)
    content_tag(:div, text, class: "px-3 py-1.5 text-xs font-semibold text-muted-foreground")
  end

  # Dropdown Builder 클래스
  class DropdownBuilder
    attr_reader :trigger_content, :menu_content

    def initialize(template)
      @template = template
      @trigger_content = nil
      @menu_content = nil
    end

    def trigger(&block)
      @trigger_content = @template.capture(&block)
    end

    def menu(&block)
      @menu_content = @template.capture(&block)
    end
  end
end
