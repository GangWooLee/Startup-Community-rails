module Components::AccordionHelper
  # Accordion 컴포넌트 - undrew-design 스타일
  #
  # 사용 예시:
  #   <%= render_accordion do |accordion| %>
  #     <% accordion.item title: "섹션 1", default_open: true do %>
  #       섹션 1의 내용입니다.
  #     <% end %>
  #     <% accordion.item title: "섹션 2" do %>
  #       섹션 2의 내용입니다.
  #     <% end %>
  #   <% end %>
  #
  # Options:
  #   - multiple: true/false (다중 열기 허용, 기본: false)
  #   - variant: :default, :bordered, :separated
  #
  def render_accordion(multiple: false, variant: :default, **options, &block)
    builder = AccordionBuilder.new(self, variant: variant)
    capture(builder, &block) if block

    wrapper_classes = case variant.to_sym
    when :default
      "divide-y divide-border"
    when :bordered
      "border border-border rounded-lg divide-y divide-border overflow-hidden"
    when :separated
      "space-y-2"
    end

    render "components/ui/accordion",
           accordion_id: "accordion-#{SecureRandom.hex(4)}",
           items: builder.items,
           wrapper_classes: wrapper_classes,
           variant: variant,
           multiple: multiple,
           **options
  end

  # Accordion Builder 클래스
  class AccordionBuilder
    attr_reader :items

    def initialize(template, variant:)
      @template = template
      @variant = variant
      @items = []
    end

    def item(title:, subtitle: nil, icon: nil, default_open: false, **options, &block)
      content = @template.capture(&block) if block

      trigger_classes = case @variant
      when :default
        "flex items-center justify-between w-full py-4 text-left font-medium text-foreground hover:text-foreground/80 transition-colors"
      when :bordered
        "flex items-center justify-between w-full px-4 py-4 text-left font-medium text-foreground hover:bg-muted/50 transition-colors"
      when :separated
        "flex items-center justify-between w-full px-4 py-4 text-left font-medium text-foreground bg-card border border-border rounded-lg hover:bg-muted/50 transition-colors"
      end

      content_classes = case @variant
      when :default
        "pb-4 text-muted-foreground"
      when :bordered
        "px-4 pb-4 text-muted-foreground"
      when :separated
        "px-4 pb-4 pt-2 text-muted-foreground bg-card border-x border-b border-border rounded-b-lg -mt-2"
      end

      @items << {
        id: "item-#{SecureRandom.hex(4)}",
        title: title,
        subtitle: subtitle,
        icon: icon,
        content: content,
        default_open: default_open,
        trigger_classes: trigger_classes,
        content_classes: content_classes
      }
    end
  end
end
