# Mobile Agents - Hotwire Native 앱 개발

> **목적**: Hotwire Native 기반 iOS/Android 하이브리드 앱 개발을 위한 전문 에이전트
> **생성일**: 2026-01-21
> **에이전트 수**: 9개 (Core 3 + Feature 4 + Release 2)

---

## 에이전트 목록

### Core Agents (핵심)

| 에이전트 | 설명 | 트리거 키워드 |
|---------|------|--------------|
| [hotwire-native-expert](core/hotwire-native-expert.md) | 전체 아키텍처, Path Configuration | hotwire, hybrid, 네이티브 앱 |
| [ios-expert](core/ios-expert.md) | Swift, Navigator, WKWebView | iOS, Swift, Xcode |
| [android-expert](core/android-expert.md) | Kotlin, Fragment, WebView | Android, Kotlin, Gradle |

### Feature Agents (기능)

| 에이전트 | 설명 | 트리거 키워드 |
|---------|------|--------------|
| [bridge-expert](feature/bridge-expert.md) | 웹-네이티브 양방향 통신 | bridge, 웹 네이티브 통신 |
| [mobile-auth-expert](feature/mobile-auth-expert.md) | 세션 동기화, 생체 인증 | 앱 인증, Face ID, Keychain |
| [push-notification-expert](feature/push-notification-expert.md) | FCM, APNs 푸시 알림 | 푸시, FCM, APNs |
| [deep-linking-expert](feature/deep-linking-expert.md) | Universal/App Links | 딥 링크, Universal Link |

### Release Agents (배포)

| 에이전트 | 설명 | 트리거 키워드 |
|---------|------|--------------|
| [app-store-expert](release/app-store-expert.md) | App Store, TestFlight 배포 | App Store, TestFlight |
| [play-store-expert](release/play-store-expert.md) | Play Store 배포 | Play Store, Google Play |

---

## 사용 방법

### 1. 자동 활성화 (권장)
에이전트는 트리거 키워드가 포함된 요청 시 자동으로 컨텍스트가 로드됩니다.

```
사용자: "iOS 앱에서 세션 유지가 안 돼요"
→ ios-expert + mobile-auth-expert 컨텍스트 자동 활성화
```

### 2. 명시적 호출
특정 에이전트를 명시적으로 호출할 수도 있습니다.

```
사용자: "@hotwire-native-expert Path Configuration 설계해줘"
```

---

## 기술 스택 개요

### Hotwire Native 아키텍처

```
┌─────────────────────────────────────────────────────────────┐
│                   Native App Shell                          │
│                                                             │
│  ┌─────────────────┐     ┌─────────────────┐               │
│  │  iOS (Swift)    │     │ Android (Kotlin) │               │
│  │  - Navigator    │     │  - Navigator     │               │
│  │  - WKWebView    │     │  - WebView       │               │
│  │  - Bridge       │     │  - Bridge        │               │
│  └────────┬────────┘     └────────┬────────┘               │
│           │                       │                         │
│           └───────────┬───────────┘                         │
│                       ▼                                     │
│  ┌─────────────────────────────────────────────────────────┐│
│  │              Rails Web Application                       ││
│  │                                                          ││
│  │   Turbo Frames + Turbo Streams + Stimulus               ││
│  │              + Bridge Controllers                        ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

### 핵심 개념

| 개념 | 설명 |
|------|------|
| **Path Configuration** | JSON 기반 URL → 화면 동작 매핑 |
| **Navigator** | iOS/Android 네비게이션 컨트롤러 |
| **Bridge Components** | 웹 ↔ 네이티브 양방향 통신 |
| **Native Screens** | 선택적 네이티브 화면 통합 |

### 기술 선택 기준

| 시나리오 | 웹뷰 | 네이티브 |
|---------|------|---------|
| 콘텐츠 표시 | ✅ | |
| 폼 입력 | ✅ | |
| 카메라/갤러리 | | ✅ |
| 생체 인증 | | ✅ |
| 푸시 알림 설정 | | ✅ |
| 고성능 애니메이션 | | ✅ |

---

## 에이전트 협력 패턴

### 시나리오 1: 새 기능 추가 (채팅 앱 연동)

```
1. hotwire-native-expert → Path Configuration 설계
2. bridge-expert → 웹-네이티브 통신 구현
3. chat-expert (기존) → 채팅 도메인 로직
4. push-notification-expert → 메시지 알림
```

### 시나리오 2: 인증 시스템 구현

```
1. hotwire-native-expert → 앱 감지 패턴
2. auth-expert (기존) → OAuth, 세션 관리
3. mobile-auth-expert → Keychain/Keystore, 생체 인증
4. ios-expert / android-expert → 플랫폼별 구현
```

### 시나리오 3: 앱스토어 배포

```
1. hotwire-native-expert → 배포 전 체크리스트
2. ios-expert → Xcode 빌드 설정
3. app-store-expert → TestFlight, App Store 제출
4. android-expert → Gradle 빌드 설정
5. play-store-expert → Play Console 배포
```

---

## 기존 도메인 에이전트와의 연계

| 기존 에이전트 | 연계 모바일 에이전트 | 협력 포인트 |
|--------------|---------------------|------------|
| chat-expert | bridge, push | 실시간 메시지, 알림 |
| auth-expert | mobile-auth | OAuth, 세션 관리 |
| community-expert | deep-linking | 게시글 공유 |
| ui-ux-expert | bridge, hotwire-native | 모바일 UI 최적화 |
| admin-expert | push | 관리자 알림 |

---

## 폴더 구조

```
.claude/agents/mobile/
├── README.md                      # 이 파일
│
├── core/                          # 핵심 에이전트 (3개)
│   ├── hotwire-native-expert.md   # 아키텍처
│   ├── ios-expert.md              # iOS
│   └── android-expert.md          # Android
│
├── feature/                       # 기능 에이전트 (4개)
│   ├── bridge-expert.md           # 웹-네이티브 통신
│   ├── mobile-auth-expert.md      # 인증
│   ├── push-notification-expert.md # 푸시
│   └── deep-linking-expert.md     # 딥 링킹
│
└── release/                       # 배포 에이전트 (2개)
    ├── app-store-expert.md        # iOS 배포
    └── play-store-expert.md       # Android 배포
```

---

## 프로젝트 Hotwire Native 준비도

현재 Startup Community 프로젝트의 모바일 앱 전환 준비도:

| 영역 | 현황 | 평가 |
|------|------|------|
| **Turbo Streams** | 채팅, 알림 등 광범위 사용 | ✅ 95% |
| **Stimulus** | 70개 컨트롤러 | ✅ 90% |
| **Solid Cable** | 프로덕션 준비 완료 | ✅ 85% |
| **반응형 디자인** | Tailwind 체계적 | ✅ 80% |
| **터치 이벤트** | 1개 컨트롤러만 지원 | ⚠️ 20% |

### 앱 전환 시 필요한 작업

1. **Path Configuration 설계** → hotwire-native-expert
2. **앱 전용 레이아웃** → hotwire-native-expert
3. **Bridge 컨트롤러** → bridge-expert
4. **세션 동기화** → mobile-auth-expert
5. **푸시 알림 통합** → push-notification-expert

---

## 참조 문서

### 공식 문서
- [Hotwire Native](https://native.hotwired.dev/)
- [turbo-ios](https://github.com/hotwired/turbo-ios)
- [turbo-android](https://github.com/hotwired/turbo-android)

### 튜토리얼
- [Joe Masilotti - Hotwire Native](https://masilotti.com/hotwire-native/)
- [Learn Hotwire](https://learnhotwire.com/)

### 프로젝트 내부
- [agents/README.md](../README.md) - 전체 에이전트 가이드
- [CLAUDE.md](../../CLAUDE.md) - 프로젝트 메인 컨텍스트
