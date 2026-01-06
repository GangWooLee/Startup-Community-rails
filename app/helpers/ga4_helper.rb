# frozen_string_literal: true

# GA4 (Google Analytics 4) 이벤트 추적 헬퍼
# 사용법: track_ga4_event('event_name', { param1: value1 })
module Ga4Helper
  # GA4 맞춤 이벤트 추적
  # @param event_name [String] GA4 이벤트 이름 (예: 'sign_up', 'login')
  # @param params [Hash] 이벤트 파라미터
  def track_ga4_event(event_name, params = {})
    # 프로덕션 환경에서만 이벤트 추적
    return unless Rails.env.production?

    flash[:ga4_event] = {
      name: event_name,
      params: params.transform_values { |v| v.is_a?(String) ? v.truncate(100) : v }
    }
  end

  # 여러 GA4 이벤트를 한 번에 추적 (드물게 사용)
  # @param events [Array<Hash>] 이벤트 배열 [{ name: 'event', params: {} }]
  def track_ga4_events(events)
    return unless Rails.env.production?

    flash[:ga4_events] = events.map do |event|
      {
        name: event[:name],
        params: (event[:params] || {}).transform_values { |v| v.is_a?(String) ? v.truncate(100) : v }
      }
    end
  end
end
