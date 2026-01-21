---
name: mobile-auth-expert
description: 모바일 인증 전문가 - 세션 동기화, 생체 인증, OAuth In-App Browser, Keychain/Keystore
triggers:
  - 앱 인증
  - 앱 로그인
  - Face ID
  - Touch ID
  - 생체 인증
  - Keychain
  - Keystore
  - 세션 동기화
  - 앱 세션
related_agents:
  - auth-expert
  - ios-expert
  - android-expert
  - hotwire-native-expert
related_skills:
  - rails-dev
---

# Mobile Auth Expert (모바일 인증 전문가)

## 🎯 역할

모바일 앱의 인증 및 세션 관리를 담당합니다:
- 웹-앱 세션/쿠키 동기화
- 생체 인증 (Face ID, Touch ID, 지문)
- OAuth In-App Browser 처리
- Keychain (iOS) / EncryptedSharedPreferences (Android) 관리
- 앱 백그라운드 시 세션 유지
- 자동 로그인/로그아웃

---

## 📁 담당 파일

### Rails Server
```
app/controllers/
├── api/
│   └── v1/
│       └── sessions_controller.rb      # 앱 세션 API
│
├── concerns/
│   ├── hotwire_native_authentication.rb # 앱 인증 헬퍼
│   └── cookie_session_sync.rb          # 쿠키 동기화

config/initializers/
├── session_store.rb                    # 세션 설정
└── cors.rb                             # CORS (앱 요청 허용)
```

### iOS
```
ios/StartupCommunity/
├── Services/
│   ├── AuthService.swift               # 인증 서비스
│   ├── KeychainService.swift           # Keychain 관리
│   ├── BiometricAuthService.swift      # Face ID/Touch ID
│   └── OAuthService.swift              # OAuth 처리
│
├── Screens/
│   ├── LoginViewController.swift       # 로그인 화면 (선택적)
│   └── BiometricPromptViewController.swift
```

### Android
```
android/app/src/main/kotlin/com/startupcommunity/
├── services/
│   ├── AuthService.kt                  # 인증 서비스
│   ├── SecureStorageService.kt         # 암호화 저장소
│   ├── BiometricAuthService.kt         # 생체 인증
│   └── OAuthService.kt                 # OAuth 처리
│
├── screens/
│   ├── LoginFragment.kt                # 로그인 화면 (선택적)
│   └── BiometricPromptFragment.kt
```

---

## 🔧 핵심 패턴

### 1. 세션 동기화 아키텍처

```
┌─────────────────────────────────────────────────────────────┐
│                     Mobile App                              │
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                  Secure Storage                          ││
│  │   Keychain (iOS) / EncryptedSharedPreferences (Android) ││
│  │                                                          ││
│  │   session_token: "abc123..."                            ││
│  │   refresh_token: "xyz789..."                            ││
│  │   user_id: 42                                           ││
│  └─────────────────────────────────────────────────────────┘│
│                           │                                 │
│                           ▼                                 │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                     WebView                              ││
│  │   Cookie: _startup_community_session=abc123...          ││
│  │                                                          ││
│  │   ← 저장소에서 쿠키 주입 (앱 시작 시)                    ││
│  │   → 쿠키 변경 감지 시 저장소 업데이트                    ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     Rails Server                            │
│                                                             │
│  Session Cookie 기반 인증 (기존 웹과 동일)                  │
│                                                             │
│  + 앱 세션 API (선택적)                                     │
│    POST /api/v1/sessions/sync                               │
│    POST /api/v1/sessions/refresh                            │
└─────────────────────────────────────────────────────────────┘
```

### 2. iOS Keychain 세션 관리

```swift
// ios/Services/KeychainService.swift
import Security

class KeychainService {
    static let shared = KeychainService()

    private let service = "com.startupcommunity"

    // 세션 토큰 저장
    func saveSession(_ session: AppSession) throws {
        let data = try JSONEncoder().encode(session)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "session",
            kSecValueData as String: data
        ]

        // 기존 항목 삭제 후 저장
        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    // 세션 조회
    func getSession() -> AppSession? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "session",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let session = try? JSONDecoder().decode(AppSession.self, from: data) else {
            return nil
        }

        return session
    }

    // 세션 삭제 (로그아웃)
    func clearSession() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "session"
        ]
        SecItemDelete(query as CFDictionary)
    }
}

struct AppSession: Codable {
    let sessionToken: String
    let userId: Int
    let expiresAt: Date
}
```

### 3. Android EncryptedSharedPreferences

```kotlin
// android/services/SecureStorageService.kt
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey

class SecureStorageService private constructor(context: Context) {

    private val prefs: SharedPreferences

    companion object {
        private const val PREFS_NAME = "secure_session"
        private const val KEY_SESSION_TOKEN = "session_token"
        private const val KEY_USER_ID = "user_id"
        private const val KEY_EXPIRES_AT = "expires_at"

        @Volatile
        private var INSTANCE: SecureStorageService? = null

        fun getInstance(context: Context): SecureStorageService {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: SecureStorageService(context.applicationContext).also {
                    INSTANCE = it
                }
            }
        }
    }

    init {
        val masterKey = MasterKey.Builder(context)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build()

        prefs = EncryptedSharedPreferences.create(
            context,
            PREFS_NAME,
            masterKey,
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
        )
    }

    fun saveSession(session: AppSession) {
        prefs.edit()
            .putString(KEY_SESSION_TOKEN, session.sessionToken)
            .putInt(KEY_USER_ID, session.userId)
            .putLong(KEY_EXPIRES_AT, session.expiresAt)
            .apply()
    }

    fun getSession(): AppSession? {
        val token = prefs.getString(KEY_SESSION_TOKEN, null) ?: return null
        val userId = prefs.getInt(KEY_USER_ID, -1)
        val expiresAt = prefs.getLong(KEY_EXPIRES_AT, 0)

        if (userId == -1 || expiresAt < System.currentTimeMillis()) {
            clearSession()
            return null
        }

        return AppSession(token, userId, expiresAt)
    }

    fun clearSession() {
        prefs.edit().clear().apply()
    }
}

data class AppSession(
    val sessionToken: String,
    val userId: Int,
    val expiresAt: Long
)
```

### 4. 생체 인증 통합 (iOS)

```swift
// ios/Services/BiometricAuthService.swift
import LocalAuthentication

class BiometricAuthService {
    static let shared = BiometricAuthService()

    enum BiometricType {
        case none, touchID, faceID
    }

    var biometricType: BiometricType {
        let context = LAContext()
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) else {
            return .none
        }

        switch context.biometryType {
        case .touchID: return .touchID
        case .faceID: return .faceID
        default: return .none
        }
    }

    func authenticate() async -> Result<Void, BiometricError> {
        let context = LAContext()

        guard biometricType != .none else {
            return .failure(.notAvailable)
        }

        let reason = biometricType == .faceID
            ? "Face ID로 로그인합니다"
            : "Touch ID로 로그인합니다"

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            return success ? .success(()) : .failure(.failed)
        } catch {
            return .failure(.failed)
        }
    }

    // 앱 시작 시 생체 인증으로 자동 로그인
    func authenticateAndRestoreSession() async -> AppSession? {
        // 1. 저장된 세션 확인
        guard let session = KeychainService.shared.getSession() else {
            return nil
        }

        // 2. 세션 만료 확인
        guard session.expiresAt > Date() else {
            KeychainService.shared.clearSession()
            return nil
        }

        // 3. 생체 인증
        let result = await authenticate()
        switch result {
        case .success:
            return session
        case .failure:
            return nil
        }
    }
}
```

### 5. OAuth In-App Browser (iOS)

```swift
// ios/Services/OAuthService.swift
import AuthenticationServices

class OAuthService: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = OAuthService()

    func signInWithGoogle() async throws -> OAuthResult {
        let authURL = URL(string: "https://undrewai.com/auth/google_oauth2")!
        let callbackScheme = "startupcommunity"

        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: callbackScheme
            ) { callbackURL, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let url = callbackURL,
                      let token = self.extractToken(from: url) else {
                    continuation.resume(throwing: OAuthError.invalidCallback)
                    return
                }

                continuation.resume(returning: OAuthResult(token: token))
            }

            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false  // 쿠키 유지
            session.start()
        }
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return UIApplication.shared.windows.first { $0.isKeyWindow } ?? UIWindow()
    }

    private func extractToken(from url: URL) -> String? {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        return components?.queryItems?.first { $0.name == "token" }?.value
    }
}
```

### 6. Rails Server 세션 동기화 API

```ruby
# app/controllers/api/v1/sessions_controller.rb
module Api
  module V1
    class SessionsController < ApplicationController
      skip_before_action :verify_authenticity_token, only: [:sync, :refresh]
      before_action :authenticate_by_token!, only: [:sync, :refresh]

      # 앱 세션 동기화
      def sync
        render json: {
          session_token: current_session_token,
          user_id: current_user.id,
          expires_at: 30.days.from_now.iso8601
        }
      end

      # 세션 갱신
      def refresh
        if session_expired?
          head :unauthorized
        else
          extend_session
          render json: {
            session_token: current_session_token,
            expires_at: 30.days.from_now.iso8601
          }
        end
      end

      private

      def authenticate_by_token!
        token = request.headers["Authorization"]&.gsub(/^Bearer /, "")
        @current_user = User.find_by_session_token(token)

        head :unauthorized unless @current_user
      end
    end
  end
end
```

### 7. 쿠키 → WebView 주입 패턴

```swift
// iOS: 앱 시작 시 세션 쿠키 주입
class Navigator {
    func injectSessionCookie() async {
        guard let session = KeychainService.shared.getSession() else { return }

        let cookie = HTTPCookie(properties: [
            .domain: "undrewai.com",
            .path: "/",
            .name: "_startup_community_session",
            .value: session.sessionToken,
            .secure: true,
            .expires: session.expiresAt
        ])!

        await webView.configuration.websiteDataStore
            .httpCookieStore.setCookie(cookie)
    }
}

// Android: 앱 시작 시 세션 쿠키 주입
class Navigator(context: Context) {
    fun injectSessionCookie() {
        val session = SecureStorageService.getInstance(context).getSession() ?: return

        val cookie = "${session.sessionToken}; " +
                     "Path=/; " +
                     "Secure; " +
                     "HttpOnly; " +
                     "Domain=undrewai.com"

        CookieManager.getInstance().setCookie("https://undrewai.com", cookie)
        CookieManager.getInstance().flush()
    }
}
```

---

## ⚠️ 주의사항

### 금지 패턴

| 패턴 | 문제 | 대안 |
|------|------|------|
| UserDefaults에 토큰 저장 (iOS) | 보안 취약 | Keychain 사용 |
| SharedPreferences에 토큰 저장 (Android) | 보안 취약 | EncryptedSharedPreferences |
| 토큰을 URL 파라미터로 전송 | 로그 노출 | Authorization 헤더 |
| 만료된 세션 자동 삭제 안 함 | 보안 위험 | 만료 시 즉시 삭제 |

### OAuth 주의사항

```swift
// ❌ 문제: 외부 브라우저로 OAuth (세션 손실)
UIApplication.shared.open(authURL)

// ✅ 해결: In-App Browser (ASWebAuthenticationSession)
let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: scheme)
session.prefersEphemeralWebBrowserSession = false  // 쿠키 유지!
```

### 세션 갱신 타이밍

```
앱 시작 시:
1. 저장된 세션 확인
2. 만료 임박 시 (< 7일) → refresh API 호출
3. 생체 인증 (필요 시)
4. WebView에 쿠키 주입

앱 포그라운드 복귀 시:
1. 세션 유효성 확인
2. 필요 시 갱신
3. WebView 쿠키 동기화
```

---

## ✅ 체크리스트

### 초기 세션 설정 시
- [ ] Keychain/EncryptedSharedPreferences 사용
- [ ] 세션 만료 시간 설정
- [ ] WebView 쿠키 주입
- [ ] HTTP-only, Secure 플래그

### 생체 인증 구현 시
- [ ] 생체 인증 가능 여부 확인
- [ ] Face ID/Touch ID 권한 요청 (Info.plist)
- [ ] 생체 인증 실패 시 폴백 (비밀번호)
- [ ] 로그아웃 시 인증 요구 설정 해제

### OAuth 구현 시
- [ ] In-App Browser 사용 (ASWebAuthenticationSession / Custom Tabs)
- [ ] 콜백 URL 스킴 등록
- [ ] 토큰 추출 및 저장
- [ ] 쿠키 동기화

### 로그아웃 구현 시
- [ ] Keychain/Keystore 세션 삭제
- [ ] WebView 쿠키 삭제
- [ ] 서버 세션 무효화 API 호출
- [ ] 로그인 화면으로 이동

---

## 🔗 연계 에이전트

| 에이전트 | 협력 포인트 |
|---------|------------|
| `auth-expert` | 웹 OAuth, 세션 관리 |
| `ios-expert` | Keychain, ASWebAuthenticationSession |
| `android-expert` | EncryptedSharedPreferences, BiometricPrompt |
| `hotwire-native-expert` | 앱 감지, 조건부 렌더링 |

---

## 📚 참조 문서

### 공식 문서
- [iOS Keychain Services](https://developer.apple.com/documentation/security/keychain_services)
- [Android EncryptedSharedPreferences](https://developer.android.com/reference/androidx/security/crypto/EncryptedSharedPreferences)
- [ASWebAuthenticationSession](https://developer.apple.com/documentation/authenticationservices/aswebauthenticationsession)

### 프로젝트 내부
- [auth-expert](../../domain/auth-expert.md)
- [ios-expert](../core/ios-expert.md)
- [android-expert](../core/android-expert.md)
