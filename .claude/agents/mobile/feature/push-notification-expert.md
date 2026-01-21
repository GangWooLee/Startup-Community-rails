---
name: push-notification-expert
description: 푸시 알림 전문가 - FCM, APNs, 토큰 관리, 딥링크 연동
triggers:
  - 푸시 알림
  - push notification
  - FCM
  - APNs
  - 앱 알림
  - 디바이스 토큰
related_agents:
  - ios-expert
  - android-expert
  - deep-linking-expert
  - chat-expert
related_skills:
  - background-job
  - rails-dev
---

# Push Notification Expert (푸시 알림 전문가)

## 🎯 역할

모바일 앱 푸시 알림 시스템을 담당합니다:
- FCM (Firebase Cloud Messaging) 설정 및 전송
- APNs (Apple Push Notification service) 통합
- 디바이스 토큰 등록/관리
- 알림 페이로드 설계
- 딥링크 연동 (알림 탭 → 앱 내 화면)
- 백그라운드/포그라운드 알림 처리

---

## 📁 담당 파일

### Rails Server
```
app/models/
├── device.rb                        # 디바이스 토큰 모델

app/services/push/
├── notification_sender.rb           # 알림 전송 서비스
├── fcm_client.rb                    # FCM HTTP v1 API
├── apns_client.rb                   # APNs 클라이언트 (옵션)
└── payload_builder.rb               # 페이로드 생성

app/jobs/
├── send_push_notification_job.rb    # 비동기 알림 전송
└── cleanup_invalid_tokens_job.rb    # 무효 토큰 정리

app/controllers/api/v1/
├── devices_controller.rb            # 토큰 등록 API

config/initializers/
├── firebase.rb                      # Firebase Admin SDK 설정

db/migrate/
├── xxx_create_devices.rb            # devices 테이블
```

### iOS
```
ios/StartupCommunity/
├── Services/
│   └── PushNotificationService.swift    # 푸시 알림 서비스
│
├── App/
│   └── AppDelegate.swift                # APNs 등록, 알림 수신

ios/StartupCommunity.entitlements        # Push Notification 권한
```

### Android
```
android/app/src/main/kotlin/com/startupcommunity/
├── services/
│   └── FCMService.kt                    # FCM 메시지 수신

android/app/
├── google-services.json                 # Firebase 설정

android/app/src/main/
├── AndroidManifest.xml                  # FCM 서비스 등록
```

---

## 🔧 핵심 패턴

### 1. 푸시 알림 아키텍처

```
┌─────────────────────────────────────────────────────────────┐
│                     Rails Server                            │
│                                                             │
│  ┌─────────────────┐    ┌─────────────────────────────────┐│
│  │ Notification    │───►│ SendPushNotificationJob         ││
│  │ Created         │    │                                 ││
│  └─────────────────┘    │  ┌────────────────────────────┐ ││
│                         │  │ Push::NotificationSender   │ ││
│                         │  │                            │ ││
│                         │  │  iOS → APNs via FCM        │ ││
│                         │  │  Android → FCM             │ ││
│                         │  └────────────────────────────┘ ││
│                         └─────────────────────────────────┘│
└───────────────────────────────────┬─────────────────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    ▼                               ▼
            ┌───────────────┐               ┌───────────────┐
            │     FCM       │               │     APNs      │
            │  (Android)    │               │    (iOS)      │
            └───────┬───────┘               └───────┬───────┘
                    │                               │
                    ▼                               ▼
            ┌───────────────┐               ┌───────────────┐
            │  Android App  │               │   iOS App     │
            │  FCMService   │               │  AppDelegate  │
            └───────────────┘               └───────────────┘
```

### 2. Device 모델

```ruby
# app/models/device.rb
class Device < ApplicationRecord
  belongs_to :user

  enum platform: { ios: 0, android: 1 }

  validates :token, presence: true, uniqueness: true
  validates :platform, presence: true

  scope :active, -> { where("updated_at > ?", 30.days.ago) }
  scope :for_user, ->(user) { where(user: user) }

  # 토큰 등록/업데이트
  def self.register(user:, token:, platform:)
    device = find_or_initialize_by(token: token)
    device.update!(
      user: user,
      platform: platform,
      updated_at: Time.current
    )
    device
  end

  # 무효 토큰 삭제
  def self.remove_invalid_token(token)
    where(token: token).destroy_all
  end
end

# db/migrate/xxx_create_devices.rb
class CreateDevices < ActiveRecord::Migration[7.1]
  def change
    create_table :devices do |t|
      t.references :user, null: false, foreign_key: true
      t.string :token, null: false
      t.integer :platform, null: false, default: 0
      t.timestamps
    end

    add_index :devices, :token, unique: true
    add_index :devices, [:user_id, :platform]
  end
end
```

### 3. FCM 전송 서비스 (HTTP v1 API)

```ruby
# app/services/push/fcm_client.rb
require "googleauth"
require "net/http"

module Push
  class FcmClient
    FCM_ENDPOINT = "https://fcm.googleapis.com/v1/projects/%s/messages:send"

    def initialize
      @project_id = Rails.application.credentials.dig(:firebase, :project_id)
      @credentials = Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: StringIO.new(
          Rails.application.credentials.firebase[:service_account].to_json
        ),
        scope: "https://www.googleapis.com/auth/firebase.messaging"
      )
    end

    def send_notification(device_token:, title:, body:, data: {})
      payload = build_payload(device_token, title, body, data)

      uri = URI(FCM_ENDPOINT % @project_id)
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{access_token}"
      request["Content-Type"] = "application/json"
      request.body = payload.to_json

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end

      handle_response(response, device_token)
    end

    private

    def build_payload(token, title, body, data)
      {
        message: {
          token: token,
          notification: {
            title: title,
            body: body
          },
          data: data.transform_values(&:to_s),
          android: android_config,
          apns: apns_config
        }
      }
    end

    def android_config
      {
        priority: "high",
        notification: {
          channel_id: "default",
          click_action: "OPEN_ACTIVITY"
        }
      }
    end

    def apns_config
      {
        payload: {
          aps: {
            sound: "default",
            badge: 1
          }
        }
      }
    end

    def access_token
      @credentials.fetch_access_token!["access_token"]
    end

    def handle_response(response, device_token)
      case response.code.to_i
      when 200
        { success: true }
      when 404, 410
        # 무효 토큰 삭제
        Device.remove_invalid_token(device_token)
        { success: false, error: "invalid_token" }
      else
        Rails.logger.error "[FCM] Error: #{response.body}"
        { success: false, error: response.body }
      end
    end
  end
end
```

### 4. 알림 전송 Job

```ruby
# app/jobs/send_push_notification_job.rb
class SendPushNotificationJob < ApplicationJob
  queue_as :push_notifications

  def perform(notification_id)
    notification = Notification.find(notification_id)
    user = notification.user

    # 사용자의 모든 활성 디바이스에 전송
    devices = Device.for_user(user).active

    devices.find_each do |device|
      send_to_device(notification, device)
    end
  end

  private

  def send_to_device(notification, device)
    Push::FcmClient.new.send_notification(
      device_token: device.token,
      title: notification.title,
      body: notification.body,
      data: {
        type: notification.notification_type,
        resource_id: notification.notifiable_id.to_s,
        resource_type: notification.notifiable_type,
        url: notification_url(notification)
      }
    )
  rescue => e
    Rails.logger.error "[Push] Failed to send: #{e.message}"
    Sentry.capture_exception(e) if defined?(Sentry)
  end

  def notification_url(notification)
    case notification.notifiable_type
    when "Message"
      "/chat_rooms/#{notification.notifiable.chat_room_id}"
    when "Comment"
      "/posts/#{notification.notifiable.post_id}"
    when "Like"
      "/posts/#{notification.notifiable.likeable_id}"
    else
      "/notifications"
    end
  end
end
```

### 5. 디바이스 토큰 API

```ruby
# app/controllers/api/v1/devices_controller.rb
module Api
  module V1
    class DevicesController < ApplicationController
      before_action :authenticate_user!

      # POST /api/v1/devices
      def create
        device = Device.register(
          user: current_user,
          token: params[:token],
          platform: params[:platform]
        )

        render json: { success: true, device_id: device.id }
      rescue => e
        render json: { success: false, error: e.message }, status: :unprocessable_entity
      end

      # DELETE /api/v1/devices
      def destroy
        Device.where(user: current_user, token: params[:token]).destroy_all
        render json: { success: true }
      end
    end
  end
end
```

### 6. iOS 푸시 알림 처리

```swift
// ios/App/AppDelegate.swift
import UIKit
import UserNotifications
import FirebaseMessaging

class AppDelegate: UIResponder, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Firebase 초기화
        FirebaseApp.configure()

        // FCM 델리게이트 설정
        Messaging.messaging().delegate = self

        // 알림 권한 요청
        requestNotificationPermission()

        return true
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }

    // APNs 토큰 수신
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    // FCM 토큰 수신/갱신
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        PushNotificationService.shared.registerToken(token)
    }

    // 포그라운드 알림 표시
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .badge, .sound])
    }

    // 알림 탭 처리
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo

        if let url = userInfo["url"] as? String {
            Navigator.shared.visit(url: URL(string: "https://undrewai.com\(url)")!)
        }

        completionHandler()
    }
}

// ios/Services/PushNotificationService.swift
class PushNotificationService {
    static let shared = PushNotificationService()

    func registerToken(_ token: String) {
        guard let sessionToken = KeychainService.shared.getSession()?.sessionToken else {
            return
        }

        var request = URLRequest(url: URL(string: "https://undrewai.com/api/v1/devices")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode([
            "token": token,
            "platform": "ios"
        ])

        URLSession.shared.dataTask(with: request).resume()
    }
}
```

### 7. Android FCM 처리

```kotlin
// android/services/FCMService.kt
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class FCMService : FirebaseMessagingService() {

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        registerToken(token)
    }

    override fun onMessageReceived(message: RemoteMessage) {
        super.onMessageReceived(message)

        // 데이터 메시지 처리
        val data = message.data
        val url = data["url"]

        // 알림 표시
        message.notification?.let { notification ->
            showNotification(
                title = notification.title ?: "Startup Community",
                body = notification.body ?: "",
                url = url
            )
        }
    }

    private fun registerToken(token: String) {
        val sessionToken = SecureStorageService.getInstance(this)
            .getSession()?.sessionToken ?: return

        // API 호출하여 토큰 등록
        // ... HTTP 요청
    }

    private fun showNotification(title: String, body: String, url: String?) {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            url?.let { putExtra("deep_link", it) }
        }

        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_ONE_SHOT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, "default")
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title)
            .setContentText(body)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(System.currentTimeMillis().toInt(), notification)
    }
}
```

---

## ⚠️ 주의사항

### 금지 패턴

| 패턴 | 문제 | 대안 |
|------|------|------|
| FCM Legacy API | 2024년 지원 종료 | FCM HTTP v1 API 사용 |
| 토큰을 평문 저장 | 보안 취약 | Keychain/Keystore |
| 동기 알림 전송 | 응답 지연 | Background Job 사용 |
| 무효 토큰 무시 | 전송 실패 누적 | 404/410 시 토큰 삭제 |

### FCM 토큰 관리

```ruby
# ❌ 문제: 동일 토큰 중복 저장
Device.create!(user: user, token: token)

# ✅ 해결: find_or_initialize_by 사용
device = Device.find_or_initialize_by(token: token)
device.update!(user: user, platform: platform)
```

### 알림 페이로드 제한

| 플랫폼 | 최대 크기 |
|--------|----------|
| FCM (Android) | 4KB |
| APNs (iOS) | 4KB |

```ruby
# ❌ 문제: 페이로드 초과
data: { full_content: very_long_string }

# ✅ 해결: 최소 데이터만 전송
data: { type: "message", id: "123" }
# 앱에서 상세 정보는 API로 조회
```

---

## ✅ 체크리스트

### 초기 설정 시
- [ ] Firebase 프로젝트 생성
- [ ] iOS: APNs 인증 키 업로드
- [ ] Android: google-services.json 추가
- [ ] Rails: Service Account JSON 설정
- [ ] Device 마이그레이션 실행

### 알림 전송 구현 시
- [ ] Background Job 사용
- [ ] 무효 토큰 처리 로직
- [ ] 딥링크 URL 포함
- [ ] 플랫폼별 페이로드 설정

### 앱 구현 시
- [ ] 알림 권한 요청
- [ ] FCM 토큰 서버 등록
- [ ] 포그라운드 알림 처리
- [ ] 알림 탭 → 딥링크

### 테스트
- [ ] 토큰 등록 확인
- [ ] 알림 수신 확인 (포/백그라운드)
- [ ] 딥링크 이동 확인
- [ ] 로그아웃 시 토큰 삭제

---

## 🔗 연계 에이전트

| 에이전트 | 협력 포인트 |
|---------|------------|
| `ios-expert` | APNs 토큰, AppDelegate |
| `android-expert` | FCM Service, Manifest |
| `deep-linking-expert` | 알림 탭 → 앱 내 화면 |
| `chat-expert` | 새 메시지 알림 |

---

## 📚 참조 문서

### 공식 문서
- [FCM HTTP v1 API](https://firebase.google.com/docs/cloud-messaging/send-message)
- [APNs Provider API](https://developer.apple.com/documentation/usernotifications)
- [Firebase Admin Ruby](https://github.com/cheddar-me/firebase-admin-sdk-ruby)

### 프로젝트 내부
- [ios-expert](../core/ios-expert.md)
- [android-expert](../core/android-expert.md)
- [deep-linking-expert](./deep-linking-expert.md)
