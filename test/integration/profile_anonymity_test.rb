# frozen_string_literal: true

require "test_helper"

class ProfileAnonymityTest < ActionDispatch::IntegrationTest
  fixtures :users, :posts

  TEST_PASSWORD = "test1234"

  setup do
    @anonymous_user = users(:one)
    @anonymous_user.update!(
      profile_completed: true,
      is_anonymous: true,
      nickname: "익명개발자",
      avatar_type: 2
    )

    @real_name_user = users(:two)
    @real_name_user.update!(
      profile_completed: true,
      is_anonymous: false,
      nickname: "실명닉네임"
    )

    @other_user = users(:three)
    @other_user.update!(
      profile_completed: true,
      is_anonymous: false,
      nickname: "다른유저"
    )
  end

  # =========================================
  # Profile Page Tests
  # =========================================

  test "anonymous user profile shows nickname to other users" do
    log_in_as(@other_user)

    get profile_path(@anonymous_user)
    assert_response :success

    # 닉네임이 표시되어야 함 (h1 태그에서)
    assert_select "h1", text: /익명개발자/
    # 실명은 표시되지 않아야 함
    assert_select "h1", text: @anonymous_user.name, count: 0
  end

  test "anonymous user profile shows limited info to others" do
    log_in_as(@other_user)

    get profile_path(@anonymous_user)
    assert_response :success

    # "익명 사용자" 표시 확인
    assert_match /익명 사용자/, response.body
  end

  test "anonymous user can see own full profile" do
    log_in_as(@anonymous_user)

    get my_page_path
    assert_response :success
    # 본인 페이지에서는 설정 변경 가능해야 함
  end

  test "real name user profile shows actual name" do
    log_in_as(@other_user)

    get profile_path(@real_name_user)
    assert_response :success

    # 실제 이름이 표시되어야 함 (h1 태그에서)
    assert_select "h1", text: /#{@real_name_user.name}/
  end

  # =========================================
  # Post Author Display Tests
  # =========================================

  test "post shows anonymous author nickname" do
    post_record = posts(:one)
    post_record.update!(user: @anonymous_user)

    get post_path(post_record)
    assert_response :success

    # 익명 닉네임이 표시되어야 함
    assert_match /익명개발자/, response.body
  end

  test "post shows real author name when not anonymous" do
    post_record = posts(:one)
    post_record.update!(user: @real_name_user)

    get post_path(post_record)
    assert_response :success

    # 실명이 표시되어야 함
    assert_match /#{@real_name_user.name}/, response.body
  end

  # =========================================
  # Community Feed Tests
  # =========================================

  test "community feed shows anonymous author correctly" do
    log_in_as(@other_user)  # 로그인 필요

    post_record = posts(:one)
    post_record.update!(user: @anonymous_user, category: :free)

    get community_path
    assert_response :success

    # 피드에서도 익명 닉네임 표시
    assert_match /익명개발자/, response.body
  end

  # =========================================
  # Guest User Tests
  # =========================================

  test "guest can view anonymous user profile" do
    get profile_path(@anonymous_user)
    assert_response :success

    # 익명 닉네임 표시
    assert_match /익명개발자/, response.body
    # 실명 미표시
    assert_no_match /#{@anonymous_user.name}/, response.body
  end

  # =========================================
  # State Transition Tests
  # =========================================

  test "existing posts show new display name after user switches to anonymous" do
    post_record = posts(:one)
    post_record.update!(user: @real_name_user)

    # 처음에는 실명 표시
    get post_path(post_record)
    assert_match /#{@real_name_user.name}/, response.body

    # 사용자가 익명으로 전환
    @real_name_user.update!(is_anonymous: true, nickname: "전환된익명")

    # 같은 게시글에서 이제 익명 닉네임 표시
    get post_path(post_record)
    assert_match /전환된익명/, response.body
    assert_no_match /#{@real_name_user.reload.name}/, response.body
  end

  test "existing posts show real name after user switches from anonymous" do
    post_record = posts(:one)
    post_record.update!(user: @anonymous_user)

    # 처음에는 익명 닉네임 표시
    get post_path(post_record)
    assert_match /익명개발자/, response.body

    # 사용자가 실명으로 전환
    @anonymous_user.update!(is_anonymous: false)

    # 같은 게시글에서 이제 실명 표시
    get post_path(post_record)
    assert_match /#{@anonymous_user.name}/, response.body
  end

  private

  def log_in_as(user)
    post login_path, params: {
      email: user.email,
      password: TEST_PASSWORD
    }
  end
end
