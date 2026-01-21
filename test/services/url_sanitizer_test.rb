# frozen_string_literal: true

require "test_helper"

class UrlSanitizerTest < ActiveSupport::TestCase
  # =========================================
  # Valid Public URLs
  # =========================================

  test "should accept valid https URL" do
    assert UrlSanitizer.safe?("https://example.com/image.png")
  end

  test "should accept valid http URL" do
    assert UrlSanitizer.safe?("http://example.com/image.jpg")
  end

  test "should accept URL with port" do
    # example.com은 IANA 예약 도메인으로 DNS 해석 가능
    assert UrlSanitizer.safe?("https://example.com:443/image.png")
  end

  # =========================================
  # Localhost Rejection (SSRF Prevention)
  # =========================================

  test "should reject localhost" do
    assert_not UrlSanitizer.safe?("http://localhost/image.png")
    assert_not UrlSanitizer.safe?("https://localhost:3000/image.png")
  end

  test "should reject 127.0.0.1 (loopback IPv4)" do
    assert_not UrlSanitizer.safe?("http://127.0.0.1/image.png")
    assert_not UrlSanitizer.safe?("http://127.0.0.1:8080/secret.txt")
  end

  test "should reject any 127.x.x.x range" do
    assert_not UrlSanitizer.safe?("http://127.0.0.2/image.png")
    assert_not UrlSanitizer.safe?("http://127.255.255.255/image.png")
  end

  # =========================================
  # Private IP Ranges Rejection (SSRF Prevention)
  # =========================================

  test "should reject 10.x.x.x (Class A private)" do
    assert_not UrlSanitizer.safe?("http://10.0.0.1/image.png")
    assert_not UrlSanitizer.safe?("http://10.255.255.255/image.png")
  end

  test "should reject 172.16.x.x - 172.31.x.x (Class B private)" do
    assert_not UrlSanitizer.safe?("http://172.16.0.1/image.png")
    assert_not UrlSanitizer.safe?("http://172.31.255.255/image.png")
  end

  test "should reject 192.168.x.x (Class C private)" do
    assert_not UrlSanitizer.safe?("http://192.168.1.1/image.png")
    assert_not UrlSanitizer.safe?("http://192.168.0.1/admin/config")
  end

  test "should reject 169.254.x.x (link-local)" do
    assert_not UrlSanitizer.safe?("http://169.254.169.254/latest/meta-data/")
  end

  # =========================================
  # IPv6 Private Address Rejection
  # =========================================

  test "should reject IPv6 loopback (::1)" do
    assert_not UrlSanitizer.safe?("http://[::1]/image.png")
  end

  # Step 2: IPv6 unique local (fc00::/7) 커버리지
  test "should reject IPv6 unique local addresses (fc00::/7)" do
    # fc00::/8 범위 (아직 할당되지 않음)
    assert_not UrlSanitizer.safe?("http://[fc00::1]/image.png")
    # fd00::/8 범위 (실제 사용되는 unique local)
    assert_not UrlSanitizer.safe?("http://[fd00::1]/image.png")
    assert_not UrlSanitizer.safe?("http://[fdff:ffff:ffff:ffff:ffff:ffff:ffff:ffff]/image.png")
  end

  # Step 2: IPv6 link-local (fe80::/10) 커버리지
  test "should reject IPv6 link-local addresses (fe80::/10)" do
    assert_not UrlSanitizer.safe?("http://[fe80::1]/image.png")
    assert_not UrlSanitizer.safe?("http://[fe80::1%eth0]/image.png")  # zone ID 포함
    assert_not UrlSanitizer.safe?("http://[febf:ffff:ffff:ffff:ffff:ffff:ffff:ffff]/image.png")
  end

  # =========================================
  # Invalid URL Formats
  # =========================================

  test "should reject non-http schemes" do
    assert_not UrlSanitizer.safe?("ftp://example.com/image.png")
    assert_not UrlSanitizer.safe?("file:///etc/passwd")
    assert_not UrlSanitizer.safe?("javascript:alert(1)")
  end

  test "should reject malformed URLs" do
    assert_not UrlSanitizer.safe?("not-a-valid-url")
    assert_not UrlSanitizer.safe?("")
    assert_not UrlSanitizer.safe?(nil)
  end

  test "should reject URL without host" do
    assert_not UrlSanitizer.safe?("http:///path/to/image.png")
  end

  # =========================================
  # DNS Rebinding Prevention
  # =========================================

  test "should resolve hostname and check IP" do
    # localhost resolves to 127.0.0.1
    assert_not UrlSanitizer.safe?("http://localhost/image.png")
  end

  # =========================================
  # Edge Cases
  # =========================================

  test "should handle URL with query params" do
    assert UrlSanitizer.safe?("https://example.com/image.png?size=large")
  end

  test "should handle URL with fragments" do
    assert UrlSanitizer.safe?("https://example.com/page#section")
  end

  test "should handle URL with special characters in path" do
    assert UrlSanitizer.safe?("https://example.com/images/photo%20(1).jpg")
  end
end
