# frozen_string_literal: true

# Kaminari pagination configuration
# This initializer ensures Kaminari is properly loaded and extends ActiveRecord

Kaminari.configure do |config|
  config.default_per_page = 10
  config.max_per_page = 100
  config.window = 2
  config.outer_window = 0
  config.left = 0
  config.right = 0
  # config.page_method_name = :page
  # config.param_name = :page
end
