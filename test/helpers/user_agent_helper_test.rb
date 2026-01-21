# frozen_string_literal: true

require "test_helper"

class UserAgentHelperTest < ActionView::TestCase
  include UserAgentHelper

  # Mock request object for testing
  class MockRequest
    attr_accessor :user_agent

    def initialize(ua = nil)
      @user_agent = ua
    end
  end

  def request
    @mock_request ||= MockRequest.new
  end

  # ============================================================================
  # hotwire_native_app? Tests
  # ============================================================================

  test "hotwire_native_app? returns false for nil user agent" do
    request.user_agent = nil

    assert_not hotwire_native_app?
  end

  test "hotwire_native_app? returns false for empty user agent" do
    request.user_agent = ""

    assert_not hotwire_native_app?
  end

  test "hotwire_native_app? returns true for Turbo Native iOS" do
    request.user_agent = "Mozilla/5.0 Turbo Native iOS"

    assert hotwire_native_app?
  end

  test "hotwire_native_app? returns true for Turbo Native Android" do
    request.user_agent = "Mozilla/5.0 Turbo Native Android"

    assert hotwire_native_app?
  end

  test "hotwire_native_app? returns false for normal Safari" do
    request.user_agent = "Mozilla/5.0 (iPhone; CPU iPhone OS 14_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0.3 Mobile/15E148 Safari/604.1"

    assert_not hotwire_native_app?
  end

  test "hotwire_native_app? returns false for normal Chrome" do
    request.user_agent = "Mozilla/5.0 (Linux; Android 10; SM-G960F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36"

    assert_not hotwire_native_app?
  end

  # ============================================================================
  # hotwire_native_ios? Tests
  # ============================================================================

  test "hotwire_native_ios? returns true for Turbo Native iOS" do
    request.user_agent = "Mozilla/5.0 Turbo Native iOS"

    assert hotwire_native_ios?
  end

  test "hotwire_native_ios? returns false for Turbo Native Android" do
    request.user_agent = "Mozilla/5.0 Turbo Native Android"

    assert_not hotwire_native_ios?
  end

  test "hotwire_native_ios? returns false for normal browser" do
    request.user_agent = "Mozilla/5.0 Safari/604.1"

    assert_not hotwire_native_ios?
  end

  # ============================================================================
  # hotwire_native_android? Tests
  # ============================================================================

  test "hotwire_native_android? returns true for Turbo Native Android" do
    request.user_agent = "Mozilla/5.0 Turbo Native Android"

    assert hotwire_native_android?
  end

  test "hotwire_native_android? returns false for Turbo Native iOS" do
    request.user_agent = "Mozilla/5.0 Turbo Native iOS"

    assert_not hotwire_native_android?
  end

  test "hotwire_native_android? returns false for normal browser" do
    request.user_agent = "Mozilla/5.0 Chrome/91.0"

    assert_not hotwire_native_android?
  end

  # ============================================================================
  # in_app_browser? Tests
  # ============================================================================

  test "in_app_browser? returns false for nil user agent" do
    request.user_agent = nil

    assert_not in_app_browser?
  end

  test "in_app_browser? returns false for empty user agent" do
    request.user_agent = ""

    assert_not in_app_browser?
  end

  test "in_app_browser? detects Android WebView with wv token" do
    request.user_agent = "Mozilla/5.0 (Linux; Android 10; SM-G960F; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/91.0.4472.120 Mobile Safari/537.36"

    assert in_app_browser?
  end

  test "in_app_browser? detects Android WebView with Version/X.X Chrome pattern" do
    request.user_agent = "Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 Version/4.0 Chrome/91.0 Mobile Safari/537.36"

    assert in_app_browser?
  end

  test "in_app_browser? detects iOS WebView (Mobile/ without Safari/)" do
    request.user_agent = "Mozilla/5.0 (iPhone; CPU iPhone OS 14_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148"

    assert in_app_browser?
  end

  test "in_app_browser? returns false for normal Safari" do
    request.user_agent = "Mozilla/5.0 (iPhone; CPU iPhone OS 14_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0.3 Mobile/15E148 Safari/604.1"

    assert_not in_app_browser?
  end

  test "in_app_browser? returns false for normal Chrome on Android" do
    request.user_agent = "Mozilla/5.0 (Linux; Android 10; SM-G960F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36"

    assert_not in_app_browser?
  end

  test "in_app_browser? detects KakaoTalk" do
    request.user_agent = "Mozilla/5.0 (iPhone; CPU iPhone OS 14_4 like Mac OS X) AppleWebKit/605.1.15 Mobile/15E148 KAKAOTALK 9.5.5"

    assert in_app_browser?
  end

  test "in_app_browser? detects Instagram" do
    request.user_agent = "Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15 Mobile/15E148 Instagram 152.0.0.24.117"

    assert in_app_browser?
  end

  test "in_app_browser? detects Facebook with FBAN token" do
    request.user_agent = "Mozilla/5.0 (iPhone; CPU iPhone OS 14_4 like Mac OS X) [FBAN/FBIOS;FBDV/iPhone12,1]"

    assert in_app_browser?
  end

  test "in_app_browser? detects Facebook with FBAV token" do
    request.user_agent = "Mozilla/5.0 (Linux; Android 10) [FBAV/330.0.0.0]"

    assert in_app_browser?
  end

  test "in_app_browser? detects Twitter" do
    request.user_agent = "Mozilla/5.0 (iPhone) Twitter for iPhone"

    assert in_app_browser?
  end

  test "in_app_browser? detects LINE" do
    request.user_agent = "Mozilla/5.0 (iPhone) Line/12.0.0"

    assert in_app_browser?
  end

  test "in_app_browser? detects Naver" do
    request.user_agent = "Mozilla/5.0 (iPhone) Naver(inapp)"

    assert in_app_browser?
  end

  test "in_app_browser? detects Discord" do
    request.user_agent = "Mozilla/5.0 (iPhone) Discord/100.0"

    assert in_app_browser?
  end

  test "in_app_browser? detects Slack" do
    request.user_agent = "Mozilla/5.0 (iPhone) Slack/22.0"

    assert in_app_browser?
  end

  # ============================================================================
  # detected_app_name Tests
  # ============================================================================

  test "detected_app_name returns 카카오톡 for KakaoTalk UA" do
    request.user_agent = "Mozilla/5.0 KAKAOTALK 9.5.5"

    assert_equal "카카오톡", detected_app_name
  end

  test "detected_app_name returns Instagram for Instagram UA" do
    request.user_agent = "Mozilla/5.0 Instagram 152.0"

    assert_equal "Instagram", detected_app_name
  end

  test "detected_app_name returns Facebook for Facebook UA" do
    request.user_agent = "Mozilla/5.0 [FBAN/FBIOS]"

    assert_equal "Facebook", detected_app_name
  end

  test "detected_app_name returns Twitter/X for Twitter UA" do
    request.user_agent = "Mozilla/5.0 Twitter for iPhone"

    assert_equal "Twitter/X", detected_app_name
  end

  test "detected_app_name returns LINE for LINE UA" do
    request.user_agent = "Mozilla/5.0 Line/12.0"

    assert_equal "LINE", detected_app_name
  end

  test "detected_app_name returns 네이버 for Naver UA" do
    request.user_agent = "Mozilla/5.0 Naver(inapp)"

    assert_equal "네이버", detected_app_name
  end

  test "detected_app_name returns Discord for Discord UA" do
    request.user_agent = "Mozilla/5.0 Discord/100.0"

    assert_equal "Discord", detected_app_name
  end

  test "detected_app_name returns Slack for Slack UA" do
    request.user_agent = "Mozilla/5.0 Slack/22.0"

    assert_equal "Slack", detected_app_name
  end

  test "detected_app_name returns 인앱 브라우저 for generic WebView" do
    request.user_agent = "Mozilla/5.0 (Linux; Android 10; wv)"

    assert_equal "인앱 브라우저", detected_app_name
  end

  test "detected_app_name returns 인앱 브라우저 for blank UA" do
    request.user_agent = nil

    assert_equal "인앱 브라우저", detected_app_name
  end

  # ============================================================================
  # ios_device? Tests
  # ============================================================================

  test "ios_device? returns true for iPhone" do
    request.user_agent = "Mozilla/5.0 (iPhone; CPU iPhone OS 14_4)"

    assert ios_device?
  end

  test "ios_device? returns true for iPad" do
    request.user_agent = "Mozilla/5.0 (iPad; CPU iPad OS 14_4)"

    assert ios_device?
  end

  test "ios_device? returns true for iPod" do
    request.user_agent = "Mozilla/5.0 (iPod touch; CPU iPhone OS 14_4)"

    assert ios_device?
  end

  test "ios_device? returns false for Android" do
    request.user_agent = "Mozilla/5.0 (Linux; Android 10)"

    assert_not ios_device?
  end

  test "ios_device? returns false for blank UA" do
    request.user_agent = nil

    assert_not ios_device?
  end

  # ============================================================================
  # android_device? Tests
  # ============================================================================

  test "android_device? returns true for Android" do
    request.user_agent = "Mozilla/5.0 (Linux; Android 10)"

    assert android_device?
  end

  test "android_device? returns false for iPhone" do
    request.user_agent = "Mozilla/5.0 (iPhone; CPU iPhone OS 14_4)"

    assert_not android_device?
  end

  test "android_device? returns false for blank UA" do
    request.user_agent = nil

    assert_not android_device?
  end
end
