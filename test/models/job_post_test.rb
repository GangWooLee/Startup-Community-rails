# frozen_string_literal: true

require "test_helper"

# NOTE: JobPost 모델은 DEPRECATED입니다.
# Post 모델의 category: :hiring으로 대체되었습니다.
# 이 테스트는 마이그레이션 완료 전까지 호환성을 위해 유지됩니다.
class JobPostTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @job_post = job_posts(:one)
  end

  # =========================================
  # Association Tests
  # =========================================

  test "should belong to user" do
    assert_respond_to @job_post, :user
    assert_equal @user, @job_post.user
  end

  test "should have many bookmarks" do
    assert_respond_to @job_post, :bookmarks
  end

  # =========================================
  # Validation Tests
  # =========================================

  test "should be valid with valid attributes" do
    job_post = JobPost.new(
      user: @user,
      title: "Rails 개발자 구합니다",
      description: "스타트업에서 풀스택 개발자를 찾습니다.",
      category: :development,
      project_type: :short_term,
      status: :open
    )
    assert job_post.valid?
  end

  test "should require title" do
    job_post = JobPost.new(
      user: @user,
      description: "설명입니다.",
      category: :development,
      project_type: :short_term
    )
    assert_not job_post.valid?
    assert_includes job_post.errors[:title], "can't be blank"
  end

  test "should require description" do
    job_post = JobPost.new(
      user: @user,
      title: "제목입니다",
      category: :development,
      project_type: :short_term
    )
    assert_not job_post.valid?
    assert_includes job_post.errors[:description], "can't be blank"
  end

  test "should enforce title maximum length" do
    job_post = JobPost.new(
      user: @user,
      title: "a" * 256,
      description: "설명입니다.",
      category: :development,
      project_type: :short_term
    )
    assert_not job_post.valid?
    assert_includes job_post.errors[:title], "is too long (maximum is 255 characters)"
  end

  # =========================================
  # Enum Tests
  # =========================================

  test "should have category enum" do
    assert_equal %w[development design pm marketing], JobPost.categories.keys
  end

  test "should have project_type enum" do
    assert_equal %w[short_term long_term one_time], JobPost.project_types.keys
  end

  test "should have status enum" do
    assert_equal %w[open closed filled], JobPost.statuses.keys
  end

  # =========================================
  # Scope Tests
  # =========================================

  test "open_positions scope should return only open jobs" do
    @job_post.update!(status: :open)
    closed_job = JobPost.create!(
      user: @user,
      title: "마감된 공고",
      description: "설명",
      category: :development,
      project_type: :short_term,
      status: :closed
    )

    open_jobs = JobPost.open_positions
    assert_includes open_jobs, @job_post
    assert_not_includes open_jobs, closed_job
  end

  test "recent scope should order by created_at desc" do
    recent_jobs = JobPost.recent.to_a
    # 최신순 정렬 확인: 각 레코드의 created_at이 다음 레코드보다 크거나 같아야 함
    recent_jobs.each_cons(2) do |prev, curr|
      assert prev.created_at >= curr.created_at, "Expected #{prev.created_at} >= #{curr.created_at}"
    end
  end

  test "by_category scope should filter by category" do
    # 테스트용 데이터 명시적 생성 (fixture 의존성 제거)
    dev_job = JobPost.create!(
      user: @user,
      title: "개발자 채용",
      description: "설명",
      category: :development,
      project_type: :short_term,
      status: :open
    )
    design_job = JobPost.create!(
      user: @user,
      title: "디자이너 채용",
      description: "설명",
      category: :design,
      project_type: :short_term,
      status: :open
    )

    development_jobs = JobPost.by_category(:development)

    # 결과가 비어있지 않음을 확인 (테스트 의미 보장)
    assert_not_empty development_jobs, "by_category(:development) should return results"

    # 생성한 개발 공고가 포함되어야 함
    assert_includes development_jobs, dev_job

    # 디자인 공고는 포함되지 않아야 함
    assert_not_includes development_jobs, design_job

    # 모든 결과가 development 카테고리인지 확인
    development_jobs.each do |job|
      assert_equal "development", job.category
    end
  end

  # =========================================
  # Instance Method Tests
  # =========================================

  test "increment_views! should increase views_count" do
    initial_views = @job_post.views_count
    @job_post.increment_views!
    assert_equal initial_views + 1, @job_post.reload.views_count
  end

  test "category_i18n should return Korean labels" do
    @job_post.category = :development
    assert_equal "개발", @job_post.category_i18n

    @job_post.category = :design
    assert_equal "디자인", @job_post.category_i18n

    @job_post.category = :pm
    assert_equal "PM/기획", @job_post.category_i18n

    @job_post.category = :marketing
    assert_equal "마케팅", @job_post.category_i18n
  end

  test "project_type_i18n should return Korean labels" do
    @job_post.project_type = :short_term
    assert_equal "단기", @job_post.project_type_i18n

    @job_post.project_type = :long_term
    assert_equal "장기", @job_post.project_type_i18n

    @job_post.project_type = :one_time
    assert_equal "단발", @job_post.project_type_i18n
  end

  test "status_i18n should return Korean labels" do
    @job_post.status = :open
    assert_equal "모집중", @job_post.status_i18n

    @job_post.status = :closed
    assert_equal "마감", @job_post.status_i18n

    @job_post.status = :filled
    assert_equal "완료", @job_post.status_i18n
  end
end
