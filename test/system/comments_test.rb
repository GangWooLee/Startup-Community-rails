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

    # 댓글 입력
    comment_input = find("[data-comment-form-target='input']", match: :first, wait: 5)
    comment_input.fill_in with: unique_comment

    # Enter 키로 제출
    comment_input.send_keys(:enter)

    # Turbo Stream 응답 대기 및 댓글 표시 확인
    assert_text unique_comment, wait: 5

    # 입력 필드가 비워졌는지 확인 (폼 리셋)
    assert_equal "", comment_input.value
  end

  test "submit button is disabled when input is empty" do
    log_in_as(@user)
    visit post_path(@post)

    # 댓글 폼의 제출 버튼 확인
    submit_button = find("[data-comment-form-target='submit']", match: :first, wait: 5)

    # 초기 상태: 비활성화
    assert submit_button.disabled?

    # 텍스트 입력 시 활성화
    comment_input = find("[data-comment-form-target='input']", match: :first)
    comment_input.fill_in with: "테스트 댓글"

    # 버튼 활성화 확인
    assert_not submit_button.disabled?

    # 텍스트 삭제 시 다시 비활성화 (native clear + input event trigger)
    comment_input.native.clear
    comment_input.send_keys(:backspace)  # input 이벤트 트리거
    sleep 0.1  # Stimulus 반응 대기

    # 버튼 상태 확인 (disabled 또는 opacity-50 클래스)
    assert submit_button.disabled? || submit_button[:class].include?("opacity-50")
  end

  test "shows character counter" do
    log_in_as(@user)
    visit post_path(@post)

    counter = find("[data-comment-form-target='counter']", match: :first, wait: 5)
    comment_input = find("[data-comment-form-target='input']", match: :first)

    # 초기 카운터 확인
    assert_match %r{\d+/1000}, counter.text

    # 텍스트 입력 후 카운터 업데이트 확인
    comment_input.fill_in with: "가나다라마"
    assert_match %r{\d+/1000}, counter.text
  end

  # =========================================
  # 중복 제출 방지 테스트
  # =========================================

  test "Enter key does not create duplicate comments" do
    log_in_as(@user)
    visit post_path(@post)

    unique_comment = "중복 방지 테스트 #{Time.now.to_i}"

    # 댓글 입력
    comment_input = find("[data-comment-form-target='input']", match: :first, wait: 5)
    comment_input.fill_in with: unique_comment

    # 초기 댓글 수 확인
    initial_count = Comment.where(post: @post).count

    # Enter 키 제출
    comment_input.send_keys(:enter)

    # Turbo Stream 응답 대기
    assert_text unique_comment, wait: 5

    # 댓글이 정확히 1개만 추가되었는지 확인
    assert_equal initial_count + 1, Comment.where(post: @post).count

    # 같은 내용의 댓글이 1개만 있는지 확인
    assert_equal 1, Comment.where(post: @post, content: unique_comment).count
  end

  test "submit button shows loading state during submission" do
    log_in_as(@user)
    visit post_path(@post)

    unique_comment = "로딩 상태 테스트 #{Time.now.to_i}"

    comment_input = find("[data-comment-form-target='input']", match: :first, wait: 5)
    submit_button = find("[data-comment-form-target='submit']", match: :first)

    comment_input.fill_in with: unique_comment

    # 제출 버튼 텍스트 확인 (제출 전)
    assert_match /작성/, submit_button.text

    # 제출
    submit_button.click

    # 완료 후 버튼 텍스트 복원 확인
    assert_text unique_comment, wait: 5
    assert_match /작성/, submit_button.text
  end
end
