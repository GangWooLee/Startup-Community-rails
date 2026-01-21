---
name: play-store-expert
description: Play Store 배포 전문가 - Google Play Console, 내부 테스트, AAB, Fastlane
triggers:
  - Play Store
  - Google Play
  - Android 배포
  - AAB
  - 앱 번들
  - Play Console
  - Fastlane Android
related_agents:
  - android-expert
  - hotwire-native-expert
related_skills:
  - rails-dev
---

# Play Store Expert (Android 배포 전문가)

## 🎯 역할

Android 앱의 Google Play Store 배포를 담당합니다:
- 내부/비공개/공개 테스트 트랙
- Play Store 제출 및 심사
- Fastlane 자동화
- 서명 키 관리 (Play App Signing)
- Data Safety 섹션
- 앱 스크린샷 및 메타데이터

---

## 📁 담당 파일

### Fastlane
```
android/fastlane/
├── Fastfile                      # 빌드/배포 레인
├── Appfile                       # 패키지 이름, JSON 키
│
├── metadata/android/
│   ├── ko-KR/
│   │   ├── title.txt             # 앱 이름
│   │   ├── short_description.txt # 짧은 설명 (80자)
│   │   ├── full_description.txt  # 전체 설명
│   │   └── changelogs/
│   │       └── default.txt       # 릴리스 노트
│   └── en-US/
│       └── ...
│
├── screenshots/
│   ├── phoneScreenshots/         # 휴대폰
│   ├── sevenInchScreenshots/     # 7" 태블릿
│   └── tenInchScreenshots/       # 10" 태블릿
│
└── .env.default                  # 환경 변수
```

### Gradle
```
android/
├── build.gradle.kts              # 프로젝트 레벨
├── app/
│   ├── build.gradle.kts          # 앱 레벨 (버전, 서명)
│   └── proguard-rules.pro        # 난독화 규칙
│
├── gradle.properties             # 빌드 설정
└── keystore/
    ├── release.keystore          # 릴리스 키 (로컬 백업)
    └── keystore.properties       # 키 비밀번호 (gitignore)
```

---

## 🔧 핵심 패턴

### 1. Fastlane 설정

```ruby
# android/fastlane/Fastfile

default_platform(:android)

platform :android do
  # 유닛 테스트
  desc "Run unit tests"
  lane :test do
    gradle(task: "test")
  end

  # 내부 테스트 트랙
  desc "Deploy to Internal Testing"
  lane :internal do
    gradle(
      task: "bundle",
      build_type: "Release"
    )

    upload_to_play_store(
      track: "internal",
      aab: "app/build/outputs/bundle/release/app-release.aab",
      skip_upload_metadata: true,
      skip_upload_images: true,
      skip_upload_screenshots: true
    )

    slack(
      message: "New internal test build uploaded! 🤖",
      channel: "#android-releases"
    )
  end

  # 비공개 테스트 (베타)
  desc "Deploy to Closed Testing (Beta)"
  lane :beta do
    gradle(
      task: "bundle",
      build_type: "Release"
    )

    upload_to_play_store(
      track: "beta",
      aab: "app/build/outputs/bundle/release/app-release.aab"
    )
  end

  # 프로덕션
  desc "Deploy to Production"
  lane :release do
    gradle(
      task: "bundle",
      build_type: "Release"
    )

    upload_to_play_store(
      track: "production",
      aab: "app/build/outputs/bundle/release/app-release.aab",
      rollout: "0.1"  # 10% 단계적 출시
    )
  end

  # 단계적 출시 확대
  desc "Increase rollout percentage"
  lane :promote do |options|
    percentage = options[:percentage] || 1.0

    upload_to_play_store(
      track: "production",
      rollout: percentage.to_s,
      skip_upload_aab: true,
      skip_upload_metadata: true,
      skip_upload_images: true,
      skip_upload_screenshots: true
    )
  end
end
```

### 2. Gradle 빌드 설정

```kotlin
// android/app/build.gradle.kts

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
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

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    signingConfigs {
        create("release") {
            // 로컬 개발용 (Play App Signing 사용 시 불필요)
            if (file("../keystore/keystore.properties").exists()) {
                val keystoreProperties = java.util.Properties().apply {
                    load(file("../keystore/keystore.properties").inputStream())
                }
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("release")
        }
    }

    bundle {
        language {
            // 모든 언어 리소스 포함
            enableSplit = false
        }
    }
}
```

### 3. Play App Signing

```markdown
## Play App Signing 설정

### 장점
- Google이 서명 키 안전하게 관리
- 키 분실 위험 없음
- App Bundle 최적화

### 설정 방법
1. Play Console > 앱 선택 > 설정 > 앱 무결성
2. "Play App Signing 사용" 선택
3. 업로드 키 생성 및 등록

### 업로드 키 생성
```bash
keytool -genkeypair -v \
  -keystore upload-keystore.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload-key
```

### SHA-256 지문 확인 (딥링크용)
Play Console > 앱 무결성 > 앱 서명 키 인증서
```

### 4. Data Safety 섹션

```markdown
## Data Safety 체크리스트

### 수집하는 데이터
| 데이터 유형 | 수집 | 공유 | 용도 |
|------------|------|------|------|
| 이메일 주소 | ✅ | ❌ | 계정 관리, 로그인 |
| 이름 | ✅ | ✅ (커뮤니티) | 프로필 표시 |
| 프로필 사진 | ✅ | ✅ (커뮤니티) | 프로필 표시 |
| 앱 활동 | ✅ | ❌ | 분석, 개선 |
| 기기 ID | ✅ | ❌ | 푸시 알림 |

### 보안 관행
- [x] 데이터 전송 시 암호화 (HTTPS)
- [x] 데이터 삭제 요청 가능
- [ ] 광고 기반 추적 없음

### 개인정보 처리방침 URL
https://undrewai.com/privacy
```

### 5. 버전 관리

```kotlin
// android/app/build.gradle.kts

android {
    defaultConfig {
        // 자동 버전 코드 (GitHub Actions 등에서)
        versionCode = (System.getenv("VERSION_CODE") ?: "1").toInt()

        // 시맨틱 버전
        versionName = "1.0.0"
    }
}
```

```ruby
# Fastlane에서 버전 코드 자동 증가
lane :increment_version do
  # Play Store에서 현재 버전 코드 가져오기
  current_version = google_play_track_version_codes(
    track: "internal"
  ).max || 0

  # build.gradle 업데이트
  increment_version_code(
    gradle_file_path: "app/build.gradle.kts",
    version_code: current_version + 1
  )
end
```

### 6. 스크린샷 요구사항

```markdown
## 스크린샷 요구사항

### 필수 (휴대폰)
- 최소 2장, 최대 8장
- 크기: 320-3840px (16:9 또는 9:16)
- 형식: JPEG, PNG (24비트, 투명도 없음)

### 권장 해상도
| 디바이스 | 해상도 |
|----------|--------|
| Phone | 1080 x 1920 (9:16) |
| 7" Tablet | 1200 x 1920 |
| 10" Tablet | 1600 x 2560 |

### Fastlane Screengrab
```bash
# 스크린샷 자동 캡처
fastlane screengrab

# 설정 파일
android/fastlane/Screengrabfile
```
```

### 7. 메타데이터

```text
# android/fastlane/metadata/android/ko-KR/title.txt
스타트업 커뮤니티

# android/fastlane/metadata/android/ko-KR/short_description.txt
창업자들의 네트워킹 공간 - 아이디어 공유, 채팅, AI 분석

# android/fastlane/metadata/android/ko-KR/full_description.txt
스타트업 커뮤니티는 초기 창업자들을 위한 네트워킹 플랫폼입니다.

주요 기능:
• 커뮤니티 게시판 - 아이디어 공유, 질문, 피드백
• 실시간 채팅 - 관심사가 맞는 창업자와 대화
• AI 아이디어 분석 - 사업 아이디어 검증 및 피드백
• 전문가 매칭 - 분야별 전문가 연결

지금 가입하고 창업 여정을 시작하세요!

# android/fastlane/metadata/android/ko-KR/changelogs/default.txt
버전 1.0.0
- 첫 번째 정식 출시
- 커뮤니티 게시판
- 실시간 채팅
- AI 아이디어 분석
```

---

## ⚠️ 주의사항

### 금지 패턴

| 패턴 | 문제 | 대안 |
|------|------|------|
| APK 업로드 | 2021년부터 AAB 필수 | App Bundle 사용 |
| 릴리스 키 직접 관리 | 분실 위험 | Play App Signing |
| 100% 즉시 출시 | 버그 시 피해 큼 | 단계적 출시 (10%→50%→100%) |
| ProGuard 규칙 누락 | 릴리스 빌드 크래시 | 필수 keep 규칙 추가 |

### ProGuard 주의

```proguard
# android/app/proguard-rules.pro

# Hotwire/Turbo
-keep class dev.hotwire.turbo.** { *; }

# Kotlin Serialization
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.**

# Firebase
-keep class com.google.firebase.** { *; }

# 앱 클래스
-keep class com.startupcommunity.** { *; }

# WebView JavaScript Interface
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
```

### 단계적 출시

```ruby
# 1단계: 10% 출시
lane :release do
  upload_to_play_store(
    track: "production",
    rollout: "0.1"
  )
end

# 2단계: 50%로 확대 (버그 없으면)
lane :expand_50 do
  upload_to_play_store(
    track: "production",
    rollout: "0.5",
    skip_upload_aab: true
  )
end

# 3단계: 100% 완전 출시
lane :full_release do
  upload_to_play_store(
    track: "production",
    rollout: "1.0",
    skip_upload_aab: true
  )
end

# 긴급 중단
lane :halt do
  upload_to_play_store(
    track: "production",
    rollout: "0",  # 출시 중단
    skip_upload_aab: true
  )
end
```

---

## ✅ 체크리스트

### 첫 배포 전
- [ ] Google Play Developer 계정 생성 ($25 일회성)
- [ ] Play Console에 앱 생성
- [ ] Play App Signing 활성화
- [ ] 업로드 키 생성 및 등록
- [ ] Data Safety 섹션 작성
- [ ] 개인정보 처리방침 URL 등록

### 매 배포 시
- [ ] 버전 코드/이름 증가
- [ ] 릴리스 노트 작성
- [ ] 스크린샷 최신화 (UI 변경 시)
- [ ] 내부 테스트 → 비공개 테스트 → 프로덕션
- [ ] 단계적 출시 설정

### 심사 제출 전
- [ ] 테스트 계정 정보 (정책 위반 검토 시)
- [ ] 연락처 정보 최신화
- [ ] 앱 설명 정확성 확인
- [ ] 콘텐츠 등급 설문 완료

---

## 📊 배포 워크플로우

```
┌─────────────────────────────────────────────────────────────┐
│                     개발 & 테스트                            │
│                                                             │
│  1. 기능 개발 완료                                          │
│  2. 로컬 테스트 (에뮬레이터 + 실기기)                       │
│  3. 코드 리뷰                                               │
└───────────────────────────────┬─────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                     내부 테스트 트랙                         │
│                                                             │
│  $ fastlane internal                                        │
│                                                             │
│  - 최대 100명 내부 테스터                                   │
│  - 심사 없이 즉시 배포                                      │
│  - 15분 내 설치 가능                                        │
└───────────────────────────────┬─────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                  비공개 테스트 (베타)                        │
│                                                             │
│  $ fastlane beta                                            │
│                                                             │
│  - 이메일로 테스터 초대                                     │
│  - 피드백 수집                                              │
│  - 버그 수정                                                │
└───────────────────────────────┬─────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                     프로덕션 출시                            │
│                                                             │
│  $ fastlane release                                         │
│                                                             │
│  10% → 모니터링 → 50% → 모니터링 → 100%                    │
│                                                             │
│  문제 발생 시: $ fastlane halt                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔗 연계 에이전트

| 에이전트 | 협력 포인트 |
|---------|------------|
| `android-expert` | Gradle 설정, 빌드 |
| `hotwire-native-expert` | 앱 기능, 심사 포인트 |
| `deep-linking-expert` | App Links, assetlinks |

---

## 📚 참조 문서

### 공식 문서
- [Google Play Console](https://play.google.com/console)
- [Play Console 정책](https://play.google.com/about/developer-content-policy/)
- [App Bundle 가이드](https://developer.android.com/guide/app-bundle)

### Fastlane
- [Fastlane Android](https://docs.fastlane.tools/getting-started/android/setup/)
- [Supply](https://docs.fastlane.tools/actions/supply/)
- [Screengrab](https://docs.fastlane.tools/actions/screengrab/)

### 프로젝트 내부
- [android-expert](../core/android-expert.md)
- [hotwire-native-expert](../core/hotwire-native-expert.md)
