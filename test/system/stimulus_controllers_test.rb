# frozen_string_literal: true

require "application_system_test_case"

# Stimulus 컨트롤러 System Test
#
# 테스트 대상 (수정된 파일):
# - confirm_controller.js: bind() 패턴 수정 (메모리 누수 방지)
# - image_carousel_controller.js: bind() 패턴 수정
# - _search_modal.html.erb: keydown.escape → keydown.esc
#
# CI 안정성 패턴 적용:
# - window.confirm 스텁
# - KeyboardEvent 디스패치
# - [data-controller] 대기
# - SecureRandom.hex(4) 유니크 데이터
# - page.execute_script 클릭
#
class StimulusControllersTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    @post = posts(:one)
  end

  # ============================================================
  # Phase 1: confirm_controller.js 테스트
  # ============================================================

  test "삭제 확인 다이얼로그 수락 시 게시글 삭제됨" do
    # 삭제할 새 게시글 생성 (다른 테스트에 영향 없도록)
    deletable_post = Post.create!(
      user: @user,
      title: "삭제 테스트 #{SecureRandom.hex(4)}",
      content: "삭제될 게시글입니다",
      status: :published,
      category: :free
    )

    log_in_as(@user)
    visit post_path(deletable_post)

    # confirm() 스텁: 수락 시뮬레이션
    page.execute_script("window.confirm = () => true")

    # 삭제 버튼 찾기 (button_to helper는 form > button 구조 생성)
    # confirm 컨트롤러가 form에 연결됨
    delete_form = find("form[data-controller='confirm']", wait: 5)
    delete_button = delete_form.find("button")
    page.execute_script("arguments[0].click()", delete_button)

    # 게시글 목록으로 리다이렉트 확인
    assert_current_path posts_path, wait: 10

    # 게시글이 삭제되었는지 확인
    assert_no_text deletable_post.title
  end

  test "삭제 확인 다이얼로그 취소 시 게시글 유지됨" do
    log_in_as(@user)
    visit post_path(@post)

    # 페이지 로드 대기
    assert_text @post.title, wait: 5

    # confirm() 스텁: 취소 시뮬레이션
    page.execute_script("window.confirm = () => false")

    # 삭제 버튼 찾기 (button_to helper는 form > button 구조 생성)
    delete_form = find("form[data-controller='confirm']", wait: 5)
    delete_button = delete_form.find("button")
    page.execute_script("arguments[0].click()", delete_button)

    # 짧은 대기 후 페이지 유지 확인
    sleep 0.5

    # 동일 페이지에 머물러 있는지 확인
    assert_current_path post_path(@post)
    assert_text @post.title
  end

  # ============================================================
  # Phase 2: image_carousel_controller.js 테스트
  # ============================================================

  test "이미지 캐러셀 다음 버튼 클릭 시 슬라이드 변경" do
    post_with_images = create_post_with_images(3)

    visit post_path(post_with_images)

    # 캐러셀 컨트롤러 로드 대기
    assert_selector "[data-controller='image-carousel']", wait: 5

    # 초기 카운터 확인 (1)
    assert_selector "[data-image-carousel-target='current']", text: "1", wait: 3

    # 다음 버튼 클릭
    next_button = find("[data-image-carousel-target='nextButton']", wait: 3)
    next_button.click

    # 카운터 변경 확인 (2)
    assert_selector "[data-image-carousel-target='current']", text: "2", wait: 3
  end

  test "이미지 캐러셀 이전 버튼 클릭 시 슬라이드 변경" do
    post_with_images = create_post_with_images(3)

    visit post_path(post_with_images)

    assert_selector "[data-controller='image-carousel']", wait: 5

    # 먼저 다음으로 이동
    find("[data-image-carousel-target='nextButton']").click
    assert_selector "[data-image-carousel-target='current']", text: "2", wait: 3

    # 이전으로 돌아가기
    find("[data-image-carousel-target='prevButton']").click
    assert_selector "[data-image-carousel-target='current']", text: "1", wait: 3
  end

  test "이미지 캐러셀 인디케이터 클릭 시 해당 슬라이드로 이동" do
    post_with_images = create_post_with_images(3)

    visit post_path(post_with_images)

    assert_selector "[data-controller='image-carousel']", wait: 5

    # 세 번째 인디케이터 클릭
    indicators = all("[data-image-carousel-target='indicator']")
    indicators[2].click

    # 카운터 확인 (3)
    assert_selector "[data-image-carousel-target='current']", text: "3", wait: 3
  end

  # ============================================================
  # Phase 3: search_modal ESC 키 테스트
  # ============================================================

  test "Cmd+K로 검색 모달 열기" do
    visit root_path

    # 페이지 로드 대기
    assert_selector "body", wait: 5

    # Cmd+K 시뮬레이션
    page.execute_script(<<~JS)
      document.dispatchEvent(new KeyboardEvent('keydown', {
        key: 'k',
        metaKey: true,
        bubbles: true
      }));
    JS

    # 모달 오버레이 표시 확인
    assert_selector "[data-search-modal-target='overlay']:not(.hidden)", wait: 3
  end

  test "ESC 키로 검색 모달 닫기 (keydown.esc 액션 검증)" do
    visit root_path

    assert_selector "body", wait: 5

    # 모달 열기
    page.execute_script(<<~JS)
      document.dispatchEvent(new KeyboardEvent('keydown', {
        key: 'k',
        metaKey: true,
        bubbles: true
      }));
    JS

    # 모달 열림 확인
    assert_selector "[data-search-modal-target='overlay']:not(.hidden)", wait: 3

    # ESC 키로 닫기 (input에서 keydown.esc 액션 트리거)
    page.execute_script(<<~JS)
      const input = document.querySelector("[data-search-modal-target='input']");
      if (input) {
        input.focus();
        input.dispatchEvent(new KeyboardEvent('keydown', {
          key: 'Escape',
          keyCode: 27,
          code: 'Escape',
          bubbles: true
        }));
      }
    JS

    # 모달 닫힘 확인 (hidden 클래스 또는 opacity-0)
    assert_selector "[data-search-modal-target='overlay'].hidden, [data-search-modal-target='overlay'].opacity-0", wait: 3
  end

  test "ESC 버튼 클릭으로 검색 모달 닫기" do
    visit root_path

    assert_selector "body", wait: 5

    # 모달 열기
    page.execute_script(<<~JS)
      document.dispatchEvent(new KeyboardEvent('keydown', {
        key: 'k',
        metaKey: true,
        bubbles: true
      }));
    JS

    assert_selector "[data-search-modal-target='overlay']:not(.hidden)", wait: 3

    # ESC 버튼 클릭
    click_button "ESC"

    # 모달 닫힘 확인
    assert_selector "[data-search-modal-target='overlay'].hidden, [data-search-modal-target='overlay'].opacity-0", wait: 3
  end

  private

  # 다중 이미지 게시글 생성 헬퍼
  def create_post_with_images(count = 3)
    post = Post.create!(
      user: @user,
      title: "이미지 캐러셀 테스트 #{SecureRandom.hex(4)}",
      content: "테스트용 게시글입니다",
      status: :published,
      category: :free
    )

    count.times do |i|
      post.images.attach(
        io: File.open(Rails.root.join("test/fixtures/files/test_image.png")),
        filename: "carousel_#{i}.png",
        content_type: "image/png"
      )
    end

    post
  end
end
