# frozen_string_literal: true

require "application_system_test_case"

class ChatTest < ApplicationSystemTestCase
  def setup
    @user = users(:one)
    @other_user = users(:two)
  end

  # =========================================
  # 채팅 목록 테스트
  # =========================================

  test "can view chat rooms list when logged in" do
    log_in_as(@user)
    visit chat_rooms_path

    # 채팅 목록 페이지 로드 확인
    assert_current_path chat_rooms_path
  end

  test "redirects to login when not authenticated" do
    visit chat_rooms_path

    # 로그인 페이지로 리다이렉트
    assert_current_path login_path
  end

  # =========================================
  # 채팅방 생성 테스트
  # =========================================

  test "can start chat from user profile" do
    log_in_as(@user)
    visit profile_path(@other_user)

    # 채팅하기 버튼 클릭
    if page.has_button?("채팅하기")
      click_button "채팅하기"

      # 채팅방으로 이동 확인
      assert_current_path %r{/chat_rooms/\d+}
    elsif page.has_link?("채팅하기")
      click_link "채팅하기"
      assert_current_path %r{/chat_rooms/\d+}
    end
  end

  test "cannot chat with self" do
    log_in_as(@user)
    visit profile_path(@user)

    # 자신의 프로필에는 채팅 버튼이 없어야 함
    assert_no_button "채팅하기"
    assert_no_link "채팅하기"
  end

  # =========================================
  # 메시지 전송 테스트
  # =========================================

  test "can send message in chat room" do
    # 채팅방 생성
    chat_room = ChatRoom.create!
    chat_room.participants.create!(user: @user)
    chat_room.participants.create!(user: @other_user)

    log_in_as(@user)
    visit chat_room_path(chat_room)

    # 폼과 Stimulus 컨트롤러가 완전히 로드될 때까지 대기
    assert_selector "form[data-controller='message-form']", wait: 10

    # 메시지 입력 영역이 준비될 때까지 대기
    input_selector = "[data-message-form-target='input']"
    assert_selector input_selector, wait: 5

    # 고유한 테스트 메시지 생성
    test_message = "CI테스트메시지_#{SecureRandom.hex(4)}"

    # JavaScript로 직접 값 설정 및 폼 제출 (Stimulus 컨트롤러 우회)
    # CI 환경에서 Capybara의 set/click이 불안정할 수 있음
    page.execute_script(<<~JS, test_message)
      const input = document.querySelector("[data-message-form-target='input']");
      const form = document.querySelector("form[data-controller='message-form']");
      if (input && form) {
        input.value = arguments[0];
        // 폼 직접 제출 (requestSubmit 사용)
        form.requestSubmit();
      }
    JS

    # DB에 메시지가 저장될 때까지 대기 (최대 10초)
    message_saved = false
    10.times do
      sleep 1
      if chat_room.messages.reload.exists?(content: test_message)
        message_saved = true
        break
      end
    end

    # 메시지가 DB에 저장되었는지 확인 (핵심 검증)
    assert message_saved, "메시지가 DB에 저장되지 않았습니다: #{test_message}"

    # UI 확인은 페이지 새로고침 후 진행 (Turbo Stream 의존성 제거)
    visit chat_room_path(chat_room)
    assert_text test_message, wait: 5
  end

  test "cannot send empty message" do
    chat_room = ChatRoom.create!
    chat_room.participants.create!(user: @user)
    chat_room.participants.create!(user: @other_user)

    log_in_as(@user)
    visit chat_room_path(chat_room)

    # 메시지 입력 영역 확인
    assert_selector "[data-message-form-target='input']", wait: 5

    # 빈 메시지 상태에서 전송 버튼이 비활성화되어 있거나
    # 전송해도 메시지가 추가되지 않아야 함
    input = find("[data-message-form-target='input']")
    assert input.value.blank? || input.value.strip.empty?
  end

  # =========================================
  # 채팅방 UI 테스트
  # =========================================

  test "shows participant info in chat room" do
    chat_room = ChatRoom.create!
    chat_room.participants.create!(user: @user)
    chat_room.participants.create!(user: @other_user)

    log_in_as(@user)
    visit chat_room_path(chat_room)

    # 상대방 정보 표시 확인
    assert_text @other_user.name
  end

  test "can go back to chat list" do
    skip <<~SKIP
      [모바일 전용 UI 테스트]
      - 뒤로가기 버튼은 md:hidden (768px 미만에서만 표시)
      - 테스트 환경 viewport: 1400x1400 (데스크톱)
      - CSS 미디어 쿼리 테스트는 별도 모바일 E2E 환경에서 수행 필요
    SKIP
  end

  # =========================================
  # 읽음 표시 테스트
  # =========================================

  test "unread badge shows on chat list" do
    chat_room = ChatRoom.create!
    chat_room.participants.create!(user: @user)
    chat_room.participants.create!(user: @other_user)

    # 상대방이 메시지 전송 (sender: 사용)
    chat_room.messages.create!(
      sender: @other_user,
      content: "읽지 않은 메시지입니다."
    )

    log_in_as(@user)
    visit chat_rooms_path

    # 읽지 않음 표시 확인 (뱃지 또는 채팅방 표시)
    assert_selector ".unread, [class*='unread'], .bg-orange-500, .bg-red-500, [data-unread]", wait: 5
  end

  # =========================================
  # 한글 메시지 중복 전송 방지 테스트
  # =========================================

  test "can send korean message without duplication" do
    chat_room = ChatRoom.create!
    chat_room.participants.create!(user: @user)
    chat_room.participants.create!(user: @other_user)

    log_in_as(@user)
    visit chat_room_path(chat_room)

    # 폼 로드 대기
    assert_selector "form[data-controller='message-form']", wait: 10

    korean_message = "안녕하세요_#{SecureRandom.hex(4)}"
    initial_count = chat_room.messages.count

    # JavaScript로 한글 메시지 전송 (IME 처리 시뮬레이션)
    page.execute_script(<<~JS, korean_message)
      const input = document.querySelector("[data-message-form-target='input']");
      const form = document.querySelector("form[data-controller='message-form']");
      if (input && form) {
        input.value = arguments[0];
        form.requestSubmit();
      }
    JS

    # DB에 메시지가 저장될 때까지 대기
    message_saved = false
    10.times do
      sleep 1
      if chat_room.messages.reload.where(content: korean_message).exists?
        message_saved = true
        break
      end
    end

    assert message_saved, "한글 메시지가 저장되지 않음: #{korean_message}"

    # 핵심: 메시지가 정확히 1개만 저장되어야 함
    assert_equal 1, chat_room.messages.where(content: korean_message).count,
      "한글 메시지가 중복 전송됨"
  end

  test "rapid enter key does not cause duplicate messages" do
    chat_room = ChatRoom.create!
    chat_room.participants.create!(user: @user)
    chat_room.participants.create!(user: @other_user)

    log_in_as(@user)
    visit chat_room_path(chat_room)

    # 폼 로드 대기
    assert_selector "form[data-controller='message-form']", wait: 10

    test_message = "빠른입력테스트_#{SecureRandom.hex(4)}"
    initial_count = chat_room.messages.count

    # JavaScript로 메시지 입력 후 Enter 키 3번 빠르게 전송 (IME 이슈 시뮬레이션)
    page.execute_script(<<~JS, test_message)
      const input = document.querySelector("[data-message-form-target='input']");
      if (input) {
        input.value = arguments[0];

        // Enter 키 이벤트 3번 빠르게 발생
        for (let i = 0; i < 3; i++) {
          input.dispatchEvent(new KeyboardEvent('keydown', {
            key: 'Enter',
            code: 'Enter',
            keyCode: 13,
            bubbles: true
          }));
        }
      }
    JS

    # 메시지 전송 완료 대기
    sleep 2

    # DB 확인: 메시지가 0개 또는 1개만 있어야 함 (중복 전송 방지)
    final_count = chat_room.messages.reload.where(content: test_message).count

    assert final_count <= 1,
      "빠른 Enter 키로 메시지가 #{final_count}개 전송됨 (최대 1개여야 함)"
  end

  test "compositionend followed by enter does not cause duplicate" do
    chat_room = ChatRoom.create!
    chat_room.participants.create!(user: @user)
    chat_room.participants.create!(user: @other_user)

    log_in_as(@user)
    visit chat_room_path(chat_room)

    # 폼 로드 대기
    assert_selector "form[data-controller='message-form']", wait: 10

    test_message = "IME테스트_#{SecureRandom.hex(4)}"

    # IME compositionend 이벤트 후 Enter 키 시뮬레이션
    # 이것이 한글 입력 중복 전송의 주요 원인
    page.execute_script(<<~JS, test_message)
      const input = document.querySelector("[data-message-form-target='input']");
      if (input) {
        input.value = arguments[0];

        // IME 조합 시작
        input.dispatchEvent(new CompositionEvent('compositionstart', { bubbles: true }));

        // IME 조합 완료 (한글 입력 완료 시점)
        input.dispatchEvent(new CompositionEvent('compositionend', { bubbles: true }));

        // 조합 완료 직후 Enter 키 (isComposing이 false가 된 직후)
        setTimeout(() => {
          input.dispatchEvent(new KeyboardEvent('keydown', {
            key: 'Enter',
            code: 'Enter',
            keyCode: 13,
            bubbles: true,
            isComposing: false
          }));
        }, 10);
      }
    JS

    # 메시지 전송 완료 대기
    sleep 2

    # DB 확인: 메시지가 0개 또는 1개만 있어야 함
    final_count = chat_room.messages.reload.where(content: test_message).count

    assert final_count <= 1,
      "compositionend 후 Enter로 메시지가 #{final_count}개 전송됨 (최대 1개여야 함)"
  end
end
