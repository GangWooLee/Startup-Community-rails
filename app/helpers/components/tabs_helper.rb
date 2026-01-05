module Components::TabsHelper
  # Tabs 컴포넌트 - undrew-design 스타일
  #
  # 사용 예시:
  #   <%= render_tabs default: "posts" do |tabs| %>
  #     <% tabs.list do %>
  #       <%= tabs.trigger "posts", label: "게시글" %>
  #       <%= tabs.trigger "comments", label: "댓글" %>
  #       <%= tabs.trigger "likes", label: "좋아요" %>
  #     <% end %>
  #     <% tabs.panel "posts" do %>
  #       게시글 목록...
  #     <% end %>
  #     <% tabs.panel "comments" do %>
  #       댓글 목록...
  #     <% end %>
  #     <% tabs.panel "likes" do %>
  #       좋아요 목록...
  #     <% end %>
  #   <% end %>
  #
  # Variants: :default, :pills, :underline
  #
  def render_tabs(default: nil, variant: :default, **options, &block)
    builder = TabsBuilder.new(self, default: default, variant: variant)
    capture(builder, &block) if block

    render "components/ui/tabs",
           tabs_id: "tabs-#{SecureRandom.hex(4)}",
           default_tab: default,
           variant: variant,
           list_content: builder.list_content,
           panels: builder.panels,
           **options
  end

  # Tabs Builder 클래스
  class TabsBuilder
    attr_reader :list_content, :panels

    def initialize(template, default:, variant:)
      @template = template
      @default = default
      @variant = variant
      @list_content = nil
      @panels = []
    end

    def list(**options, &block)
      @list_options = options
      @list_content = @template.capture(&block)
    end

    def trigger(id, label:, icon: nil, count: nil, **options)
      active = (id.to_s == @default.to_s)

      base_classes = "relative px-4 py-2 text-sm font-medium transition-all cursor-pointer"

      variant_classes = case @variant
      when :default
        if active
          "text-foreground bg-card shadow-sm rounded-md"
        else
          "text-muted-foreground hover:text-foreground"
        end
      when :pills
        if active
          "text-primary-foreground bg-primary rounded-full"
        else
          "text-muted-foreground hover:bg-muted rounded-full"
        end
      when :underline
        if active
          "text-foreground border-b-2 border-primary -mb-px"
        else
          "text-muted-foreground hover:text-foreground border-b-2 border-transparent -mb-px"
        end
      end

      classes = @template.tw(base_classes, variant_classes, options[:class])

      @template.content_tag(:button, type: "button", class: classes,
                            data: {
                              "tabs-target": "trigger",
                              action: "click->tabs#select",
                              "tab-id": id
                            },
                            role: "tab",
                            "aria-selected": active.to_s,
                            "aria-controls": "panel-#{id}") do
        @template.safe_join([
          icon.present? ? @template.content_tag(:span, @template.raw(icon), class: "mr-2") : nil,
          @template.content_tag(:span, label),
          count.present? ? @template.content_tag(:span, count, class: "ml-2 px-1.5 py-0.5 text-xs rounded-full bg-muted") : nil
        ].compact)
      end
    end

    def panel(id, **options, &block)
      active = (id.to_s == @default.to_s)
      content = @template.capture(&block)
      @panels << { id: id, content: content, active: active, options: options }
    end
  end
end
