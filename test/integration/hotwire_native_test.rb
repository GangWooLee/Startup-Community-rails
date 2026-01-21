# frozen_string_literal: true

require "test_helper"

class HotwireNativeTest < ActionDispatch::IntegrationTest
  # ============================================================================
  # 레이아웃 선택 테스트
  # ============================================================================

  test "웹 브라우저는 application 레이아웃 사용" do
    get root_path

    assert_response :success
    # 웹 레이아웃은 data-turbo-native 속성이 없음
    assert_no_match(/data-turbo-native/, response.body)
  end

  test "Hotwire Native iOS 앱은 turbo_native 레이아웃 사용" do
    get root_path, headers: { "HTTP_USER_AGENT" => "Mozilla/5.0 Turbo Native iOS" }

    assert_response :success
    # 앱 레이아웃은 data-turbo-native="true" 속성 포함
    assert_match(/data-turbo-native="true"/, response.body)
  end

  test "Hotwire Native Android 앱은 turbo_native 레이아웃 사용" do
    get root_path, headers: { "HTTP_USER_AGENT" => "Mozilla/5.0 Turbo Native Android" }

    assert_response :success
    assert_match(/data-turbo-native="true"/, response.body)
  end

  # ============================================================================
  # 보안 헤더 테스트
  # ============================================================================

  test "응답에 X-Frame-Options 헤더 포함" do
    get root_path

    assert_response :success
    assert_equal "SAMEORIGIN", response.headers["X-Frame-Options"]
  end

  test "응답에 X-Content-Type-Options 헤더 포함" do
    get root_path

    assert_response :success
    assert_equal "nosniff", response.headers["X-Content-Type-Options"]
  end

  test "응답에 Referrer-Policy 헤더 포함" do
    get root_path

    assert_response :success
    assert_equal "strict-origin-when-cross-origin", response.headers["Referrer-Policy"]
  end

  test "응답에 Permissions-Policy 헤더 포함" do
    get root_path

    assert_response :success
    assert_equal "geolocation=(), camera=(), microphone=()", response.headers["Permissions-Policy"]
  end

  # ============================================================================
  # 앱 레이아웃 특성 테스트
  # ============================================================================

  test "앱 레이아웃은 웹 사이드바 제외" do
    # 로그인 페이지는 사이드바가 없으므로 root_path 사용
    get root_path, headers: { "HTTP_USER_AGENT" => "Mozilla/5.0 Turbo Native iOS" }

    assert_response :success
    # turbo_native 레이아웃은 sidebar-collapse 컨트롤러가 없음
    assert_no_match(/data-controller="sidebar-collapse"/, response.body)
  end

  test "앱 레이아웃은 Safe Area 패딩 클래스 포함" do
    get root_path, headers: { "HTTP_USER_AGENT" => "Mozilla/5.0 Turbo Native iOS" }

    assert_response :success
    assert_match(/safe-area-bottom/, response.body)
  end
end
