---
name: android-expert
description: Android 앱 개발 전문가 - Kotlin, Fragment Navigation, WebView, Gradle 설정
triggers:
  - Android
  - Kotlin
  - Gradle
  - turbo-android
  - Fragment
  - WebView
  - Play Store
related_agents:
  - hotwire-native-expert
  - bridge-expert
  - mobile-auth-expert
  - play-store-expert
related_skills:
  - test-gen
---

# Android Expert (Android 앱 전문가)

## 🎯 역할

Hotwire Native 기반 Android 앱의 모든 측면을 담당합니다:
- Kotlin Navigator/Fragment 구현
- WebView 커스터마이징
- Bridge Components (Kotlin 측)
- 네이티브 화면 통합
- 생체 인증 (지문, 얼굴)
- EncryptedSharedPreferences 세션 관리
- Gradle 프로젝트 구성

---

## 📁 담당 파일

### Navigator (핵심)
```
android/app/src/main/kotlin/com/startupcommunity/
├── navigator/
│   ├── Navigator.kt                 # 메인 Navigator
│   ├── PathConfiguration.kt         # Path Configuration 로더
│   ├── TurboWebFragment.kt          # 웹뷰 Fragment
│   └── TurboModalFragment.kt        # 모달 Fragment
```

### Activity & Application
```
android/app/src/main/kotlin/com/startupcommunity/
├── MainActivity.kt                  # 메인 Activity
├── StartupCommunityApp.kt           # Application 클래스
└── SplashActivity.kt                # 스플래시 화면
```

### Bridge Components
```
android/app/src/main/kotlin/com/startupcommunity/
├── bridge/
│   ├── BridgeComponent.kt           # 기본 Bridge 컴포넌트
│   ├── ButtonComponent.kt           # 네이티브 버튼
│   ├── MenuComponent.kt             # 네이티브 메뉴
│   ├── FormComponent.kt             # 폼 연동
│   ├── OverflowMenuComponent.kt     # 더보기 메뉴
│   └── AlertComponent.kt            # 네이티브 다이얼로그
```

### Native Screens (Fragments)
```
android/app/src/main/kotlin/com/startupcommunity/
├── screens/
│   ├── AccountSettingsFragment.kt   # 계정 설정 (네이티브)
│   ├── NotificationSettingsFragment.kt  # 알림 설정
│   └── BiometricAuthFragment.kt     # 생체 인증
```

### Services
```
android/app/src/main/kotlin/com/startupcommunity/
├── services/
│   ├── AuthService.kt               # 인증 서비스
│   ├── SecureStorageService.kt      # 암호화 저장소
│   ├── PushNotificationService.kt   # FCM 서비스
│   └── CookieService.kt             # 웹-앱 쿠키 동기화
```

### Resources
```
android/app/src/main/
├── res/
│   ├── raw/
│   │   └── path_configuration.json  # 로컬 Path Configuration
│   ├── layout/
│   │   ├── activity_main.xml
│   │   └── fragment_web.xml
│   ├── navigation/
│   │   └── nav_graph.xml            # Navigation Graph
│   └── values/
│       ├── strings.xml
│       └── themes.xml
│
├── AndroidManifest.xml
```

### Gradle
```
android/
├── build.gradle.kts                 # 프로젝트 레벨
├── app/
│   └── build.gradle.kts             # 앱 레벨
├── gradle.properties
└── settings.gradle.kts
```

---

## 🔧 핵심 패턴

### 1. Navigator 기본 구조

```kotlin
package com.startupcommunity.navigator

import android.content.Context
import dev.hotwire.turbo.config.TurboPathConfiguration
import dev.hotwire.turbo.session.TurboSession

class Navigator private constructor(context: Context) {

    private val turboSession: TurboSession
    private val pathConfiguration: TurboPathConfiguration

    companion object {
        @Volatile
        private var INSTANCE: Navigator? = null

        fun getInstance(context: Context): Navigator {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: Navigator(context.applicationContext).also {
                    INSTANCE = it
                }
            }
        }
    }

    init {
        // WebView 설정
        val webView = createWebView(context)

        // Path Configuration 로드
        pathConfiguration = loadPathConfiguration(context)

        // Turbo Session 초기화
        turboSession = TurboSession.create(
            context = context,
            webView = webView,
            pathConfiguration = pathConfiguration
        )
    }

    private fun loadPathConfiguration(context: Context): TurboPathConfiguration {
        val serverUrl = "https://undrewai.com/hotwire_native/path_configuration"
        val localPath = "res/raw/path_configuration.json"

        return TurboPathConfiguration.load(
            context = context,
            location = TurboPathConfiguration.Location(
                assetFilePath = localPath,
                remoteFileUrl = serverUrl
            )
        )
    }

    fun visit(url: String) {
        val properties = pathConfiguration.properties(url)
        val presentation = properties.presentation

        when (presentation) {
            "modal" -> navigateToModal(url)
            "replace" -> replaceCurrentFragment(url)
            else -> navigatePush(url)
        }
    }
}
```

### 2. TurboWebFragment 구현

```kotlin
package com.startupcommunity.navigator

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import dev.hotwire.turbo.fragments.TurboWebFragment
import dev.hotwire.turbo.nav.TurboNavDestination

class MainWebFragment : TurboWebFragment(), TurboNavDestination {

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.fragment_web, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        // 쿠키 동기화
        CookieService.getInstance(requireContext())
            .injectSessionCookie(webView)
    }

    // 페이지 로드 완료 콜백
    override fun onVisitCompleted(location: String, completedOffline: Boolean) {
        super.onVisitCompleted(location, completedOffline)

        // Pull-to-refresh 활성화 여부 확인
        val properties = pathConfiguration.properties(location)
        swipeRefreshLayout?.isEnabled = properties.pullToRefreshEnabled
    }

    // 에러 처리
    override fun onVisitErrorReceived(location: String, errorCode: Int) {
        when (errorCode) {
            401 -> navigateToLogin()
            404 -> showNotFoundError()
            else -> showGenericError()
        }
    }
}
```

### 3. 쿠키 동기화 (세션 공유)

```kotlin
package com.startupcommunity.services

import android.content.Context
import android.webkit.CookieManager
import android.webkit.WebView

class CookieService private constructor(private val context: Context) {

    private val cookieManager = CookieManager.getInstance()

    companion object {
        @Volatile
        private var INSTANCE: CookieService? = null

        fun getInstance(context: Context): CookieService {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: CookieService(context.applicationContext).also {
                    INSTANCE = it
                }
            }
        }
    }

    // 세션 쿠키 주입
    fun injectSessionCookie(webView: WebView) {
        val sessionToken = SecureStorageService.getInstance(context)
            .getSessionToken() ?: return

        val cookie = "_startup_community_session=$sessionToken; " +
                     "Path=/; " +
                     "Secure; " +
                     "HttpOnly; " +
                     "SameSite=Lax"

        cookieManager.setCookie("https://undrewai.com", cookie)
        cookieManager.flush()
    }

    // 웹뷰 쿠키 추출
    fun extractSessionCookie(): String? {
        val cookies = cookieManager.getCookie("https://undrewai.com")
        return cookies?.split(";")
            ?.find { it.trim().startsWith("_startup_community_session=") }
            ?.substringAfter("=")
            ?.trim()
    }

    // 쿠키 저장
    fun saveSessionFromWebView() {
        val sessionToken = extractSessionCookie() ?: return
        SecureStorageService.getInstance(context)
            .saveSessionToken(sessionToken)
    }

    // 쿠키 전체 삭제 (로그아웃 시)
    fun clearAllCookies() {
        cookieManager.removeAllCookies(null)
        cookieManager.flush()
    }
}
```

### 4. 암호화 저장소 (EncryptedSharedPreferences)

```kotlin
package com.startupcommunity.services

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey

class SecureStorageService private constructor(context: Context) {

    private val encryptedPrefs: SharedPreferences

    companion object {
        private const val PREFS_NAME = "secure_prefs"
        private const val KEY_SESSION_TOKEN = "session_token"

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

        encryptedPrefs = EncryptedSharedPreferences.create(
            context,
            PREFS_NAME,
            masterKey,
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
        )
    }

    fun saveSessionToken(token: String) {
        encryptedPrefs.edit()
            .putString(KEY_SESSION_TOKEN, token)
            .apply()
    }

    fun getSessionToken(): String? {
        return encryptedPrefs.getString(KEY_SESSION_TOKEN, null)
    }

    fun clearSessionToken() {
        encryptedPrefs.edit()
            .remove(KEY_SESSION_TOKEN)
            .apply()
    }
}
```

### 5. Bridge Component 구현

```kotlin
package com.startupcommunity.bridge

import android.content.Context
import dev.hotwire.turbo.bridge.BridgeComponent
import dev.hotwire.turbo.bridge.Message

// 네이티브 버튼 Bridge
class ButtonComponent(
    name: String,
    private val delegate: BridgeDelegate
) : BridgeComponent<BridgeDelegate>(name, delegate) {

    override fun onReceive(message: Message) {
        when (message.event) {
            "connect" -> configureButton(message)
            "disconnect" -> removeButton()
        }
    }

    private fun configureButton(message: Message) {
        val title = message.data?.getString("title") ?: return
        val icon = message.data?.getString("icon")

        delegate.activity?.runOnUiThread {
            val toolbar = delegate.activity?.supportActionBar
            toolbar?.title = title

            // 메뉴 아이템 추가
            delegate.fragment?.setHasOptionsMenu(true)
        }
    }

    private fun removeButton() {
        delegate.fragment?.setHasOptionsMenu(false)
    }

    fun onButtonTapped() {
        replyTo("tap")
    }
}

// Bridge 컴포넌트 등록
object BridgeComponentFactory {
    fun create(
        name: String,
        delegate: BridgeDelegate
    ): BridgeComponent<*>? {
        return when (name) {
            "button" -> ButtonComponent(name, delegate)
            "menu" -> MenuComponent(name, delegate)
            "form" -> FormComponent(name, delegate)
            "alert" -> AlertComponent(name, delegate)
            else -> null
        }
    }
}
```

### 6. 생체 인증 (BiometricPrompt)

```kotlin
package com.startupcommunity.services

import android.content.Context
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity

class BiometricAuthService(private val activity: FragmentActivity) {

    fun canUseBiometrics(): Boolean {
        val biometricManager = BiometricManager.from(activity)
        return when (biometricManager.canAuthenticate(
            BiometricManager.Authenticators.BIOMETRIC_STRONG
        )) {
            BiometricManager.BIOMETRIC_SUCCESS -> true
            else -> false
        }
    }

    fun authenticate(
        onSuccess: () -> Unit,
        onError: (Int, String) -> Unit
    ) {
        val executor = ContextCompat.getMainExecutor(activity)

        val callback = object : BiometricPrompt.AuthenticationCallback() {
            override fun onAuthenticationSucceeded(
                result: BiometricPrompt.AuthenticationResult
            ) {
                super.onAuthenticationSucceeded(result)
                onSuccess()
            }

            override fun onAuthenticationError(
                errorCode: Int,
                errString: CharSequence
            ) {
                super.onAuthenticationError(errorCode, errString)
                onError(errorCode, errString.toString())
            }

            override fun onAuthenticationFailed() {
                super.onAuthenticationFailed()
                // 인증 실패 (재시도 가능)
            }
        }

        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle("로그인")
            .setSubtitle("생체 인증으로 로그인합니다")
            .setNegativeButtonText("취소")
            .setAllowedAuthenticators(
                BiometricManager.Authenticators.BIOMETRIC_STRONG
            )
            .build()

        val biometricPrompt = BiometricPrompt(activity, executor, callback)
        biometricPrompt.authenticate(promptInfo)
    }
}
```

---

## ⚠️ 주의사항

### 금지 패턴

| 패턴 | 문제 | 대안 |
|------|------|------|
| `!!` (강제 언래핑) | NullPointerException | `?.let { }` 또는 `?: return` |
| 메인 스레드 네트워크 | ANR | `withContext(Dispatchers.IO)` |
| SharedPreferences에 세션 | 보안 취약 | EncryptedSharedPreferences |
| 하드코딩된 URL | 환경 관리 어려움 | BuildConfig 또는 리소스 |

### WebView 주의사항

```kotlin
// ❌ 문제: JavaScript 비활성화 상태
webView.settings.javaScriptEnabled = false

// ✅ 해결: Hotwire에 필수
webView.settings.apply {
    javaScriptEnabled = true
    domStorageEnabled = true
    databaseEnabled = true
}

// ❌ 문제: Mixed Content 차단
// ✅ 해결: HTTPS만 사용 (보안을 위해 HTTP 허용하지 않음)

// ❌ 문제: 쿠키가 WebView에 반영 안 됨
webView.loadUrl(url)

// ✅ 해결: 쿠키 설정 후 로드
CookieManager.getInstance().setAcceptThirdPartyCookies(webView, true)
cookieService.injectSessionCookie(webView)
webView.loadUrl(url)
```

### ProGuard/R8 규칙

```proguard
# build.gradle.kts의 proguard-rules.pro

# Hotwire Native
-keep class dev.hotwire.turbo.** { *; }
-keep interface dev.hotwire.turbo.** { *; }

# Bridge Components
-keep class com.startupcommunity.bridge.** { *; }

# Kotlin Serialization (Path Configuration 파싱)
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt

# 앱 클래스
-keep class com.startupcommunity.** { *; }
```

---

## ✅ 체크리스트

### 새 네이티브 화면 추가 시
- [ ] Fragment 클래스 생성
- [ ] Navigation Graph에 destination 추가
- [ ] Path Configuration에 `context: native_screen` 규칙 추가
- [ ] Navigator에서 화면 라우팅 구현

### Bridge Component 추가 시
- [ ] BridgeComponent 서브클래스 생성
- [ ] BridgeComponentFactory에 등록
- [ ] JavaScript 측 Stimulus 컨트롤러와 연동 확인
- [ ] 양방향 메시지 테스트

### 인증 기능 수정 시
- [ ] EncryptedSharedPreferences 사용 확인
- [ ] 쿠키 동기화 동작 확인
- [ ] 생체 인증 권한 요청 (AndroidManifest)
- [ ] 로그아웃 시 토큰/쿠키 정리

### 앱 배포 전
- [ ] ProGuard 난독화 테스트
- [ ] 릴리스 빌드 서명
- [ ] 64비트 ABI 포함 확인
- [ ] 최소 SDK 버전 검토

---

## 📊 Gradle 의존성

```kotlin
// app/build.gradle.kts

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.serialization")
}

android {
    namespace = "com.startupcommunity"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.startupcommunity"
        minSdk = 24
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

dependencies {
    // Hotwire Native (Turbo)
    implementation("dev.hotwire:turbo:7.1.0")

    // AndroidX
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("androidx.fragment:fragment-ktx:1.6.2")
    implementation("androidx.navigation:navigation-fragment-ktx:2.7.6")
    implementation("androidx.navigation:navigation-ui-ktx:2.7.6")

    // Security (암호화 저장소)
    implementation("androidx.security:security-crypto:1.1.0-alpha06")

    // Biometric (생체 인증)
    implementation("androidx.biometric:biometric:1.1.0")

    // Firebase (푸시 알림)
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    implementation("com.google.firebase:firebase-messaging-ktx")

    // Serialization (JSON 파싱)
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.2")

    // Material Design
    implementation("com.google.android.material:material:1.11.0")
}
```

---

## 🔗 연계 에이전트

| 에이전트 | 협력 포인트 |
|---------|------------|
| `hotwire-native-expert` | Path Configuration, 아키텍처 설계 |
| `bridge-expert` | JavaScript ↔ Kotlin Bridge 통신 |
| `mobile-auth-expert` | EncryptedSharedPreferences, 생체 인증 |
| `push-notification-expert` | FCM 토큰 등록, 알림 처리 |
| `play-store-expert` | Play Console, AAB 배포 |

---

## 📚 참조 문서

### 공식 문서
- [turbo-android GitHub](https://github.com/hotwired/turbo-android)
- [HotwireNative Android Documentation](https://native.hotwired.dev/android/)
- [Android WebView](https://developer.android.com/develop/ui/views/layout/webapps/webview)

### 튜토리얼
- [Joe Masilotti - Turbo Android Guide](https://masilotti.com/turbo-android/)
- [Android Security Best Practices](https://developer.android.com/topic/security/best-practices)

### 프로젝트 내부
- [hotwire-native-expert](./hotwire-native-expert.md)
- [bridge-expert](../feature/bridge-expert.md)
