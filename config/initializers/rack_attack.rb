# frozen_string_literal: true

# Rack::Attack configuration for rate limiting and brute force protection
# https://github.com/rack/rack-attack

class Rack::Attack
  ### Configure Cache ###
  # Rack::Attack uses Rails.cache by default

  ### Throttle Settings ###

  # Throttle all requests by IP (300 requests per 5 minutes)
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?("/assets", "/up")
  end

  # Throttle login attempts by IP address (5 requests per 20 seconds)
  throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
    if req.path == "/login" && req.post?
      req.ip
    end
  end

  # Throttle login attempts by email (5 requests per 5 minutes)
  throttle("logins/email", limit: 5, period: 5.minutes) do |req|
    if req.path == "/login" && req.post?
      # Normalize email to prevent bypass attempts
      req.params["email"].to_s.downcase.gsub(/\s+/, "").presence
    end
  end

  # Throttle signup attempts by IP (5 requests per hour)
  throttle("signups/ip", limit: 5, period: 1.hour) do |req|
    if req.path == "/signup" && req.post?
      req.ip
    end
  end

  # Throttle post creation by IP (10 posts per hour)
  throttle("posts/ip", limit: 10, period: 1.hour) do |req|
    if req.path == "/posts" && req.post?
      req.ip
    end
  end

  # Throttle comment creation by IP (30 comments per hour)
  throttle("comments/ip", limit: 30, period: 1.hour) do |req|
    if req.path.match?(%r{/posts/\d+/comments}) && req.post?
      req.ip
    end
  end

  # Throttle email verification requests by IP
  # 회원가입 이메일 인증: 10회/시간
  throttle("email_verification/ip", limit: 10, period: 1.hour) do |req|
    if req.path == "/email_verifications" && req.post?
      req.ip
    end
  end

  # Throttle account recovery requests by IP
  # 비밀번호 찾기: 5회/시간
  throttle("forgot_password/ip", limit: 5, period: 1.hour) do |req|
    if req.path == "/password/forgot" && req.post?
      req.ip
    end
  end

  # 비밀번호 찾기: 이메일당 3회/시간 (더 엄격한 제한)
  throttle("forgot_password/email", limit: 3, period: 1.hour) do |req|
    if req.path == "/password/forgot" && req.post?
      req.params["email"].to_s.downcase.gsub(/\s+/, "").presence
    end
  end

  # 비밀번호 재설정: 5회/시간
  throttle("password_reset/ip", limit: 5, period: 1.hour) do |req|
    if req.path.match?(%r{/password/reset/}) && req.patch?
      req.ip
    end
  end

  ### Blocklist ###

  # Block suspicious requests (SQL injection attempts, etc.)
  blocklist("block/malicious") do |req|
    # Block requests with suspicious patterns
    # Wrap in rescue to handle cache unavailability during initial deployment
    begin
      Rack::Attack::Fail2Ban.filter("pentesters-#{req.ip}", maxretry: 3, findtime: 10.minutes, bantime: 1.hour) do
        req.path.include?("..") ||
          req.query_string.include?("UNION") ||
          req.query_string.include?("SELECT") ||
          req.path.include?(".php") ||
          req.path.include?("wp-admin") ||
          req.path.include?("xmlrpc")
      end
    rescue ActiveRecord::StatementInvalid, PG::UndefinedTable => e
      Rails.logger.warn "[Rack::Attack] Cache unavailable: #{e.message}"
      false
    end
  end

  ### Custom Responses ###

  # Return a custom response for throttled requests
  throttled_responder = lambda do |request|
    match_data = request.env["rack.attack.match_data"]
    now = Time.now.utc
    retry_after = match_data[:period] - (now.to_i % match_data[:period])

    [
      429,
      {
        "Content-Type" => "application/json",
        "Retry-After" => retry_after.to_s
      },
      [{ error: "요청이 너무 많습니다. #{retry_after}초 후에 다시 시도해주세요." }.to_json]
    ]
  end

  self.throttled_responder = throttled_responder

  # Custom response for blocked requests
  blocklisted_responder = lambda do |request|
    [
      403,
      { "Content-Type" => "application/json" },
      [{ error: "접근이 차단되었습니다." }.to_json]
    ]
  end

  self.blocklisted_responder = blocklisted_responder

  ### Logging ###

  # Log throttled requests
  ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |_name, _start, _finish, _request_id, payload|
    request = payload[:request]
    Rails.logger.warn "[Rack::Attack] Throttled #{request.ip} - #{request.path}"
  end

  # Log blocked requests
  ActiveSupport::Notifications.subscribe("blocklist.rack_attack") do |_name, _start, _finish, _request_id, payload|
    request = payload[:request]
    Rails.logger.warn "[Rack::Attack] Blocked #{request.ip} - #{request.path}"
  end
end
