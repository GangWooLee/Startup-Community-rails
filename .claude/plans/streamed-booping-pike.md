# 1:1 채팅(DM) 기능 구현 계획

## 개요
외주 문의, 프로필에서 대화 시작 등을 위한 실시간 1:1 DM 채팅 기능 구현

## 핵심 요구사항
- 1:1 DM 채팅 (그룹 채팅 X)
- 실시간 메시지 송수신 (Turbo Streams + ActionCable)
- 안읽은 메시지 카운트/뱃지
- 내 메시지 vs 상대방 메시지 구분 (버블 스타일/위치)
- 최신 메시지로 자동 스크롤
- 채팅방 접근 권한 (참여자만)
- 모바일 우선 UI

---

## Phase 1: 데이터베이스 & 모델 (Day 1)

### 1.1 마이그레이션 생성

```bash
# 채팅방 테이블
rails g migration CreateChatRooms

# 채팅방 참여자 테이블 (Join Table)
rails g migration CreateChatRoomParticipants

# 메시지 테이블
rails g migration CreateMessages
```

### 1.2 Schema 설계

**chat_rooms**
```ruby
create_table :chat_rooms do |t|
  t.integer :messages_count, default: 0, null: false
  t.datetime :last_message_at
  t.timestamps
end

add_index :chat_rooms, :last_message_at
```

**chat_room_participants**
```ruby
create_table :chat_room_participants do |t|
  t.references :chat_room, null: false, foreign_key: true
  t.references :user, null: false, foreign_key: true
  t.datetime :last_read_at  # 읽음 처리용
  t.timestamps
end

add_index :chat_room_participants, [:chat_room_id, :user_id], unique: true
add_index :chat_room_participants, [:user_id, :chat_room_id]
```

**messages**
```ruby
create_table :messages do |t|
  t.references :chat_room, null: false, foreign_key: true
  t.references :sender, null: false, foreign_key: { to_table: :users }
  t.text :content, null: false
  t.timestamps
end

add_index :messages, [:chat_room_id, :created_at]
add_index :messages, :sender_id
```

### 1.3 모델 정의

**app/models/chat_room.rb**
```ruby
class ChatRoom < ApplicationRecord
  has_many :participants, class_name: "ChatRoomParticipant", dependent: :destroy
  has_many :users, through: :participants
  has_many :messages, dependent: :destroy

  # 1:1 채팅방 찾기 또는 생성
  def self.find_or_create_between(user1, user2)
    # 기존 채팅방 찾기
    room = joins(:participants)
           .where(chat_room_participants: { user_id: [user1.id, user2.id] })
           .group(:id)
           .having("COUNT(chat_room_participants.id) = 2")
           .first

    return room if room

    # 새 채팅방 생성
    transaction do
      room = create!
      room.participants.create!(user: user1)
      room.participants.create!(user: user2)
      room
    end
  end

  # 상대방 가져오기
  def other_participant(current_user)
    users.where.not(id: current_user.id).first
  end
end
```

**app/models/chat_room_participant.rb**
```ruby
class ChatRoomParticipant < ApplicationRecord
  belongs_to :chat_room
  belongs_to :user

  # 안읽은 메시지 수
  def unread_count
    chat_room.messages
             .where.not(sender_id: user_id)
             .where("created_at > ?", last_read_at || Time.at(0))
             .count
  end

  # 읽음 처리
  def mark_as_read!
    update!(last_read_at: Time.current)
  end
end
```

**app/models/message.rb**
```ruby
class Message < ApplicationRecord
  belongs_to :chat_room, counter_cache: true, touch: :last_message_at
  belongs_to :sender, class_name: "User"

  validates :content, presence: true, length: { maximum: 2000 }

  after_create_commit :broadcast_message

  private

  def broadcast_message
    # Turbo Stream 브로드캐스트 (채팅방)
    broadcast_append_to chat_room,
                        target: "messages",
                        partial: "messages/message",
                        locals: { message: self }

    # 상대방에게 알림 브로드캐스트 (unread badge)
    chat_room.participants.where.not(user_id: sender_id).each do |participant|
      broadcast_replace_to "user_#{participant.user_id}_chat_badge",
                           target: "chat_unread_badge",
                           partial: "shared/chat_unread_badge",
                           locals: { count: participant.user.total_unread_messages }
    end
  end
end
```

**app/models/user.rb 추가**
```ruby
# User 모델에 추가
has_many :chat_room_participants, dependent: :destroy
has_many :chat_rooms, through: :chat_room_participants
has_many :sent_messages, class_name: "Message", foreign_key: :sender_id

def total_unread_messages
  chat_room_participants.sum(&:unread_count)
end
```

---

## Phase 2: 컨트롤러 & 라우팅 (Day 2)

### 2.1 라우팅 추가

**config/routes.rb**
```ruby
# Chat
resources :chat_rooms, only: [:index, :show, :create] do
  resources :messages, only: [:create], shallow: true
end

# 프로필에서 채팅 시작
post "profiles/:id/start_chat", to: "chat_rooms#create", as: :start_chat
```

### 2.2 컨트롤러

**app/controllers/chat_rooms_controller.rb**
```ruby
class ChatRoomsController < ApplicationController
  before_action :require_login
  before_action :set_chat_room, only: [:show]

  def index
    @chat_rooms = current_user.chat_rooms
                              .includes(:users, :messages)
                              .order(last_message_at: :desc)
  end

  def show
    # 권한 확인
    unless @chat_room.users.include?(current_user)
      redirect_to chat_rooms_path, alert: "접근 권한이 없습니다."
      return
    end

    # 읽음 처리
    @participant = @chat_room.participants.find_by(user: current_user)
    @participant.mark_as_read!

    @messages = @chat_room.messages.includes(:sender).order(:created_at)
    @other_user = @chat_room.other_participant(current_user)
  end

  def create
    other_user = User.find(params[:user_id] || params[:id])
    @chat_room = ChatRoom.find_or_create_between(current_user, other_user)
    redirect_to @chat_room
  end

  private

  def set_chat_room
    @chat_room = ChatRoom.find(params[:id])
  end
end
```

**app/controllers/messages_controller.rb**
```ruby
class MessagesController < ApplicationController
  before_action :require_login

  def create
    @chat_room = ChatRoom.find(params[:chat_room_id])

    # 권한 확인
    unless @chat_room.users.include?(current_user)
      head :forbidden
      return
    end

    @message = @chat_room.messages.build(message_params)
    @message.sender = current_user

    if @message.save
      # Turbo Stream 응답
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @chat_room }
      end
    else
      head :unprocessable_entity
    end
  end

  private

  def message_params
    params.require(:message).permit(:content)
  end
end
```

---

## Phase 3: 뷰 & UI (Day 3)

### 3.1 채팅방 목록

**app/views/chat_rooms/index.html.erb**
```erb
<div class="flex flex-col h-[calc(100vh-128px)] bg-background">
  <header class="p-4 border-b border-divider">
    <h1 class="text-lg font-bold">메시지</h1>
  </header>

  <div class="flex-1 overflow-y-auto">
    <% if @chat_rooms.any? %>
      <div class="divide-y divide-divider">
        <% @chat_rooms.each do |room| %>
          <%= render "chat_rooms/chat_room_item", room: room %>
        <% end %>
      </div>
    <% else %>
      <div class="flex flex-col items-center justify-center h-full text-muted">
        <svg class="w-16 h-16 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"/>
        </svg>
        <p>아직 대화가 없습니다</p>
        <p class="text-sm mt-1">프로필에서 대화를 시작해보세요</p>
      </div>
    <% end %>
  </div>
</div>
```

### 3.2 채팅방 상세 (메시지 화면)

**app/views/chat_rooms/show.html.erb**
```erb
<div class="flex flex-col h-[calc(100vh-64px)] bg-background"
     data-controller="chat-room"
     data-chat-room-room-id-value="<%= @chat_room.id %>">

  <!-- 헤더 -->
  <header class="flex items-center gap-3 p-4 border-b border-divider bg-surface">
    <%= link_to chat_rooms_path, class: "text-muted hover:text-foreground" do %>
      <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/>
      </svg>
    <% end %>

    <%= link_to profile_path(@other_user), class: "flex items-center gap-3 flex-1" do %>
      <%= render "shared/avatar", user: @other_user, size: "md" %>
      <div>
        <p class="font-medium"><%= @other_user.name %></p>
        <p class="text-xs text-muted"><%= @other_user.role_title %></p>
      </div>
    <% end %>
  </header>

  <!-- 메시지 영역 -->
  <div id="messages"
       class="flex-1 overflow-y-auto p-4 space-y-3"
       data-chat-room-target="messages">
    <%= turbo_stream_from @chat_room %>
    <%= render @messages %>
  </div>

  <!-- 입력 영역 -->
  <div class="p-4 border-t border-divider bg-surface safe-area-bottom">
    <%= form_with model: [@chat_room, Message.new],
                  data: { controller: "message-form", action: "turbo:submit-end->message-form#reset" },
                  class: "flex gap-2" do |f| %>
      <%= f.text_area :content,
                      placeholder: "메시지를 입력하세요...",
                      rows: 1,
                      class: "flex-1 px-4 py-2 rounded-full border border-divider bg-background resize-none focus:outline-none focus:ring-2 focus:ring-primary",
                      data: { message_form_target: "input", action: "keydown.ctrl+enter->message-form#submit" } %>
      <%= f.submit "전송",
                   class: "px-4 py-2 bg-primary text-white rounded-full font-medium hover:bg-primary/90 transition" %>
    <% end %>
  </div>
</div>
```

### 3.3 메시지 Partial

**app/views/messages/_message.html.erb**
```erb
<%
  is_mine = message.sender_id == current_user.id
  bubble_class = is_mine ? "bg-primary text-white ml-auto" : "bg-muted/20 text-foreground mr-auto"
  container_class = is_mine ? "justify-end" : "justify-start"
%>

<div id="<%= dom_id(message) %>" class="flex <%= container_class %>">
  <% unless is_mine %>
    <%= link_to profile_path(message.sender), class: "flex-shrink-0 mr-2" do %>
      <%= render "shared/avatar", user: message.sender, size: "sm" %>
    <% end %>
  <% end %>

  <div class="max-w-[70%]">
    <div class="<%= bubble_class %> px-4 py-2 rounded-2xl">
      <p class="whitespace-pre-wrap break-words"><%= message.content %></p>
    </div>
    <p class="text-xs text-muted mt-1 <%= is_mine ? 'text-right' : 'text-left' %>">
      <%= message.created_at.strftime("%H:%M") %>
    </p>
  </div>
</div>
```

### 3.4 Turbo Stream 응답

**app/views/messages/create.turbo_stream.erb**
```erb
<%= turbo_stream.append "messages" do %>
  <%= render @message %>
<% end %>
```

---

## Phase 4: Stimulus 컨트롤러 & ActionCable (Day 4)

### 4.1 Stimulus 컨트롤러

**app/javascript/controllers/chat_room_controller.js**
```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messages"]
  static values = { roomId: Number }

  connect() {
    this.scrollToBottom()
    this.observeNewMessages()
  }

  scrollToBottom() {
    if (this.hasMessagesTarget) {
      this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
    }
  }

  observeNewMessages() {
    const observer = new MutationObserver(() => {
      this.scrollToBottom()
    })

    if (this.hasMessagesTarget) {
      observer.observe(this.messagesTarget, { childList: true })
    }
  }
}
```

**app/javascript/controllers/message_form_controller.js**
```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  submit(event) {
    if (event.key === "Enter" && event.ctrlKey) {
      event.preventDefault()
      this.element.requestSubmit()
    }
  }

  reset() {
    if (this.hasInputTarget) {
      this.inputTarget.value = ""
      this.inputTarget.style.height = "auto"
    }
  }
}
```

### 4.2 ActionCable 채널 (선택적 - Turbo Streams로 대체 가능)

이 프로젝트는 Turbo Streams의 브로드캐스트 기능을 활용하므로 별도 ActionCable 채널 없이도 실시간 기능 구현 가능.

---

## Phase 5: 안읽은 메시지 뱃지 (Day 5)

### 5.1 네비게이션 뱃지

**app/views/shared/_bottom_nav.html.erb 수정**
```erb
<%= link_to chat_rooms_path, class: nav_link_class("chat_rooms") do %>
  <div class="relative">
    <svg class="w-6 h-6" ...><!-- 채팅 아이콘 --></svg>
    <%= turbo_stream_from "user_#{current_user.id}_chat_badge" %>
    <div id="chat_unread_badge">
      <%= render "shared/chat_unread_badge", count: current_user.total_unread_messages %>
    </div>
  </div>
  <span class="text-xs mt-1">메시지</span>
<% end %>
```

**app/views/shared/_chat_unread_badge.html.erb**
```erb
<% if count > 0 %>
  <span class="absolute -top-1 -right-1 bg-red-500 text-white text-xs rounded-full w-5 h-5 flex items-center justify-center">
    <%= count > 99 ? "99+" : count %>
  </span>
<% end %>
```

---

## 수정 대상 파일 목록

### 새로 생성할 파일
1. `db/migrate/YYYYMMDD_create_chat_rooms.rb`
2. `db/migrate/YYYYMMDD_create_chat_room_participants.rb`
3. `db/migrate/YYYYMMDD_create_messages.rb`
4. `app/models/chat_room.rb`
5. `app/models/chat_room_participant.rb`
6. `app/models/message.rb`
7. `app/controllers/chat_rooms_controller.rb`
8. `app/controllers/messages_controller.rb`
9. `app/views/chat_rooms/index.html.erb`
10. `app/views/chat_rooms/show.html.erb`
11. `app/views/chat_rooms/_chat_room_item.html.erb`
12. `app/views/messages/_message.html.erb`
13. `app/views/messages/create.turbo_stream.erb`
14. `app/views/shared/_chat_unread_badge.html.erb`
15. `app/javascript/controllers/chat_room_controller.js`
16. `app/javascript/controllers/message_form_controller.js`

### 수정할 파일
1. `app/models/user.rb` - 채팅 관계 추가
2. `config/routes.rb` - 채팅 라우트 추가
3. `app/views/shared/_bottom_nav.html.erb` - 채팅 링크 & 뱃지 추가
4. `app/views/profiles/show.html.erb` - "대화하기" 버튼 추가

---

## 구현 순서 체크리스트

### Day 1: 데이터베이스 & 모델
- [ ] 마이그레이션 3개 생성 및 실행
- [ ] ChatRoom 모델 생성
- [ ] ChatRoomParticipant 모델 생성
- [ ] Message 모델 생성
- [ ] User 모델에 관계 추가
- [ ] 모델 테스트 작성

### Day 2: 컨트롤러 & 라우팅
- [ ] routes.rb에 채팅 라우트 추가
- [ ] ChatRoomsController 생성
- [ ] MessagesController 생성
- [ ] 컨트롤러 테스트 작성

### Day 3: 뷰 & UI
- [ ] 채팅방 목록 뷰 생성
- [ ] 채팅방 상세 뷰 생성
- [ ] 메시지 partial 생성
- [ ] Turbo Stream 뷰 생성
- [ ] 하단 네비게이션에 채팅 링크 추가

### Day 4: 실시간 기능
- [ ] Stimulus 컨트롤러 생성 (chat_room, message_form)
- [ ] Turbo Streams 브로드캐스트 설정
- [ ] 자동 스크롤 구현

### Day 5: 안읽은 메시지 & 마무리
- [ ] 안읽은 메시지 카운트 로직
- [ ] 뱃지 UI 구현
- [ ] 프로필 페이지에 "대화하기" 버튼 추가
- [ ] 전체 테스트 및 버그 수정

---

## 보안 고려사항

1. **접근 제어**: 채팅방 참여자만 메시지 조회/전송 가능
2. **입력 검증**: 메시지 내용 길이 제한 (2000자)
3. **XSS 방지**: ERB 자동 이스케이핑 활용
4. **Rate Limiting**: 메시지 전송 속도 제한 (선택적)
5. **CSRF**: Rails 기본 보호 활용

---

## 테스트 계획

1. **모델 테스트**
   - ChatRoom.find_or_create_between 로직
   - 안읽은 메시지 카운트
   - 읽음 처리

2. **컨트롤러 테스트**
   - 인증/인가 확인
   - 채팅방 생성
   - 메시지 전송

3. **시스템 테스트**
   - 채팅 시작 → 메시지 전송 → 실시간 수신 플로우
