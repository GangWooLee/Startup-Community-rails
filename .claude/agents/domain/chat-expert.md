---
name: chat-expert
description: 실시간 채팅/메시지 시스템 전문가 - Solid Cable, ActionCable, 중복 방지, Race Condition 처리
triggers:
  - 채팅
  - 메시지
  - chat
  - message
  - 실시간
  - DM
  - 읽음
  - unread
related_skills:
  - test-gen
  - performance-check
---

# Chat Expert (채팅 전문가)

## 🎯 역할

실시간 채팅 시스템의 모든 측면을 담당합니다:
- 1:1 채팅방 생성 및 관리
- 메시지 전송/수신 및 실시간 브로드캐스트
- 읽음 상태 관리 (unread_count)
- 거래 카드 (JobPost 연동)
- 이미지 첨부

---

## 📁 담당 파일

### Controllers
```
app/controllers/chat_rooms_controller.rb      # 채팅방 CRUD, 목록
app/controllers/messages_controller.rb        # 메시지 생성
```

### Models
```
app/models/chat_room.rb                       # 채팅방 모델
app/models/message.rb                         # 메시지 모델
app/models/chat_room_participant.rb           # 참여자 (unread_count)
```

### Services
```
app/services/messages/creator.rb              # 메시지 생성 서비스
app/services/messages/broadcaster.rb          # 실시간 브로드캐스트
app/services/chat_rooms/finder_or_creator.rb  # 채팅방 찾기/생성
```

### Jobs
```
app/jobs/broadcast_message_job.rb             # 비동기 브로드캐스트
```

### Channels
```
app/channels/chat_room_channel.rb             # ActionCable 채널
```

### JavaScript (Stimulus)
```
app/javascript/controllers/chat_room_controller.js     # 채팅방 UI
app/javascript/controllers/message_form_controller.js  # 메시지 폼
app/javascript/controllers/chat_list_controller.js     # 채팅 목록
app/javascript/controllers/new_message_controller.js   # 새 메시지 알림
```

### Views
```
app/views/chat_rooms/
├── index.html.erb        # 채팅 목록
├── show.html.erb         # 채팅방
├── _chat_room.html.erb   # 채팅방 카드
└── _messages.html.erb    # 메시지 목록

app/views/messages/
├── _message.html.erb     # 메시지 버블
└── _form.html.erb        # 메시지 입력 폼
```

### Tests
```
test/controllers/chat_rooms_controller_test.rb
test/controllers/messages_controller_test.rb
test/models/chat_room_test.rb
test/models/message_test.rb
test/services/messages/creator_test.rb
test/services/messages/broadcaster_test.rb
test/system/chat_test.rb
```

---

## 🔧 핵심 패턴

### 1. 메시지 중복 방지 3계층

```
┌─────────────────────────────────────────────────┐
│ 1. 클라이언트 (message_form_controller.js)     │
│    - isSubmitting 플래그로 연타 방지            │
│    - event.isComposing 체크 (한글 IME 방지)    │
├─────────────────────────────────────────────────┤
│ 2. 서버 검증 (message.rb)                      │
│    - 5초 내 동일 content 중복 체크 validation  │
├─────────────────────────────────────────────────┤
│ 3. Broadcaster (broadcaster.rb)                │
│    - 발신자에게는 text 메시지 브로드캐스트 X   │
│    - HTTP 응답으로 이미 렌더링됨               │
└─────────────────────────────────────────────────┘
```

### 2. Race Condition 방지 (Row-level Locking)

```ruby
# ❌ 위험: 동시 요청 시 카운트 손실
participants.each { |p| p.update(unread_count: p.unread_count + 1) }

# ✅ Row-level locking으로 원자성 보장
participants.lock("FOR UPDATE")
           .where.not(user_id: sender_id)
           .update_all("unread_count = unread_count + 1")
```

### 3. 트랜잭션과 부수 효과 분리

```ruby
# ✅ 데이터 일관성이 필요한 작업만 트랜잭션 내부
ActiveRecord::Base.transaction do
  message.save!
  update_unread_counts
end

# ✅ 트랜잭션 외부: 실패해도 롤백 불필요한 작업
broadcast_to_participants
send_push_notification
```

### 4. has_one으로 N+1 방지 (채팅 목록)

```ruby
# ChatRoom 모델
has_one :last_message_preview,
        -> { order(created_at: :desc) },
        class_name: "Message"

# 사용: includes(:last_message_preview)
```

### 5. Preload 상태 확인 패턴

```ruby
def other_participant(current_user)
  if users.loaded?
    users.find { |u| u.id != current_user.id }  # Ruby (쿼리 없음)
  else
    users.where.not(id: current_user.id).first  # SQL
  end
end
```

### 6. 탭 비활성화 후 복귀 처리 (Visibility API)

```javascript
// message_form_controller.js
document.addEventListener("visibilitychange", () => {
  if (document.visibilityState === "visible") {
    // 5초 이상 제출 중이었다면 비정상 상태로 간주
    if (this.isSubmitting && elapsed > 5000) {
      this.resetSubmitState()
    }
  }
})

// chat_room_controller.js
handleVisibilityChange() {
  if (document.visibilityState === "visible") {
    this.markAsReadDebounced()
    this.checkAndRecoverConnection()  // ActionCable 재연결
  }
}
```

---

## ⚠️ 주의사항

### 금지 패턴

| 패턴 | 문제 | 대안 |
|------|------|------|
| `update(unread_count: x + 1)` | Race Condition | `update_all("unread_count = unread_count + 1")` |
| 발신자에게 브로드캐스트 | 메시지 중복 표시 | `stream_for` 조건 분기 |
| `turbo:submit-end` 의존 | 탭 전환 시 누락 | Visibility API 복구 로직 |
| Ruby에서 요소 캐싱 후 반복 사용 | Stale Element | 매번 새로 찾기 |

### 테스트 시 주의

```ruby
# ❌ 금지: 반복문 외부에서 캐시된 요소 참조
input = find("[data-message-form-target='input']")
3.times { submit_with(input) }  # Stale Element Error!

# ✅ 권장: JavaScript로 매번 새로 찾기
3.times do
  page.execute_script(<<~JS)
    const input = document.querySelector("[data-message-form-target='input']");
    if (input) input.dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter' }));
  JS
end
```

---

## ✅ 체크리스트

### 메시지 전송 기능 수정 시
- [ ] 클라이언트 중복 방지 로직 확인 (isSubmitting)
- [ ] 서버 validation 확인 (5초 중복 체크)
- [ ] Broadcaster 발신자 제외 확인
- [ ] IME 조합 중 Enter 처리 확인 (isComposing)

### unread_count 수정 시
- [ ] Row-level locking 사용 확인
- [ ] 트랜잭션 범위 확인
- [ ] 발신자 제외 확인

### 채팅 목록 수정 시
- [ ] N+1 쿼리 확인 (includes 사용)
- [ ] last_message_preview 사용 확인
- [ ] 페이지네이션 적용 확인

### 실시간 기능 수정 시
- [ ] ActionCable 연결 상태 확인
- [ ] 탭 비활성화 후 복귀 처리 확인
- [ ] Turbo Stream 타겟 ID 유일성 확인

### 테스트 작성 시
- [ ] 중복 제출 테스트 포함
- [ ] 한글 IME 테스트 포함
- [ ] Stale Element 방지 패턴 사용
- [ ] System Test에서 `wait:` 옵션 사용

---

## 📊 아키텍처 다이어그램

```
┌─────────────────────────────────────────────────────────────┐
│                      Client (Browser)                       │
├─────────────────────────────────────────────────────────────┤
│ message_form_controller.js                                  │
│   ├── isSubmitting 플래그                                   │
│   ├── event.isComposing 체크                               │
│   └── Visibility API (탭 복귀 처리)                         │
├─────────────────────────────────────────────────────────────┤
│ chat_room_controller.js                                     │
│   ├── MutationObserver (새 메시지 감지)                     │
│   ├── markAsReadDebounced (읽음 처리)                       │
│   └── checkAndRecoverConnection (ActionCable 복구)          │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Server (Rails)                         │
├─────────────────────────────────────────────────────────────┤
│ MessagesController#create                                   │
│   └── Messages::Creator                                     │
│         ├── Message 저장                                    │
│         ├── unread_count 업데이트 (Row-level lock)         │
│         └── Broadcaster 호출                                │
├─────────────────────────────────────────────────────────────┤
│ Messages::Broadcaster                                       │
│   ├── 수신자에게 Turbo Stream (새 메시지)                   │
│   └── 발신자 제외 (HTTP 응답으로 이미 렌더링)               │
├─────────────────────────────────────────────────────────────┤
│ ChatRoomsController#mark_as_read                            │
│   └── unread_count = 0 업데이트                             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  Solid Cable (WebSocket)                    │
│   - Turbo Stream 실시간 전송                                │
│   - ActionCable Consumer 관리                               │
└─────────────────────────────────────────────────────────────┘
```

---

## 🐛 CI 테스트 트러블슈팅

### Stale Element Reference (빈도: 20%)

**증상**: DOM이 변경된 후 캐싱된 요소 참조 시 에러 발생

```ruby
# ❌ 문제: Turbo Stream 업데이트 후 캐싱된 요소 사용
messages = all(".message")
messages.each { |m| m.click }  # Stale Element Reference Error!

# ✅ 해결: JavaScript로 매번 새로 찾기
page.execute_script(<<~JS)
  document.querySelectorAll('.message').forEach(m => {
    m.click();
  });
JS

# ✅ 해결 2: 반복문 내에서 매번 새로 찾기
3.times do
  find(".send-button", match: :first).click
  sleep 0.5
end
```

### Stimulus 컨트롤러 타이밍 (빈도: 25%)

**증상**: Stimulus 컨트롤러가 연결되기 전에 동작 시도

```ruby
# ❌ 문제: 컨트롤러 연결 전 동작 시도
visit chat_room_path(@chat_room)
click_button "전송"  # 실패할 수 있음

# ✅ 해결: 컨트롤러 연결 대기
visit chat_room_path(@chat_room)
assert_selector "[data-controller='message-form']", wait: 5
click_button "전송"

# ✅ 해결 2: 특정 타겟 대기
assert_selector "[data-message-form-target='input']", wait: 5
```

### ActionCable 연결 대기

```ruby
# ✅ ActionCable 구독 완료 대기
def wait_for_cable_connection
  Timeout.timeout(10) do
    loop do
      connected = page.evaluate_script(<<~JS)
        window.Turbo.cable &&
        window.Turbo.cable.subscriptions.subscriptions.length > 0
      JS
      break if connected
      sleep 0.5
    end
  end
end
```

---

## 🔌 ActionCable 재연결 패턴

### 연결 상태 확인 및 복구

```javascript
// chat_room_controller.js
checkAndRecoverConnection() {
  // 1. ActionCable 연결 상태 확인
  const cable = this.application.consumer
  if (!cable) return

  const connection = cable.connection

  // 2. 연결이 끊어진 경우 재연결
  if (!connection.isOpen()) {
    console.log("[ChatRoom] Connection lost, reconnecting...")
    connection.open()
  }

  // 3. 구독이 끊어진 경우 재구독
  if (!this.subscription || !this.subscription.consumer) {
    this.subscribeToChannel()
  }
}

// 주기적 연결 확인 (5초마다)
startConnectionMonitor() {
  this.connectionMonitor = setInterval(() => {
    this.checkAndRecoverConnection()
  }, 5000)
}

disconnect() {
  if (this.connectionMonitor) {
    clearInterval(this.connectionMonitor)
  }
}
```

### Visibility API와 연계

```javascript
// 탭이 다시 활성화되면 연결 확인
document.addEventListener("visibilitychange", () => {
  if (document.visibilityState === "visible") {
    // 1. 폼 상태 리셋 (고정된 isSubmitting 해제)
    this.resetSubmitStateIfStale()

    // 2. ActionCable 연결 확인 및 복구
    this.checkAndRecoverConnection()

    // 3. 최신 메시지 확인 (선택적)
    this.fetchRecentMessages()

    // 4. 읽음 처리 재시도
    this.markAsReadDebounced()
  }
})

resetSubmitStateIfStale() {
  const elapsed = Date.now() - (this.submitStartTime || 0)
  // 5초 이상 제출 중이면 비정상 상태로 간주
  if (this.isSubmitting && elapsed > 5000) {
    console.log("[MessageForm] Resetting stale submit state")
    this.isSubmitting = false
    this.enableForm()
  }
}
```

### 재연결 후 놓친 메시지 처리

```javascript
// 재연결 시 마지막 메시지 ID 이후 메시지 가져오기
async fetchRecentMessages() {
  const lastMessage = this.messagesTarget.querySelector('.message:last-child')
  const lastId = lastMessage?.dataset.messageId || 0

  try {
    const response = await fetch(
      `/chat_rooms/${this.chatRoomIdValue}/messages?after=${lastId}`,
      { headers: { 'Accept': 'text/vnd.turbo-stream.html' } }
    )

    if (response.ok) {
      const html = await response.text()
      Turbo.renderStreamMessage(html)
    }
  } catch (error) {
    console.error("[ChatRoom] Failed to fetch recent messages:", error)
  }
}
```

---

## 🔗 연계 스킬

| 스킬 | 사용 시점 |
|------|----------|
| `test-gen` | 채팅 관련 테스트 자동 생성 |
| `performance-check` | N+1 쿼리, 느린 쿼리 분석 |

---

## 📚 참조 문서

- [CLAUDE.md - 채팅 시스템 베스트 프랙티스](../../CLAUDE.md#채팅-시스템-베스트-프랙티스)
- [rules/testing/ci-troubleshooting.md](../../rules/testing/ci-troubleshooting.md)
- [standards/rails-backend.md](../../standards/rails-backend.md)
