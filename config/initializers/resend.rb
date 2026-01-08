# frozen_string_literal: true

# Resend Email Service Configuration
# https://resend.com/docs/send-with-ruby-on-rails
#
# Resend API key must be set for the gem to work properly.
# The API key is stored in Rails credentials for security.

if Rails.application.credentials.dig(:resend, :api_key).present?
  Resend.api_key = Rails.application.credentials.dig(:resend, :api_key)
end
