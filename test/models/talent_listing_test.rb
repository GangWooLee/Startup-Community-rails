# frozen_string_literal: true

require "test_helper"

# NOTE: TalentListing 모델은 DEPRECATED입니다.
# Post 모델의 category: :seeking으로 대체되었습니다.
# 이 테스트는 마이그레이션 완료 전까지 호환성을 위해 유지됩니다.
class TalentListingTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @talent_listing = talent_listings(:one)
  end

  # =========================================
  # Association Tests
  # =========================================

  test "should belong to user" do
    assert_respond_to @talent_listing, :user
    assert_equal @user, @talent_listing.user
  end

  test "should have many bookmarks" do
    assert_respond_to @talent_listing, :bookmarks
  end

  # =========================================
  # Validation Tests
  # =========================================

  test "should be valid with valid attributes" do
    talent = TalentListing.new(
      user: @user,
      title: "풀스택 개발자입니다",
      description: "Rails, React 경험 5년입니다.",
      category: :development,
      project_type: :long_term,
      status: :available
    )
    assert talent.valid?
  end

  test "should require title" do
    talent = TalentListing.new(
      user: @user,
      description: "설명입니다.",
      category: :development,
      project_type: :short_term
    )
    assert_not talent.valid?
    assert_includes talent.errors[:title], "can't be blank"
  end

  test "should require description" do
    talent = TalentListing.new(
      user: @user,
      title: "제목입니다",
      category: :development,
      project_type: :short_term
    )
    assert_not talent.valid?
    assert_includes talent.errors[:description], "can't be blank"
  end

  test "should enforce title maximum length" do
    talent = TalentListing.new(
      user: @user,
      title: "a" * 256,
      description: "설명입니다.",
      category: :development,
      project_type: :short_term
    )
    assert_not talent.valid?
    assert_includes talent.errors[:title], "is too long (maximum is 255 characters)"
  end

  # =========================================
  # Enum Tests
  # =========================================

  test "should have category enum" do
    assert_equal %w[development design pm marketing], TalentListing.categories.keys
  end

  test "should have project_type enum" do
    assert_equal %w[short_term long_term one_time], TalentListing.project_types.keys
  end

  test "should have status enum" do
    assert_equal %w[available unavailable], TalentListing.statuses.keys
  end

  # =========================================
  # Scope Tests
  # =========================================

  test "available scope should return only available listings" do
    @talent_listing.update!(status: :available)
    unavailable_talent = TalentListing.create!(
      user: users(:two),
      title: "구직 완료됨",
      description: "설명",
      category: :development,
      project_type: :short_term,
      status: :unavailable
    )

    available_talents = TalentListing.available
    assert_includes available_talents, @talent_listing
    assert_not_includes available_talents, unavailable_talent
  end

  test "recent scope should order by created_at desc" do
    recent_talents = TalentListing.recent.to_a
    # 최신순 정렬 확인: 각 레코드의 created_at이 다음 레코드보다 크거나 같아야 함
    recent_talents.each_cons(2) do |prev, curr|
      assert prev.created_at >= curr.created_at, "Expected #{prev.created_at} >= #{curr.created_at}"
    end
  end

  test "by_category scope should filter by category" do
    design_talents = TalentListing.by_category(:design)
    design_talents.each do |talent|
      assert_equal "design", talent.category
    end
  end

  # =========================================
  # Instance Method Tests
  # =========================================

  test "increment_views! should increase views_count" do
    initial_views = @talent_listing.views_count
    @talent_listing.increment_views!
    assert_equal initial_views + 1, @talent_listing.reload.views_count
  end

  test "category_i18n should return Korean labels" do
    @talent_listing.category = :development
    assert_equal "개발", @talent_listing.category_i18n

    @talent_listing.category = :design
    assert_equal "디자인", @talent_listing.category_i18n

    @talent_listing.category = :pm
    assert_equal "PM/기획", @talent_listing.category_i18n

    @talent_listing.category = :marketing
    assert_equal "마케팅", @talent_listing.category_i18n
  end

  test "project_type_i18n should return Korean labels" do
    @talent_listing.project_type = :short_term
    assert_equal "단기", @talent_listing.project_type_i18n

    @talent_listing.project_type = :long_term
    assert_equal "장기", @talent_listing.project_type_i18n

    @talent_listing.project_type = :one_time
    assert_equal "단발", @talent_listing.project_type_i18n
  end

  test "status_i18n should return Korean labels" do
    @talent_listing.status = :available
    assert_equal "구직중", @talent_listing.status_i18n

    @talent_listing.status = :unavailable
    assert_equal "구직완료", @talent_listing.status_i18n
  end
end
