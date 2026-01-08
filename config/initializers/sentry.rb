# frozen_string_literal: true

# Sentry Error Tracking Configuration
#
# Sentry captures unhandled exceptions and errors in production,
# sending them to the Sentry dashboard for monitoring and alerting.
#
# Setup:
# 1. Create a Sentry project at https://sentry.io
# 2. Get your DSN from Project Settings > Client Keys (DSN)
# 3. Add to credentials: bin/rails credentials:edit
#    sentry:
#      dsn: "https://xxx@xxx.ingest.sentry.io/xxx"
#
# Features enabled:
# - Exception capture with full stack traces
# - Breadcrumbs for request/response tracking
# - Performance tracing (10% sample rate)
# - User context (user_id, email)

if Rails.application.credentials.dig(:sentry, :dsn).present?
  Sentry.init do |config|
    config.dsn = Rails.application.credentials.dig(:sentry, :dsn)

    # Capture breadcrumbs from Rails logger and HTTP requests
    config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]

    # Performance monitoring (sample 10% of transactions)
    config.traces_sample_rate = 0.1

    # Profiling (sample 10% of profiled transactions)
    config.profiles_sample_rate = 0.1

    # Only enable in production and staging
    config.enabled_environments = %w[production staging]
    config.environment = Rails.env

    # Don't send PII by default
    config.send_default_pii = false

    # Filter sensitive parameters
    config.before_send = lambda do |event, hint|
      # Remove sensitive data from event
      if event.request&.data
        event.request.data = event.request.data.except(
          "password", "password_confirmation", "current_password",
          "credit_card", "cvv", "card_number"
        )
      end
      event
    end

    # Exclude common non-error exceptions
    config.excluded_exceptions += [
      "ActionController::RoutingError",
      "ActiveRecord::RecordNotFound",
      "ActionController::InvalidAuthenticityToken"
    ]

    # Set release version if available
    config.release = ENV.fetch("APP_VERSION", nil)
  end
end
