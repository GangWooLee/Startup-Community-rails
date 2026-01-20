# frozen_string_literal: true

# WebView/인앱 브라우저 감지 헬퍼
#
# Google은 2016년부터 WebView에서 OAuth 인증을 금지합니다.
# 이유: 앱이 사용자 자격 증명을 가로챌 수 있고, 피싱 공격 위험이 있음.
#
# 사용법:
#   include UserAgentHelper
#   redirect_to warning_path if in_app_browser?
#
module UserAgentHelper
  # 인앱 브라우저(WebView) 여부 확인
  #
  # @return [Boolean] WebView면 true
  def in_app_browser?
    return false if request.user_agent.blank?

    ua = request.user_agent.downcase

    # Android WebView 감지
    # - "wv" 토큰이 있고 Android인 경우
    # - "Version/X.X Chrome" 패턴 (WebView 특유)
    return true if android_webview?(ua)

    # iOS WebView 감지
    # - Mobile/ 있지만 Safari/ 없음 (UIWebView, WKWebView)
    return true if ios_webview?(ua)

    # 소셜 앱 인앱 브라우저 감지
    return true if social_app_webview?(ua)

    false
  end

  # 감지된 앱 이름 반환 (사용자 안내용)
  #
  # @return [String] 앱 이름 또는 "인앱 브라우저"
  def detected_app_name
    return "인앱 브라우저" if request.user_agent.blank?

    ua = request.user_agent.downcase

    case
    when ua.include?("kakaotalk")
      "카카오톡"
    when ua.include?("instagram")
      "Instagram"
    when ua.match?(/fban|fbav/)
      "Facebook"
    when ua.include?("twitter")
      "Twitter/X"
    when ua.include?("line/")
      "LINE"
    when ua.include?("naver")
      "네이버"
    when ua.include?("discord")
      "Discord"
    when ua.include?("slack")
      "Slack"
    else
      "인앱 브라우저"
    end
  end

  # iOS 기기 여부 (Safari에서 열기 버튼 표시용)
  #
  # @return [Boolean]
  def ios_device?
    return false if request.user_agent.blank?

    ua = request.user_agent.downcase
    ua.include?("iphone") || ua.include?("ipad") || ua.include?("ipod")
  end

  # Android 기기 여부
  #
  # @return [Boolean]
  def android_device?
    return false if request.user_agent.blank?

    request.user_agent.downcase.include?("android")
  end

  private

  # Android WebView 감지
  # wv 토큰 또는 Version/X.X Chrome 패턴
  def android_webview?(ua)
    return false unless ua.include?("android")

    # "wv" 토큰은 WebView 표시
    return true if ua.include?("; wv)")

    # "Version/X.X Chrome" 패턴 (일반 Chrome은 "Chrome/X.X")
    return true if ua.match?(/version\/[\d.]+ chrome/)

    false
  end

  # iOS WebView 감지
  # Mobile/ 있지만 Safari/ 없음
  def ios_webview?(ua)
    return false unless ua.include?("iphone") || ua.include?("ipad")

    # Safari 브라우저는 "Safari/" 문자열 포함
    # WebView는 Mobile/만 있고 Safari/ 없음
    ua.include?("mobile/") && !ua.include?("safari/")
  end

  # 소셜 앱 인앱 브라우저 감지
  def social_app_webview?(ua)
    # Facebook (FBAN = Facebook App Name, FBAV = Facebook App Version)
    return true if ua.match?(/fban|fbav/)

    # Instagram
    return true if ua.include?("instagram")

    # Twitter/X
    return true if ua.include?("twitter")

    # LINE
    return true if ua.include?("line/")

    # KakaoTalk
    return true if ua.include?("kakaotalk")

    # Naver
    return true if ua.include?("naver")

    # Discord
    return true if ua.include?("discord")

    # Slack
    return true if ua.include?("slack")

    false
  end
end
