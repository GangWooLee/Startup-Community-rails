---
name: deep-linking-expert
description: 딥 링킹 전문가 - Universal Links, App Links, Smart Banner, 공유 기능
triggers:
  - 딥 링크
  - deep link
  - Universal Link
  - App Link
  - 앱 열기
  - 공유
  - smart banner
related_agents:
  - hotwire-native-expert
  - ios-expert
  - android-expert
  - push-notification-expert
related_skills:
  - rails-dev
---

# Deep Linking Expert (딥 링킹 전문가)

## 🎯 역할

모바일 앱 딥 링킹 시스템을 담당합니다:
- Universal Links (iOS) 설정
- App Links (Android) 설정
- Smart App Banner
- 앱 내 공유 기능
- 웹 → 앱 전환 유도
- 푸시 알림 → 특정 화면 이동

---

## 📁 담당 파일

### Rails Server
```
public/.well-known/
├── apple-app-site-association    # iOS Universal Links
└── assetlinks.json               # Android App Links

app/views/shared/
├── _smart_app_banner.html.erb    # Smart App Banner
└── _open_in_app_prompt.html.erb  # 앱 설치/열기 유도

app/controllers/
├── deep_links_controller.rb      # 딥링크 라우팅
```

### iOS
```
ios/StartupCommunity/
├── App/
│   └── SceneDelegate.swift       # Universal Link 처리
│
├── StartupCommunity.entitlements # Associated Domains

Info.plist                        # URL Scheme
```

### Android
```
android/app/src/main/
├── AndroidManifest.xml           # Intent Filter (App Links)
│
├── kotlin/*/
│   └── MainActivity.kt           # 딥링크 처리
```

---

## 🔧 핵심 패턴

### 1. 딥 링킹 유형

```
┌─────────────────────────────────────────────────────────────┐
│                     Deep Linking Types                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. Universal Links (iOS) / App Links (Android)             │
│     https://undrewai.com/posts/123                          │
│     → 앱 설치됨: 앱에서 열림                                │
│     → 앱 미설치: 웹 브라우저에서 열림                       │
│                                                             │
│  2. Custom URL Scheme                                        │
│     startupcommunity://posts/123                            │
│     → 앱 설치됨: 앱에서 열림                                │
│     → 앱 미설치: 에러 (fallback 필요)                       │
│                                                             │
│  3. Deferred Deep Link                                       │
│     앱 미설치 → 앱스토어 → 설치 후 앱 열림                 │
│     → 원래 목적지로 이동                                    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 2. iOS Universal Links 설정

```json
// public/.well-known/apple-app-site-association
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAMID.com.startupcommunity",
        "paths": [
          "/posts/*",
          "/chat_rooms/*",
          "/users/*",
          "/onboarding/*",
          "/notifications"
        ]
      }
    ]
  },
  "webcredentials": {
    "apps": [
      "TEAMID.com.startupcommunity"
    ]
  }
}
```

```ruby
# config/routes.rb
get ".well-known/apple-app-site-association", to: "deep_links#apple_app_site_association"
```

```ruby
# app/controllers/deep_links_controller.rb
class DeepLinksController < ApplicationController
  skip_before_action :authenticate_user!

  def apple_app_site_association
    render json: Rails.root.join("public/.well-known/apple-app-site-association").read,
           content_type: "application/json"
  end
end
```

```swift
// ios/StartupCommunity.entitlements
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN">
<plist version="1.0">
<dict>
  <key>com.apple.developer.associated-domains</key>
  <array>
    <string>applinks:undrewai.com</string>
    <string>webcredentials:undrewai.com</string>
  </array>
</dict>
</plist>
```

### 3. Android App Links 설정

```json
// public/.well-known/assetlinks.json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.startupcommunity",
      "sha256_cert_fingerprints": [
        "SHA256:XX:XX:XX:..."
      ]
    }
  }
]
```

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<activity android:name=".MainActivity"
          android:exported="true">

    <!-- App Links (verified) -->
    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />

        <data android:scheme="https"
              android:host="undrewai.com"
              android:pathPattern="/posts/.*" />
        <data android:pathPattern="/chat_rooms/.*" />
        <data android:pathPattern="/users/.*" />
    </intent-filter>

    <!-- Custom URL Scheme (fallback) -->
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />

        <data android:scheme="startupcommunity" />
    </intent-filter>
</activity>
```

### 4. iOS 딥링크 처리

```swift
// ios/App/SceneDelegate.swift
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        window = UIWindow(windowScene: windowScene)
        Navigator.shared.start(in: window!)

        // 앱 시작 시 딥링크 처리
        if let urlContext = connectionOptions.urlContexts.first {
            handleDeepLink(urlContext.url)
        }
    }

    // Universal Link 수신
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else {
            return
        }
        handleDeepLink(url)
    }

    // Custom URL Scheme 수신
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        handleDeepLink(url)
    }

    private func handleDeepLink(_ url: URL) {
        // 상대 경로 추출
        let path = url.path

        // Navigator로 해당 화면 이동
        let fullURL = URL(string: "https://undrewai.com\(path)")!
        Navigator.shared.visit(url: fullURL)
    }
}
```

### 5. Android 딥링크 처리

```kotlin
// android/MainActivity.kt
class MainActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        // 딥링크 처리
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        when (intent.action) {
            Intent.ACTION_VIEW -> {
                intent.data?.let { uri ->
                    handleDeepLink(uri)
                }
            }
        }

        // 푸시 알림에서 전달된 딥링크
        intent.getStringExtra("deep_link")?.let { path ->
            val uri = Uri.parse("https://undrewai.com$path")
            handleDeepLink(uri)
        }
    }

    private fun handleDeepLink(uri: Uri) {
        val path = uri.path ?: return

        // Navigator로 해당 화면 이동
        val fullUrl = "https://undrewai.com$path"
        Navigator.getInstance(this).visit(fullUrl)
    }
}
```

### 6. Smart App Banner

```erb
<%# app/views/shared/_smart_app_banner.html.erb %>
<%# iOS Safari에서 앱 설치 유도 배너 %>
<meta name="apple-itunes-app"
      content="app-id=YOUR_APP_ID, app-argument=<%= request.original_url %>">

<%# 또는 커스텀 배너 %>
<% unless hotwire_native_app? %>
  <div id="app-banner"
       class="fixed top-0 left-0 right-0 bg-blue-600 text-white p-3 z-50
              flex items-center justify-between"
       data-controller="app-banner">

    <div class="flex items-center gap-3">
      <img src="/app-icon.png" class="w-10 h-10 rounded-lg">
      <div>
        <p class="font-semibold">Startup Community</p>
        <p class="text-sm opacity-80">앱에서 더 빠르게</p>
      </div>
    </div>

    <div class="flex gap-2">
      <button data-action="app-banner#dismiss" class="text-sm opacity-80">
        닫기
      </button>
      <%= link_to "열기", deep_link_url(request.path),
                  class: "bg-white text-blue-600 px-4 py-1 rounded-full font-semibold text-sm" %>
    </div>
  </div>
<% end %>
```

```javascript
// app/javascript/controllers/app_banner_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    if (this.isDismissed()) {
      this.element.remove()
    }
  }

  dismiss() {
    localStorage.setItem("app_banner_dismissed", Date.now())
    this.element.remove()
  }

  isDismissed() {
    const dismissedAt = localStorage.getItem("app_banner_dismissed")
    if (!dismissedAt) return false

    // 7일 후 다시 표시
    const sevenDays = 7 * 24 * 60 * 60 * 1000
    return Date.now() - parseInt(dismissedAt) < sevenDays
  }
}
```

### 7. 공유 기능 (앱 내)

```erb
<%# 게시글 공유 버튼 %>
<div data-controller="share"
     data-share-title-value="<%= @post.title %>"
     data-share-text-value="<%= truncate(@post.content, length: 100) %>"
     data-share-url-value="<%= post_url(@post) %>">
  <button data-action="share#share">
    공유하기
  </button>
</div>
```

```javascript
// app/javascript/controllers/share_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    title: String,
    text: String,
    url: String
  }

  async share() {
    const shareData = {
      title: this.titleValue,
      text: this.textValue,
      url: this.urlValue
    }

    // Web Share API 지원 확인
    if (navigator.share && this.canShare(shareData)) {
      try {
        await navigator.share(shareData)
      } catch (err) {
        if (err.name !== "AbortError") {
          this.fallbackShare()
        }
      }
    } else {
      this.fallbackShare()
    }
  }

  canShare(data) {
    return navigator.canShare ? navigator.canShare(data) : true
  }

  fallbackShare() {
    // 클립보드에 URL 복사
    navigator.clipboard.writeText(this.urlValue)
      .then(() => {
        alert("링크가 복사되었습니다!")
      })
  }
}
```

### 8. 딥링크 헬퍼

```ruby
# app/helpers/deep_link_helper.rb
module DeepLinkHelper
  def deep_link_url(path)
    if ios_browser?
      "https://undrewai.com#{path}"  # Universal Link
    elsif android_browser?
      "intent://undrewai.com#{path}#Intent;" \
      "scheme=https;" \
      "package=com.startupcommunity;" \
      "S.browser_fallback_url=https://undrewai.com#{path};" \
      "end"
    else
      "https://undrewai.com#{path}"
    end
  end

  def app_store_url
    if ios_browser?
      "https://apps.apple.com/app/idXXXXXXXXX"
    elsif android_browser?
      "https://play.google.com/store/apps/details?id=com.startupcommunity"
    end
  end

  private

  def ios_browser?
    request.user_agent.to_s.match?(/iPhone|iPad|iPod/)
  end

  def android_browser?
    request.user_agent.to_s.match?(/Android/)
  end
end
```

---

## ⚠️ 주의사항

### 금지 패턴

| 패턴 | 문제 | 대안 |
|------|------|------|
| HTTP AASA 파일 | iOS에서 검증 안 됨 | HTTPS 필수 |
| 리다이렉트되는 AASA URL | 검증 실패 | 직접 응답 |
| 잘못된 SHA256 fingerprint | App Links 검증 실패 | keytool로 정확한 값 추출 |
| wildcard paths만 사용 | 너무 많은 URL 캡처 | 구체적 경로 지정 |

### AASA/assetlinks 배포 주의

```ruby
# ❌ 문제: 리다이렉트 응답
get ".well-known/apple-app-site-association" => redirect("/some/path")

# ✅ 해결: 직접 JSON 응답
get ".well-known/apple-app-site-association", to: "deep_links#aasa"

# Content-Type 확인
def aasa
  response.headers["Content-Type"] = "application/json"
  render json: aasa_content
end
```

### SHA256 fingerprint 추출

```bash
# 디버그 키
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android

# 릴리스 키
keytool -list -v -keystore release.keystore -alias release-key

# Google Play App Signing 사용 시
# Play Console > 앱 무결성 > 앱 서명 키 인증서에서 SHA-256 확인
```

---

## ✅ 체크리스트

### Universal Links (iOS)
- [ ] AASA 파일 생성 (JSON)
- [ ] HTTPS로 제공
- [ ] Entitlements에 Associated Domains 추가
- [ ] 경로 패턴 정의
- [ ] Apple CDN 캐시 고려 (24시간)

### App Links (Android)
- [ ] assetlinks.json 생성
- [ ] SHA256 fingerprint 정확히 입력
- [ ] AndroidManifest에 intent-filter 추가
- [ ] `android:autoVerify="true"` 설정
- [ ] Digital Asset Links API로 검증

### Smart App Banner
- [ ] 앱 ID 설정
- [ ] 앱 미설치 시 스토어 링크
- [ ] 닫기 상태 저장 (localStorage)
- [ ] 앱 내에서는 배너 숨김

### 공유 기능
- [ ] Web Share API 지원 확인
- [ ] 폴백 (클립보드 복사)
- [ ] OG 메타태그 설정
- [ ] 공유 URL 단축 (선택)

---

## 📊 딥링크 검증 도구

### iOS
```bash
# AASA 검증
curl -I https://undrewai.com/.well-known/apple-app-site-association

# Apple CDN 검증
curl https://app-site-association.cdn-apple.com/a/v1/undrewai.com
```

### Android
```bash
# assetlinks 검증
curl https://undrewai.com/.well-known/assetlinks.json

# Digital Asset Links API 검증
curl "https://digitalassetlinks.googleapis.com/v1/statements:list?source.web.site=https://undrewai.com&relation=delegate_permission/common.handle_all_urls"
```

---

## 🔗 연계 에이전트

| 에이전트 | 협력 포인트 |
|---------|------------|
| `hotwire-native-expert` | Path Configuration 연동 |
| `ios-expert` | SceneDelegate, Entitlements |
| `android-expert` | AndroidManifest, Intent |
| `push-notification-expert` | 알림 탭 → 딥링크 |

---

## 📚 참조 문서

### 공식 문서
- [iOS Universal Links](https://developer.apple.com/documentation/xcode/supporting-associated-domains)
- [Android App Links](https://developer.android.com/training/app-links)
- [Digital Asset Links](https://developers.google.com/digital-asset-links)

### 검증 도구
- [Apple AASA Validator](https://search.developer.apple.com/appsearch-validation-tool/)
- [Google Digital Asset Links API](https://digitalassetlinks.googleapis.com)

### 프로젝트 내부
- [hotwire-native-expert](../core/hotwire-native-expert.md)
- [push-notification-expert](./push-notification-expert.md)
