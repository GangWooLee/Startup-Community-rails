# frozen_string_literal: true

require "test_helper"

class InquiryTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @inquiry = Inquiry.new(
      user: @user,
      category: "bug",
      title: "로그인 오류",
      content: "로그인할 때 오류가 발생합니다."
    )
  end

  # === Validations ===

  test "valid inquiry" do
    assert @inquiry.valid?
  end

  test "requires user" do
    @inquiry.user = nil
    assert_not @inquiry.valid?
    assert @inquiry.errors[:user].any?
  end

  test "requires category" do
    @inquiry.category = nil
    assert_not @inquiry.valid?
    assert @inquiry.errors[:category].any?
  end

  test "category must be valid" do
    @inquiry.category = "invalid_category"
    assert_not @inquiry.valid?
    assert_includes @inquiry.errors[:category], "유효하지 않은 카테고리입니다"
  end

  test "accepts all valid categories" do
    Inquiry::CATEGORIES.keys.each do |category|
      @inquiry.category = category
      assert @inquiry.valid?, "#{category} should be valid"
    end
  end

  test "requires title" do
    @inquiry.title = nil
    assert_not @inquiry.valid?
    assert @inquiry.errors[:title].any?
  end

  test "title must be 100 characters or less" do
    @inquiry.title = "a" * 101
    assert_not @inquiry.valid?
    assert @inquiry.errors[:title].any?

    @inquiry.title = "a" * 100
    assert @inquiry.valid?
  end

  test "requires content" do
    @inquiry.content = nil
    assert_not @inquiry.valid?
    assert @inquiry.errors[:content].any?
  end

  # === Default Values ===

  test "default status is pending" do
    @inquiry.save!
    assert_equal "pending", @inquiry.status
  end

  # === Scopes ===

  test "pending scope returns only pending inquiries" do
    pending_inquiries = Inquiry.pending
    assert pending_inquiries.all? { |i| i.status == "pending" }
  end

  test "in_progress scope returns only in_progress inquiries" do
    in_progress_inquiries = Inquiry.in_progress
    assert in_progress_inquiries.all? { |i| i.status == "in_progress" }
  end

  test "recent scope returns inquiries in descending order" do
    inquiries = Inquiry.recent
    assert_equal inquiries.order(created_at: :desc).to_a, inquiries.to_a
  end

  test "by_category scope filters by category" do
    bug_inquiries = Inquiry.by_category("bug")
    assert bug_inquiries.all? { |i| i.category == "bug" }
  end

  # === Helper Methods ===

  test "category_label returns Korean label" do
    @inquiry.category = "bug"
    assert_equal "버그 신고", @inquiry.category_label

    @inquiry.category = "feature"
    assert_equal "기능 제안", @inquiry.category_label
  end

  test "status_label returns Korean label" do
    @inquiry.status = "pending"
    assert_equal "대기 중", @inquiry.status_label

    @inquiry.status = "resolved"
    assert_equal "답변 완료", @inquiry.status_label
  end

  test "pending? returns true for pending status" do
    @inquiry.status = "pending"
    assert @inquiry.pending?
  end

  test "resolved? returns true for resolved status" do
    @inquiry.status = "resolved"
    assert @inquiry.resolved?
  end

  # === respond! Method ===

  test "respond! updates inquiry with admin response" do
    admin = users(:admin)
    @inquiry.save!
    @inquiry.respond!(admin, "답변 내용입니다.")

    assert_equal "resolved", @inquiry.status
    assert_equal "답변 내용입니다.", @inquiry.admin_response
    assert_equal admin, @inquiry.responded_by
    assert_not_nil @inquiry.responded_at
  end

  # === update_status! Method ===

  test "update_status! changes status" do
    @inquiry.save!
    @inquiry.update_status!("in_progress")

    assert_equal "in_progress", @inquiry.status
  end
end
