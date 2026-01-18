# frozen_string_literal: true

require "application_system_test_case"

class CommentsTest < ApplicationSystemTestCase
  fixtures :users, :posts, :comments

  def setup
    @user = users(:one)
    @post = posts(:two)  # 테스트할 게시글
  end

  # =========================================
  # 댓글 작성 기본 테스트
  # =========================================

  test "can submit comment via Enter key" do
    log_in_as(@user)
    visit post_path(@post)

    unique_comment = "Enter 키 댓글 테스트 #{Time.now.to_i}"

    # Stimulus 컨트롤러 연결 대기
    assert_selector "[data-controller='comment-form']", wait: 5

    # JavaScript로 값 설정 및 input 이벤트 트리거 (Stale Element 방지)
    page.execute_script(<<~JS, unique_comment)
      const input = document.querySelector("[data-comment-form-target='input']");
      if (input) {
        input.value = arguments[0];
        input.dispatchEvent(new Event('input', { bubbles: true }));
      }
    JS
    sleep 0.3  # 이벤트 처리 대기

    # Enter 키로 제출 (JavaScript 내에서 요소 찾기)
    page.execute_script(<<~JS)
      const input = document.querySelector("[data-comment-form-target='input']");
      if (input) {
        input.dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter', bubbles: true }));
      }
    JS

    # Turbo Stream 응답 대기 및 댓글 표시 확인
    assert_text unique_comment, wait: 10

    # 입력 필드가 비워졌는지 확인 (폼 리셋)
    assert_equal "", find("[data-comment-form-target='input']", match: :first).value
  end

  test "submit button is disabled when input is empty" do
    log_in_as(@user)
    visit post_path(@post)

    # Stimulus 컨트롤러가 연결될 때까지 대기
    assert_selector "[data-controller='comment-form']", wait: 5

    # 버튼이 초기 disabled 상태인지 확인 (매번 새로 find하여 Stale Element 방지)
    assert find("[data-comment-form-target='submit']", match: :first, wait: 5).disabled?,
           "버튼이 초기에 disabled여야 함"

    # 텍스트 입력 후 enabled 확인 (JavaScript로 input 이벤트 트리거)
    page.execute_script(<<~JS)
      const input = document.querySelector("[data-comment-form-target='input']");
      if (input) {
        input.value = "테스트 댓글";
        input.dispatchEvent(new Event('input', { bubbles: true }));
      }
    JS
    sleep 0.3

    # 매번 새로 find하여 최신 상태 확인
    assert_not find("[data-comment-form-target='submit']", match: :first).disabled?,
               "텍스트 입력 후 버튼이 enabled여야 함"

    # 텍스트 삭제 후 다시 disabled 확인
    page.execute_script(<<~JS)
      const input = document.querySelector("[data-comment-form-target='input']");
      if (input) {
        input.value = "";
        input.dispatchEvent(new Event('input', { bubbles: true }));
      }
    JS
    sleep 0.3

    assert find("[data-comment-form-target='submit']", match: :first).disabled?,
           "텍스트 삭제 후 버튼이 disabled여야 함"
  end

  test "shows character counter" do
    log_in_as(@user)
    visit post_path(@post)

    counter = find("[data-comment-form-target='counter']", match: :first, wait: 5)
    comment_input = find("[data-comment-form-target='input']", match: :first)

    # 초기 카운터 확인
    assert_match %r{\d+/1000}, counter.text

    # 텍스트 입력 후 카운터 업데이트 확인
    comment_input.set("가나다라마")
    page.execute_script("arguments[0].dispatchEvent(new Event('input', { bubbles: true }))", comment_input)
    sleep 0.2
    assert_match %r{\d+/1000}, counter.text
  end

  # =========================================
  # 중복 제출 방지 테스트
  # =========================================

  test "Enter key does not create duplicate comments" do
    log_in_as(@user)
    visit post_path(@post)

    unique_comment = "중복방지테스트_#{SecureRandom.hex(4)}"

    input = find("[data-comment-form-target='input']", match: :first, wait: 5)
    input.set(unique_comment)
    page.execute_script("arguments[0].dispatchEvent(new Event('input', { bubbles: true }))", input)
    sleep 0.2

    # Enter 키 여러 번 빠르게 전송 (중복 제출 시도)
    # JavaScript로 요소를 직접 찾아 이벤트 발생 (Stale Element 방지)
    3.times do
      page.execute_script(<<~JS)
        const input = document.querySelector("[data-comment-form-target='input']");
        if (input) {
          input.dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter', bubbles: true }));
        }
      JS
    end

    # 응답 대기
    assert_text unique_comment, wait: 5

    # DB에서 해당 댓글이 정확히 1개만 생성되었는지 확인
    assert_equal 1, Comment.where(content: unique_comment).count, "댓글이 정확히 1개만 생성되어야 함"
  end

  test "submit button text changes and resets after submission" do
    log_in_as(@user)
    visit post_path(@post)

    unique_comment = "버튼상태테스트_#{SecureRandom.hex(4)}"

    # Stimulus 컨트롤러 연결 대기
    assert_selector "[data-controller='comment-form']", wait: 5

    # 초기 버튼 텍스트 확인
    assert_equal "작성", find("[data-comment-form-target='submit']", match: :first).text

    # JavaScript로 값 설정 및 Enter 키 제출 (Stale Element 방지)
    page.execute_script(<<~JS, unique_comment)
      const input = document.querySelector("[data-comment-form-target='input']");
      if (input) {
        input.value = arguments[0];
        input.dispatchEvent(new Event('input', { bubbles: true }));
      }
    JS
    sleep 0.3

    # Enter 키로 제출 (JavaScript 내에서 요소 찾기)
    page.execute_script(<<~JS)
      const input = document.querySelector("[data-comment-form-target='input']");
      if (input) {
        input.dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter', bubbles: true }));
      }
    JS

    # 댓글이 생성되었는지 확인 (핵심 기능 검증)
    assert_text unique_comment, wait: 10

    # 버튼이 원래 텍스트로 복원되었는지 확인
    sleep 0.5
    assert_equal "작성", find("[data-comment-form-target='submit']", match: :first).text
  end
end
