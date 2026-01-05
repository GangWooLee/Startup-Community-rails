require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Store uploaded files on AWS S3 (see config/storage.yml for options).
  # ✅ 프로덕션: S3 사용 (이미지, 아바타 등)
  config.active_storage.service = :amazon

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  config.assume_ssl = ENV.fetch("RAILS_ASSUME_SSL", "true") == "true"

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = ENV.fetch("RAILS_FORCE_SSL", "true") == "true"

  # Skip http-to-https redirect for the default health check endpoint.
  config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)

  # Change to "debug" to log everything (including potentially personally-identifiable information!).
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # ===== Lograge 설정 (구조화된 JSON 로깅) =====
  config.lograge.enabled = true
  config.lograge.formatter = Lograge::Formatters::Json.new
  config.lograge.custom_options = lambda do |event|
    {
      time: Time.current.iso8601,
      request_id: event.payload[:request_id],
      user_id: event.payload[:user_id],
      ip: event.payload[:ip],
      user_agent: event.payload[:user_agent]
    }.compact
  end
  config.lograge.custom_payload do |controller|
    {
      user_id: controller.current_user&.id,
      ip: controller.request.remote_ip,
      user_agent: controller.request.user_agent&.truncate(100)
    }
  end

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Replace the default in-process memory cache store with a durable alternative.
  config.cache_store = :solid_cache_store

  # Replace the default in-process and non-durable queuing backend for Active Job.
  config.active_job.queue_adapter = :solid_queue
  config.solid_queue.connects_to = { database: { writing: :queue } }

  # ===== 이메일 설정 =====
  # 이메일 발송 활성화 (회원가입, 알림 등)
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true

  # 호스트 설정 (이메일 링크용)
  config.action_mailer.default_url_options = {
    host: ENV.fetch("MAILER_HOST") { ENV.fetch("ALLOWED_HOSTS", "").split(",").first || "example.com" },
    protocol: 'https'
  }

  # SMTP 서버 설정 (credentials에서 로드)
  config.action_mailer.smtp_settings = {
    address: Rails.application.credentials.dig(:production, :smtp, :address),
    port: Rails.application.credentials.dig(:production, :smtp, :port) || 587,
    domain: Rails.application.credentials.dig(:production, :smtp, :domain),
    user_name: Rails.application.credentials.dig(:production, :smtp, :user_name),
    password: Rails.application.credentials.dig(:production, :smtp, :password),
    authentication: :plain,
    enable_starttls_auto: true
  }

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [ :id ]

  # Enable DNS rebinding protection and other `Host` header attacks.
  # 환경변수로 허용할 호스트 설정 (쉼표로 구분)
  # 예: ALLOWED_HOSTS=example.com,www.example.com
  if ENV["ALLOWED_HOSTS"].present?
    config.hosts = ENV["ALLOWED_HOSTS"].split(",").map(&:strip)
  end

  # Skip DNS rebinding protection for the default health check endpoint.
  config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
end
