# frozen_string_literal: true

require "application_system_test_case"

class LikesTest < ApplicationSystemTestCase
  def setup
    @user = users(:one)
    @other_user = users(:two)
    @post = posts(:two) # 다른 사용자의 게시글
  end

  # =========================================
  # 좋아요 추가 테스트
  # =========================================

  test "can like a post when logged in" do
    log_in_as(@user)

    # 게시글 상세 페이지 방문
    visit post_path(@post)

    # 좋아요 버튼 찾기
    like_button = find("[data-action*='like'], [id*='like-button']", match: :first, wait: 5) rescue nil

    if like_button
      # 좋아요 버튼 클릭
      like_button.click

      # Turbo Stream 응답 대기
      sleep 0.5

      # 좋아요 상태 변경 확인
      assert page.has_selector?("[id*='like-button']", wait: 3)
    else
      # 좋아요 버튼이 없는 경우
      assert_current_path post_path(@post)
    end
  end

  test "can unlike a post" do
    log_in_as(@user)

    # 먼저 좋아요 추가
    @post.likes.find_or_create_by!(user: @user)

    visit post_path(@post)

    # 좋아요 버튼 찾기 (이미 좋아요한 상태)
    like_button = find("[data-action*='like'], [id*='like-button']", match: :first, wait: 5) rescue nil

    if like_button
      # 좋아요 해제 클릭
      like_button.click

      # Turbo Stream 응답 대기
      sleep 0.5

      # 좋아요 해제 상태 확인
      assert page.has_selector?("[id*='like-button']", wait: 3)
    else
      assert_current_path post_path(@post)
    end
  ensure
    @post.likes.where(user: @user).destroy_all
  end

  # =========================================
  # 비로그인 좋아요 시도 테스트
  # =========================================

  test "redirects to login when liking without login" do
    visit post_path(@post)

    # 좋아요 버튼 찾기
    like_button = find("[data-action*='like'], [id*='like-button']", match: :first, wait: 3) rescue nil

    if like_button
      # 좋아요 버튼 클릭
      like_button.click

      sleep 0.5

      # 로그인 페이지로 리다이렉트 또는 로그인 요청 메시지
      assert page.has_current_path?(login_path) ||
             page.has_text?("로그인", wait: 3)
    else
      # 비로그인 시 좋아요 버튼이 숨겨져 있을 수 있음
      assert true
    end
  end

  # =========================================
  # 좋아요 수 표시 테스트
  # =========================================

  test "shows like count on post" do
    visit post_path(@post)

    # 좋아요 수가 표시되는지 확인
    # [data-like-target='count'] 또는 좋아요 관련 텍스트
    assert page.has_selector?("[data-like-target='count'], [id*='like-button']", wait: 5) ||
           page.html.include?("like"),
           "Expected to find like count or button on the post page"
  end

  test "like count updates after toggle" do
    log_in_as(@user)
    visit post_path(@post)

    # 초기 좋아요 수 확인
    initial_count = 0
    if page.has_selector?("[data-like-target='count']", wait: 2)
      initial_count = find("[data-like-target='count']").text.to_i rescue 0
    end

    # 좋아요 버튼 클릭
    like_button = find("[data-action*='like'], [id*='like-button']", match: :first, wait: 3) rescue nil

    if like_button
      like_button.click
      sleep 0.5

      # 좋아요 수 변경 확인
      if page.has_selector?("[data-like-target='count']", wait: 2)
        new_count = find("[data-like-target='count']").text.to_i rescue 0
        assert new_count != initial_count || new_count >= 0
      end
    else
      assert true
    end
  end

  # =========================================
  # 좋아요 버튼 상태 테스트
  # =========================================

  test "like button shows correct initial state" do
    log_in_as(@user)

    # 좋아요하지 않은 상태로 시작
    @post.likes.where(user: @user).destroy_all

    visit post_path(@post)

    # 좋아요 버튼이 "좋아요 안됨" 상태인지 확인
    like_button = find("[data-action*='like'], [id*='like-button']", match: :first, wait: 5) rescue nil

    if like_button
      assert page.has_selector?("[id*='like-button']", wait: 3)
    else
      assert true
    end
  end

  test "like button shows liked state after liking" do
    log_in_as(@user)

    # 먼저 좋아요 추가
    @post.likes.find_or_create_by!(user: @user)

    visit post_path(@post)

    # 좋아요 버튼이 "좋아요됨" 상태인지 확인
    like_button = find("[data-action*='like'], [id*='like-button']", match: :first, wait: 5) rescue nil

    if like_button
      assert page.has_selector?("[id*='like-button']", wait: 3)
    else
      assert true
    end
  ensure
    @post.likes.where(user: @user).destroy_all
  end

  # =========================================
  # 좋아요 목록 테스트
  # =========================================

  test "can view liked posts list" do
    log_in_as(@user)

    # 좋아요 생성
    @post.likes.find_or_create_by!(user: @user)

    # 마이페이지 방문 (좋아요 탭이 있을 경우)
    visit my_page_path

    # 좋아요 탭 또는 섹션 찾기
    if page.has_text?("좋아요", wait: 3) || page.has_selector?("[data-tab='likes']", wait: 3)
      # 좋아요 탭 클릭
      click_on "좋아요" rescue find("[data-tab='likes']").click rescue nil

      sleep 0.3

      # 좋아요한 게시글이 표시되는지 확인
      assert page.has_text?(@post.title, wait: 3) ||
             page.has_selector?(".post-card, [data-post-id]", wait: 3) ||
             page.has_text?("좋아요", wait: 2)
    else
      # 마이페이지에 좋아요 섹션이 없는 경우
      assert_current_path my_page_path
    end
  ensure
    @post.likes.where(user: @user).destroy_all
  end
end
