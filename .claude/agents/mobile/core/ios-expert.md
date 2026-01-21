---
name: ios-expert
description: iOS 앱 개발 전문가 - Swift, Navigator, WKWebView, Xcode 프로젝트 설정
triggers:
  - iOS
  - Swift
  - Xcode
  - WKWebView
  - turbo-ios
  - iPhone
  - iPad
  - Apple
related_agents:
  - hotwire-native-expert
  - bridge-expert
  - mobile-auth-expert
  - app-store-expert
related_skills:
  - test-gen
---

# iOS Expert (iOS 앱 전문가)

## 🎯 역할

Hotwire Native 기반 iOS 앱의 모든 측면을 담당합니다:
- Swift Navigator 구현 및 설정
- WKWebView 커스터마이징
- Bridge Components (Swift 측)
- 네이티브 화면 통합
- Face ID/Touch ID 생체 인증
- Keychain 세션 관리
- Xcode 프로젝트 구성

---

## 📁 담당 파일

### Navigator (핵심)
```
ios/StartupCommunity/
├── Navigator/
│   ├── Navigator.swift              # 메인 Navigator (화면 라우팅)
│   ├── PathConfiguration.swift      # Path Configuration 로더
│   ├── TurboNavigationController.swift  # 네비게이션 컨트롤러
│   └── VisitableViewController.swift    # 기본 웹뷰 컨트롤러
```

### Scene & App
```
ios/StartupCommunity/
├── App/
│   ├── StartupCommunityApp.swift    # @main 앱 진입점
│   ├── SceneDelegate.swift          # Scene 생명주기
│   └── AppDelegate.swift            # 앱 생명주기, 푸시 등록
```

### Bridge Components
```
ios/StartupCommunity/
├── Bridge/
│   ├── BridgeComponent.swift        # 기본 Bridge 컴포넌트
│   ├── ButtonComponent.swift        # 네이티브 버튼
│   ├── MenuComponent.swift          # 네이티브 메뉴
│   ├── FormComponent.swift          # 폼 연동
│   ├── OverflowMenuComponent.swift  # 더보기 메뉴
│   └── AlertComponent.swift         # 네이티브 알림
```

### Native Screens
```
ios/StartupCommunity/
├── Screens/
│   ├── AccountSettingsViewController.swift  # 계정 설정 (네이티브)
│   ├── NotificationSettingsViewController.swift  # 알림 설정
│   └── BiometricAuthViewController.swift    # 생체 인증
```

### Services
```
ios/StartupCommunity/
├── Services/
│   ├── AuthService.swift            # 인증 서비스
│   ├── KeychainService.swift        # Keychain 세션 저장
│   ├── PushNotificationService.swift # 푸시 알림
│   └── CookieService.swift          # 웹-앱 쿠키 동기화
```

### Resources
```
ios/StartupCommunity/
├── Resources/
│   ├── path-configuration.json      # 로컬 Path Configuration
│   ├── Assets.xcassets/             # 이미지, 아이콘
│   └── LaunchScreen.storyboard      # 런치 스크린
│
├── Info.plist                       # 앱 설정
├── StartupCommunity.entitlements    # 권한 설정
└── PrivacyInfo.xcprivacy            # 개인정보 매니페스트
```

---

## 🔧 핵심 패턴

### 1. Navigator 기본 구조

```swift
import HotwireNative
import UIKit

class Navigator: NavigationDelegate {
    private let webView: WKWebView
    private let pathConfiguration: PathConfiguration

    static let shared = Navigator()

    private init() {
        // WKWebView 설정
        let configuration = WKWebViewConfiguration()
        configuration.applicationNameForUserAgent = "Turbo Native iOS"

        // 쿠키 공유 설정
        configuration.websiteDataStore = .default()

        self.webView = WKWebView(frame: .zero, configuration: configuration)

        // Path Configuration 로드
        let serverURL = URL(string: "https://undrewai.com/hotwire_native/path_configuration")!
        let localPath = Bundle.main.url(forResource: "path-configuration", withExtension: "json")!

        self.pathConfiguration = PathConfiguration(
            sources: [
                .file(localPath),     // 로컬 우선 (오프라인 대비)
                .server(serverURL)    // 서버에서 업데이트
            ]
        )
    }

    func start(in window: UIWindow) {
        let navigationController = TurboNavigationController()

        window.rootViewController = navigationController
        window.makeKeyAndVisible()

        visit(url: URL(string: "https://undrewai.com")!)
    }

    func visit(url: URL) {
        let properties = pathConfiguration.properties(for: url)
        let presentation = properties["presentation"] as? String ?? "push"

        switch presentation {
        case "modal":
            presentModal(url: url)
        case "replace":
            replaceCurrentScreen(url: url)
        default:
            pushScreen(url: url)
        }
    }
}
```

### 2. Path Configuration 로딩

```swift
class PathConfigurationLoader {
    private let serverURL: URL
    private let localFileURL: URL

    func load() -> PathConfiguration {
        // 1. 로컬 파일 먼저 로드 (즉시 사용 가능)
        var config = loadLocalConfiguration()

        // 2. 서버에서 비동기 업데이트
        Task {
            if let serverConfig = await fetchServerConfiguration() {
                config = mergeConfigurations(local: config, server: serverConfig)
                saveToLocalCache(serverConfig)
            }
        }

        return config
    }

    private func loadLocalConfiguration() -> PathConfiguration {
        guard let url = Bundle.main.url(
            forResource: "path-configuration",
            withExtension: "json"
        ) else {
            return PathConfiguration()
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(PathConfiguration.self, from: data)
        } catch {
            print("[PathConfig] Failed to load local: \(error)")
            return PathConfiguration()
        }
    }

    private func fetchServerConfiguration() async -> PathConfiguration? {
        do {
            let (data, _) = try await URLSession.shared.data(from: serverURL)
            return try JSONDecoder().decode(PathConfiguration.self, from: data)
        } catch {
            print("[PathConfig] Failed to fetch server: \(error)")
            return nil
        }
    }
}
```

### 3. 쿠키 동기화 (세션 공유)

```swift
class CookieService {
    static let shared = CookieService()

    // 웹뷰 쿠키 → HTTPCookieStorage 동기화
    func syncCookiesFromWebView(_ webView: WKWebView) async {
        let cookies = await webView.configuration.websiteDataStore
            .httpCookieStore.allCookies()

        for cookie in cookies {
            HTTPCookieStorage.shared.setCookie(cookie)
        }
    }

    // Keychain에서 세션 복원 → 웹뷰에 주입
    func injectSessionCookie(into webView: WKWebView) async {
        guard let sessionToken = KeychainService.shared.getSessionToken() else {
            return
        }

        let cookie = HTTPCookie(properties: [
            .domain: "undrewai.com",
            .path: "/",
            .name: "_startup_community_session",
            .value: sessionToken,
            .secure: true,
            .expires: Date().addingTimeInterval(60 * 60 * 24 * 30)  // 30일
        ])!

        await webView.configuration.websiteDataStore
            .httpCookieStore.setCookie(cookie)
    }
}
```

### 4. Keychain 세션 저장

```swift
import Security

class KeychainService {
    static let shared = KeychainService()

    private let serviceIdentifier = "com.startupcommunity.session"

    func saveSessionToken(_ token: String) -> Bool {
        let data = token.data(using: .utf8)!

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecValueData as String: data
        ]

        // 기존 항목 삭제 후 저장
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)

        return status == errSecSuccess
    }

    func getSessionToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }

        return token
    }

    func deleteSessionToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier
        ]
        SecItemDelete(query as CFDictionary)
    }
}
```

### 5. Bridge Component 구현

```swift
import HotwireNative
import UIKit

// 네이티브 버튼 Bridge
class ButtonComponent: BridgeComponent {
    override class var name: String { "button" }

    override func onReceive(message: Message) {
        guard let event = message.event else { return }

        switch event {
        case "connect":
            configureButton(from: message)
        case "disconnect":
            removeButton()
        default:
            break
        }
    }

    private func configureButton(from message: Message) {
        guard let title = message.data["title"] as? String else { return }

        let button = UIBarButtonItem(
            title: title,
            style: .plain,
            target: self,
            action: #selector(buttonTapped)
        )

        // 아이콘 설정
        if let iconName = message.data["icon"] as? String,
           let icon = UIImage(systemName: iconName) {
            button.image = icon
        }

        delegate?.visibleViewController?.navigationItem.rightBarButtonItem = button
    }

    @objc private func buttonTapped() {
        reply(with: "tap")
    }
}

// Bridge 컴포넌트 등록
extension Navigator {
    func registerBridgeComponents() {
        HotwireNative.Bridge.register(components: [
            ButtonComponent.self,
            MenuComponent.self,
            FormComponent.self,
            AlertComponent.self
        ])
    }
}
```

### 6. Face ID/Touch ID 인증

```swift
import LocalAuthentication

class BiometricAuthService {
    static let shared = BiometricAuthService()

    func canUseBiometrics() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    func authenticate() async -> Result<Void, BiometricError> {
        let context = LAContext()
        context.localizedCancelTitle = "취소"

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "로그인하려면 Face ID를 사용하세요"
            )

            if success {
                return .success(())
            } else {
                return .failure(.failed)
            }
        } catch let error as LAError {
            switch error.code {
            case .userCancel:
                return .failure(.userCancelled)
            case .biometryLockout:
                return .failure(.lockout)
            default:
                return .failure(.failed)
            }
        } catch {
            return .failure(.failed)
        }
    }
}

enum BiometricError: Error {
    case failed
    case userCancelled
    case lockout
    case notAvailable
}
```

---

## ⚠️ 주의사항

### 금지 패턴

| 패턴 | 문제 | 대안 |
|------|------|------|
| 강제 언래핑 `!` | 런타임 크래시 | `guard let` 또는 `if let` |
| 메인 스레드에서 네트워크 | UI 블로킹 | `Task { }` 또는 `async/await` |
| UserDefaults에 세션 저장 | 보안 취약 | Keychain 사용 |
| 하드코딩된 URL | 환경별 관리 어려움 | Configuration 파일 사용 |

### WKWebView 주의사항

```swift
// ❌ 문제: 쿠키가 즉시 반영되지 않음
webView.load(URLRequest(url: url))

// ✅ 해결: 쿠키 주입 후 로드
Task {
    await CookieService.shared.injectSessionCookie(into: webView)
    webView.load(URLRequest(url: url))
}

// ❌ 문제: JavaScript 주입 실패
webView.evaluateJavaScript("...")

// ✅ 해결: 페이지 로드 완료 대기
func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    webView.evaluateJavaScript("...")
}
```

### 앱 수명주기 처리

```swift
// SceneDelegate에서 앱 상태 변경 처리
func sceneDidBecomeActive(_ scene: UIScene) {
    // 앱이 활성화되면 연결 상태 확인
    Navigator.shared.checkAndReconnect()
}

func sceneWillResignActive(_ scene: UIScene) {
    // 백그라운드 진입 전 쿠키 동기화
    Task {
        await CookieService.shared.syncCookiesFromWebView(webView)
    }
}
```

---

## ✅ 체크리스트

### 새 네이티브 화면 추가 시
- [ ] Path Configuration에 `context: native_screen` 규칙 추가
- [ ] ViewController 구현
- [ ] Navigator에서 화면 등록
- [ ] 딥링크 처리 확인

### Bridge Component 추가 시
- [ ] `BridgeComponent` 서브클래스 생성
- [ ] `name` 정적 프로퍼티 정의
- [ ] `onReceive(message:)` 구현
- [ ] Navigator에서 등록
- [ ] JavaScript 측 Stimulus 컨트롤러와 연동 확인

### 인증 기능 수정 시
- [ ] Keychain 토큰 저장/조회/삭제 확인
- [ ] 쿠키 동기화 동작 확인
- [ ] Face ID 권한 요청 (Info.plist)
- [ ] 로그아웃 시 Keychain 정리

### 앱 배포 전
- [ ] `PrivacyInfo.xcprivacy` 업데이트
- [ ] Info.plist 권한 설명 검토
- [ ] 테스트 계정으로 전체 플로우 확인
- [ ] 크래시 로그 모니터링 설정

---

## 📊 Xcode 프로젝트 구조

```
StartupCommunity.xcodeproj/
├── StartupCommunity/
│   ├── App/
│   │   ├── StartupCommunityApp.swift
│   │   ├── SceneDelegate.swift
│   │   └── AppDelegate.swift
│   │
│   ├── Navigator/
│   │   ├── Navigator.swift
│   │   ├── PathConfiguration.swift
│   │   └── TurboNavigationController.swift
│   │
│   ├── Bridge/
│   │   ├── ButtonComponent.swift
│   │   ├── MenuComponent.swift
│   │   └── ...
│   │
│   ├── Screens/
│   │   ├── AccountSettingsViewController.swift
│   │   └── ...
│   │
│   ├── Services/
│   │   ├── AuthService.swift
│   │   ├── KeychainService.swift
│   │   └── ...
│   │
│   └── Resources/
│       ├── Assets.xcassets/
│       ├── path-configuration.json
│       └── LaunchScreen.storyboard
│
├── StartupCommunityTests/
│   └── ...
│
├── StartupCommunityUITests/
│   └── ...
│
├── Info.plist
├── StartupCommunity.entitlements
└── PrivacyInfo.xcprivacy
```

---

## 🔗 연계 에이전트

| 에이전트 | 협력 포인트 |
|---------|------------|
| `hotwire-native-expert` | Path Configuration, 아키텍처 설계 |
| `bridge-expert` | JavaScript ↔ Swift Bridge 통신 |
| `mobile-auth-expert` | Keychain, Face ID, 세션 동기화 |
| `push-notification-expert` | APNs 토큰 등록, 알림 처리 |
| `app-store-expert` | TestFlight, App Store 배포 |

---

## 📚 참조 문서

### 공식 문서
- [turbo-ios GitHub](https://github.com/hotwired/turbo-ios)
- [HotwireNative iOS Documentation](https://native.hotwired.dev/ios/)
- [Apple WKWebView](https://developer.apple.com/documentation/webkit/wkwebview)

### 튜토리얼
- [Joe Masilotti - Turbo iOS Guide](https://masilotti.com/turbo-ios/)
- [WWDC - Meet Privacy Manifest](https://developer.apple.com/videos/play/wwdc2023/10060/)

### 프로젝트 내부
- [hotwire-native-expert](./hotwire-native-expert.md)
- [bridge-expert](../feature/bridge-expert.md)
