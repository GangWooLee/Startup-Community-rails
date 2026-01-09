source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.1"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use sqlite3 as the database for Active Record (development/test)
gem "sqlite3", ">= 2.1", group: [ :development, :test ]
# Use PostgreSQL for production
gem "pg", "~> 1.5", group: :production
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"
# Use Tailwind CSS [https://github.com/rails/tailwindcss-rails]
gem "tailwindcss-rails"

# shadcn UI components for Rails [https://shadcn.rails-components.com/]
gem "shadcn-ui"
gem "tailwind_merge"  # Required by shadcn-ui for class merging

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem "bcrypt", "~> 3.1.7"

# OAuth authentication
gem "omniauth"
gem "omniauth-google-oauth2"
gem "omniauth-github"
gem "omniauth-rails_csrf_protection"  # CSRF protection for OmniAuth

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ mswin mswin64 mingw x64_mingw jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"

# Security: Rate limiting and throttling
gem "rack-attack"

# Security: Active Storage file validation
gem "active_storage_validations"

# Error Tracking & Monitoring
gem "sentry-ruby"
gem "sentry-rails"

# Structured JSON Logging
gem "lograge"

# AWS S3 SDK for backups
gem "aws-sdk-s3", require: false

# AI/LLM Integration
gem "langchainrb"           # AI Agent framework for Ruby
gem "ruby-openai"           # OpenAI API client
gem "gemini-ai"             # Google Gemini API client

# Pagination
gem "kaminari"              # Elegant pagination for Rails

# Email delivery via HTTP API (bypasses SMTP port blocking)
gem "resend"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri mswin mswin64 mingw x64_mingw ], require: "debug/prelude"

  # Audits gems for known security defects (use config/bundler-audit.yml to ignore issues)
  gem "bundler-audit", require: false

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  # dotenv-rails 제거됨 - Rails credentials 사용
  # credentials 편집: EDITOR="code --wait" bin/rails credentials:edit
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Claude AI integration for Rails development [https://github.com/obie/claude-on-rails]
  gem "claude-on-rails"

  # Preview emails in browser instead of sending [https://github.com/ryanb/letter_opener]
  gem "letter_opener"
end

group :test do
  # Pin minitest to 5.x (6.0 has breaking changes with Rails 8.1)
  gem "minitest", "~> 5.26"

  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"

  # Adds assigns() and assert_template to controller tests [https://github.com/rails/rails-controller-testing]
  gem "rails-controller-testing"

  # Code coverage analysis [https://github.com/simplecov-ruby/simplecov]
  gem "simplecov", require: false

  # HTTP request stubbing for isolated tests [https://github.com/bblimke/webmock]
  gem "webmock"
end

gem "rails_icons", "~> 1.5"
