# frozen_string_literal: true

require "test_helper"

class ReportTest < ActiveSupport::TestCase
  def setup
    @reporter = users(:one)
    @post = posts(:one)
    @report = Report.new(
      reporter: @reporter,
      reportable: @post,
      reason: "spam",
      description: "테스트 신고"
    )
  end

  # === Validations ===

  test "valid report" do
    assert @report.valid?
  end

  test "requires reporter" do
    @report.reporter = nil
    assert_not @report.valid?
    assert @report.errors[:reporter].any?
  end

  test "requires reportable" do
    @report.reportable = nil
    assert_not @report.valid?
    assert @report.errors[:reportable].any?
  end

  test "requires reason" do
    @report.reason = nil
    assert_not @report.valid?
    assert @report.errors[:reason].any?
  end

  test "reason must be valid" do
    @report.reason = "invalid_reason"
    assert_not @report.valid?
    assert_includes @report.errors[:reason], "유효하지 않은 신고 사유입니다"
  end

  test "accepts all valid reasons" do
    Report::REASONS.keys.each do |reason|
      @report.reason = reason
      assert @report.valid?, "#{reason} should be valid"
    end
  end

  test "reportable_type must be valid" do
    # 직접 타입 설정 (polymorphic 우회)
    @report.save!
    # update_columns로 직접 DB 업데이트 (콜백/validation 건너뜀)
    @report.update_columns(reportable_type: "InvalidModel", reportable_id: 1)
    @report.reload
    assert_not @report.valid?
    assert_includes @report.errors[:reportable_type], "유효하지 않은 신고 대상입니다"
  end

  test "reporter can only report same item once" do
    @report.save!

    duplicate = Report.new(
      reporter: @reporter,
      reportable: @post,
      reason: "harassment"
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:reporter_id], "이미 신고한 항목입니다"
  end

  # === Default Values ===

  test "default status is pending" do
    @report.save!
    assert_equal "pending", @report.status
  end

  # === Scopes ===

  test "pending scope returns only pending reports" do
    pending_reports = Report.pending
    assert pending_reports.all? { |r| r.status == "pending" }
  end

  test "recent scope returns reports in descending order" do
    reports = Report.recent
    assert_equal reports.order(created_at: :desc).to_a, reports.to_a
  end

  # === Helper Methods ===

  test "reason_label returns Korean label" do
    @report.reason = "spam"
    assert_equal "스팸/광고", @report.reason_label

    @report.reason = "harassment"
    assert_equal "괴롭힘/욕설", @report.reason_label
  end

  test "status_label returns Korean label" do
    @report.status = "pending"
    assert_equal "대기 중", @report.status_label

    @report.status = "resolved"
    assert_equal "처리완료", @report.status_label
  end

  test "reportable_type_label returns Korean label" do
    @report.reportable_type = "Post"
    assert_equal "게시글", @report.reportable_type_label

    @report.reportable_type = "User"
    assert_equal "사용자", @report.reportable_type_label
  end

  test "pending? returns true for pending status" do
    @report.status = "pending"
    assert @report.pending?
  end

  test "resolved? returns true for resolved or dismissed status" do
    @report.status = "resolved"
    assert @report.resolved?

    @report.status = "dismissed"
    assert @report.resolved?
  end

  # === Polymorphic Associations ===

  test "can report a Post" do
    report = Report.new(
      reporter: @reporter,
      reportable: posts(:two),
      reason: "inappropriate"
    )
    assert report.valid?
    assert_equal "Post", report.reportable_type
  end

  test "can report a User" do
    report = Report.new(
      reporter: @reporter,
      reportable: users(:two),
      reason: "harassment"
    )
    assert report.valid?
    assert_equal "User", report.reportable_type
  end

  # === resolve! Method ===

  test "resolve! updates status and sets resolved_by" do
    admin = users(:admin)
    @report.save!
    @report.resolve!(admin, "resolved", "처리 완료했습니다.")

    assert_equal "resolved", @report.status
    assert_equal admin, @report.resolved_by
    assert_not_nil @report.resolved_at
    assert_equal "처리 완료했습니다.", @report.admin_note
  end
end
