module Components::AvatarHelper
  def render_avatar(src: nil, alt: nil, fallback: "?", size: :md, **options)
    size_classes = case size.to_sym
    when :xs
      "h-6 w-6 text-xs"
    when :sm
      "h-8 w-8 text-sm"
    when :md
      "h-10 w-10 text-base"
    when :lg
      "h-12 w-12 text-lg"
    when :xl
      "h-16 w-16 text-xl"
    when :xxl
      "h-20 w-20 text-2xl"
    else
      "h-10 w-10 text-base"
    end

    extra_classes = options[:class] || ""
    base_classes = "relative inline-flex shrink-0 overflow-hidden rounded-full #{size_classes} #{extra_classes}"

    content_tag :div, class: base_classes do
      if src.present?
        image_tag src, alt: alt || "", class: "aspect-square h-full w-full object-cover"
      else
        content_tag :div, class: "flex h-full w-full items-center justify-center bg-muted text-muted-foreground font-medium" do
          fallback.to_s.first.upcase
        end
      end
    end
  end
end
