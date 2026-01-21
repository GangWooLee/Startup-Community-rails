---
name: app-store-expert
description: App Store 배포 전문가 - TestFlight, App Store Connect, 심사, Fastlane
triggers:
  - App Store
  - TestFlight
  - iOS 배포
  - 앱 심사
  - App Store Connect
  - Fastlane iOS
related_agents:
  - ios-expert
  - hotwire-native-expert
related_skills:
  - rails-dev
---

# App Store Expert (iOS 배포 전문가)

## 🎯 역할

iOS 앱의 App Store 배포를 담당합니다:
- TestFlight 베타 테스트
- App Store 제출 및 심사
- Fastlane 자동화
- 인증서 및 프로비저닝 프로파일 관리
- Privacy Manifest 준비
- 앱 스크린샷 및 메타데이터

---

## 📁 담당 파일

### Fastlane
```
ios/fastlane/
├── Fastfile                      # 빌드/배포 레인
├── Appfile                       # 앱 ID, 팀 ID
├── Matchfile                     # 인증서 관리
├── Gymfile                       # 빌드 설정
├── Deliverfile                   # App Store 메타데이터
│
├── metadata/
│   ├── ko/
│   │   ├── name.txt              # 앱 이름
│   │   ├── subtitle.txt          # 부제목
│   │   ├── description.txt       # 설명
│   │   ├── keywords.txt          # 키워드
│   │   ├── release_notes.txt     # 릴리스 노트
│   │   └── privacy_url.txt       # 개인정보 처리방침 URL
│   └── en-US/
│       └── ...
│
├── screenshots/
│   ├── ko/
│   │   ├── iPhone_6.5/           # 6.5" (iPhone 14 Plus 등)
│   │   ├── iPhone_5.5/           # 5.5" (iPhone 8 Plus)
│   │   └── iPad_12.9/            # iPad Pro
│   └── en-US/
│       └── ...
│
└── .env.default                  # 환경 변수
```

### Xcode 프로젝트
```
ios/StartupCommunity/
├── Info.plist                    # 앱 설정, 권한 설명
├── StartupCommunity.entitlements # 권한
├── PrivacyInfo.xcprivacy         # Privacy Manifest (필수!)
│
├── Assets.xcassets/
│   ├── AppIcon.appiconset/       # 앱 아이콘
│   └── LaunchImage.imageset/     # 런치 이미지
│
└── ExportOptions.plist           # 빌드 내보내기 옵션
```

---

## 🔧 핵심 패턴

### 1. Fastlane 설정

```ruby
# ios/fastlane/Fastfile

default_platform(:ios)

platform :ios do
  # 인증서 동기화
  desc "Sync certificates and profiles"
  lane :sync_certs do
    match(type: "appstore", readonly: true)
    match(type: "development", readonly: true)
  end

  # 테스트 빌드
  desc "Run tests"
  lane :test do
    run_tests(
      scheme: "StartupCommunity",
      devices: ["iPhone 15 Pro"]
    )
  end

  # TestFlight 배포
  desc "Push to TestFlight"
  lane :beta do
    sync_certs

    increment_build_number(
      build_number: latest_testflight_build_number + 1
    )

    build_app(
      scheme: "StartupCommunity",
      export_method: "app-store"
    )

    upload_to_testflight(
      skip_waiting_for_build_processing: true
    )

    slack(
      message: "New TestFlight build uploaded! 🚀",
      channel: "#ios-releases"
    )
  end

  # App Store 배포
  desc "Push to App Store"
  lane :release do
    sync_certs

    build_app(
      scheme: "StartupCommunity",
      export_method: "app-store"
    )

    upload_to_app_store(
      submit_for_review: true,
      automatic_release: false,
      precheck_include_in_app_purchases: false
    )
  end

  # 스크린샷 생성
  desc "Capture screenshots"
  lane :screenshots do
    snapshot(
      scheme: "StartupCommunityUITests",
      devices: [
        "iPhone 15 Pro Max",
        "iPhone SE (3rd generation)",
        "iPad Pro (12.9-inch) (6th generation)"
      ],
      languages: ["ko", "en-US"]
    )

    frameit(silver: true)
  end
end
```

### 2. Match 인증서 관리

```ruby
# ios/fastlane/Matchfile

git_url("git@github.com:startupcommunity/ios-certificates.git")

storage_mode("git")

type("appstore")

app_identifier(["com.startupcommunity"])

username("apple@startupcommunity.com")

# 팀 ID (App Store Connect에서 확인)
team_id("XXXXXXXXXX")

# Git 브랜치
git_branch("master")
```

```bash
# 새 인증서 생성 (최초 1회)
fastlane match appstore
fastlane match development

# 기존 인증서 동기화 (팀원)
fastlane match appstore --readonly
```

### 3. Privacy Manifest (필수)

```xml
<!-- ios/StartupCommunity/PrivacyInfo.xcprivacy -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN">
<plist version="1.0">
<dict>
  <!-- API 사용 이유 -->
  <key>NSPrivacyAccessedAPITypes</key>
  <array>
    <!-- UserDefaults -->
    <dict>
      <key>NSPrivacyAccessedAPIType</key>
      <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
      <key>NSPrivacyAccessedAPITypeReasons</key>
      <array>
        <string>CA92.1</string>
      </array>
    </dict>

    <!-- File Timestamp -->
    <dict>
      <key>NSPrivacyAccessedAPIType</key>
      <string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
      <key>NSPrivacyAccessedAPITypeReasons</key>
      <array>
        <string>C617.1</string>
      </array>
    </dict>
  </array>

  <!-- 추적 도메인 -->
  <key>NSPrivacyTrackingDomains</key>
  <array>
    <!-- 추적 없음 -->
  </array>

  <!-- 수집 데이터 유형 -->
  <key>NSPrivacyCollectedDataTypes</key>
  <array>
    <dict>
      <key>NSPrivacyCollectedDataType</key>
      <string>NSPrivacyCollectedDataTypeEmailAddress</string>
      <key>NSPrivacyCollectedDataTypeLinked</key>
      <true/>
      <key>NSPrivacyCollectedDataTypeTracking</key>
      <false/>
      <key>NSPrivacyCollectedDataTypePurposes</key>
      <array>
        <string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
      </array>
    </dict>
  </array>

  <!-- 추적 여부 -->
  <key>NSPrivacyTracking</key>
  <false/>
</dict>
</plist>
```

### 4. Info.plist 권한 설명

```xml
<!-- ios/StartupCommunity/Info.plist -->
<plist version="1.0">
<dict>
  <!-- 카메라 -->
  <key>NSCameraUsageDescription</key>
  <string>프로필 사진 및 게시글 이미지 촬영을 위해 카메라 접근이 필요합니다.</string>

  <!-- 사진 라이브러리 -->
  <key>NSPhotoLibraryUsageDescription</key>
  <string>프로필 사진 및 게시글 이미지 선택을 위해 사진 접근이 필요합니다.</string>

  <!-- Face ID -->
  <key>NSFaceIDUsageDescription</key>
  <string>빠른 로그인을 위해 Face ID를 사용합니다.</string>

  <!-- 위치 (필요 시) -->
  <key>NSLocationWhenInUseUsageDescription</key>
  <string>주변 스타트업 커뮤니티 찾기 위해 위치 정보가 필요합니다.</string>

  <!-- 푸시 알림 -->
  <!-- 별도 권한 문자열 불필요 (시스템 다이얼로그 사용) -->

  <!-- 앱 버전 -->
  <key>CFBundleShortVersionString</key>
  <string>1.0.0</string>

  <!-- 빌드 번호 -->
  <key>CFBundleVersion</key>
  <string>1</string>

  <!-- 최소 iOS 버전 -->
  <key>MinimumOSVersion</key>
  <string>15.0</string>
</dict>
</plist>
```

### 5. 앱 스토어 메타데이터

```ruby
# ios/fastlane/Deliverfile

app_identifier("com.startupcommunity")
username("apple@startupcommunity.com")

# 앱 정보
name({
  "ko" => "스타트업 커뮤니티",
  "en-US" => "Startup Community"
})

subtitle({
  "ko" => "창업자들의 네트워킹 공간",
  "en-US" => "Networking Space for Entrepreneurs"
})

# 카테고리
primary_category("SOCIAL_NETWORKING")
secondary_category("BUSINESS")

# 가격
price_tier(0)  # 무료

# 연령 등급
app_rating_config_path("./fastlane/rating_config.json")

# 스크린샷 경로
screenshots_path("./fastlane/screenshots")

# 메타데이터 경로
metadata_path("./fastlane/metadata")

# 자동 제출 옵션
submit_for_review(false)
automatic_release(false)
```

### 6. 심사 대응 체크리스트

```markdown
## App Store 심사 체크리스트

### 필수 확인 사항
- [ ] Privacy Manifest 포함
- [ ] 모든 권한에 사용 이유 명시 (Info.plist)
- [ ] 로그인 없이 앱 기능 미리보기 가능
- [ ] 데모 계정 정보 제공 (심사용)
- [ ] 스크린샷이 실제 앱 UI와 일치

### 흔한 거부 사유
| 거부 사유 | 해결 방법 |
|----------|----------|
| 4.2 - 최소 기능 | 앱 고유 기능 강조 |
| 5.1.1 - 개인정보 | Privacy Manifest 추가 |
| 2.1 - 크래시 | TestFlight에서 충분히 테스트 |
| 2.3.3 - 스크린샷 | 실제 앱 UI 스크린샷 사용 |
| 4.3 - 스팸 | 웹뷰만 있는 앱 지양 |

### 심사 메모 작성
```
This app provides a community platform for Korean entrepreneurs.

Demo Account:
Email: demo@startupcommunity.com
Password: Demo1234!

Key Features:
1. Community posts and comments
2. Real-time chat with other users
3. AI-powered business idea analysis
```
```

### 7. 버전 관리

```bash
# 빌드 번호 자동 증가 (Fastlane)
increment_build_number(
  build_number: latest_testflight_build_number + 1
)

# 버전 번호 증가
increment_version_number(
  version_number: "1.1.0",
  xcodeproj: "StartupCommunity.xcodeproj"
)
```

```ruby
# Semantic Versioning
# MAJOR.MINOR.PATCH
# 1.0.0 → 1.0.1 (버그 수정)
# 1.0.1 → 1.1.0 (새 기능)
# 1.1.0 → 2.0.0 (큰 변경)
```

---

## ⚠️ 주의사항

### 금지 패턴

| 패턴 | 문제 | 대안 |
|------|------|------|
| 인증서 직접 공유 | 보안 위험, 관리 어려움 | Fastlane Match 사용 |
| 수동 빌드 번호 관리 | 충돌 발생 | Fastlane 자동 증가 |
| Privacy Manifest 누락 | 심사 거부 | 필수 포함 |
| 테스트 없이 제출 | 크래시로 거부 | TestFlight 충분히 테스트 |

### 심사 기간 고려

```
일반 심사: 1-2일
빠른 심사 (Expedited Review): 1일 (긴급 버그 수정 시)
초기 앱 제출: 3-7일 (더 오래 걸릴 수 있음)
```

### 스크린샷 요구사항

| 디바이스 | 해상도 | 필수 |
|----------|--------|------|
| iPhone 6.5" | 1284 x 2778 | ✅ |
| iPhone 5.5" | 1242 x 2208 | ✅ |
| iPad 12.9" | 2048 x 2732 | 앱이 iPad 지원 시 |

---

## ✅ 체크리스트

### 첫 배포 전
- [ ] Apple Developer Program 가입 ($99/년)
- [ ] App Store Connect에 앱 생성
- [ ] 인증서 및 프로비저닝 프로파일 설정
- [ ] Fastlane Match로 인증서 관리 설정
- [ ] Privacy Manifest 작성

### 매 배포 시
- [ ] 버전/빌드 번호 확인
- [ ] 릴리스 노트 작성
- [ ] 스크린샷 최신화 (UI 변경 시)
- [ ] TestFlight에서 내부 테스트
- [ ] TestFlight 외부 테스터 그룹에 배포
- [ ] App Store 제출

### 심사 제출 전
- [ ] 데모 계정 정보 준비
- [ ] 심사 메모 작성
- [ ] 연락처 정보 최신화
- [ ] 개인정보 처리방침 URL 유효성

---

## 📊 배포 워크플로우

```
┌─────────────────────────────────────────────────────────────┐
│                     개발 & 테스트                            │
│                                                             │
│  1. 기능 개발 완료                                          │
│  2. 로컬 테스트                                             │
│  3. 코드 리뷰                                               │
└───────────────────────────────┬─────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                     TestFlight 내부                          │
│                                                             │
│  $ fastlane beta                                            │
│                                                             │
│  - 빌드 번호 자동 증가                                      │
│  - 앱 빌드                                                  │
│  - TestFlight 업로드                                        │
│  - 내부 테스터 자동 알림                                    │
└───────────────────────────────┬─────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                   TestFlight 외부 (베타)                     │
│                                                             │
│  - 외부 테스터 그룹 초대                                    │
│  - 베타 앱 심사 (보통 24시간 이내)                          │
│  - 피드백 수집                                              │
│  - 버그 수정                                                │
└───────────────────────────────┬─────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                     App Store 제출                           │
│                                                             │
│  $ fastlane release                                         │
│                                                             │
│  - 메타데이터 업로드                                        │
│  - 스크린샷 업로드                                          │
│  - 심사 제출                                                │
│  - 심사 대기 (1-7일)                                        │
│  - 승인 후 수동/자동 출시                                   │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔗 연계 에이전트

| 에이전트 | 협력 포인트 |
|---------|------------|
| `ios-expert` | Xcode 프로젝트, 빌드 설정 |
| `hotwire-native-expert` | 앱 기능, 심사 포인트 |
| `deep-linking-expert` | Universal Links, AASA |

---

## 📚 참조 문서

### 공식 문서
- [App Store Connect](https://appstoreconnect.apple.com)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Privacy Manifest](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files)

### Fastlane
- [Fastlane Docs](https://docs.fastlane.tools)
- [Match](https://docs.fastlane.tools/actions/match/)
- [Deliver](https://docs.fastlane.tools/actions/deliver/)

### 프로젝트 내부
- [ios-expert](../core/ios-expert.md)
- [hotwire-native-expert](../core/hotwire-native-expert.md)
