# frozen_string_literal: true

require "test_helper"

class Admin::CsvExportServiceTest < ActiveSupport::TestCase
  fixtures :users

  setup do
    @users = User.where(id: [ users(:one).id, users(:two).id ])
    @columns = {
      id: "ID",
      name: "이름",
      email: "이메일",
      created_at: "가입일"
    }
  end

  # ===== 기본 동작 =====

  test "generates CSV with headers" do
    service = Admin::CsvExportService.new(@users, columns: @columns, filename_prefix: "users")
    csv = service.generate

    # UTF-8 BOM 확인
    assert csv.start_with?("\xEF\xBB\xBF"), "CSV should start with UTF-8 BOM"

    # 헤더 확인 (한글)
    lines = csv.lines
    header = lines.first.strip
    assert_includes header, "ID"
    assert_includes header, "이름"
    assert_includes header, "이메일"
    assert_includes header, "가입일"
  end

  test "generates CSV with data rows" do
    service = Admin::CsvExportService.new(@users, columns: @columns, filename_prefix: "users")
    csv = service.generate
    lines = csv.lines

    # 헤더 + 데이터 행 (2명)
    assert_equal 3, lines.count

    # 첫 번째 사용자 데이터 확인
    user = users(:one)
    data_line = lines.find { |l| l.include?(user.email) }
    assert data_line.present?, "Should include user email"
    assert_includes data_line, user.name
  end

  test "handles empty data" do
    empty_users = User.none
    service = Admin::CsvExportService.new(empty_users, columns: @columns, filename_prefix: "users")
    csv = service.generate

    lines = csv.lines
    # 빈 데이터일 때 헤더만 있어야 함
    assert_equal 1, lines.count
    assert_includes lines.first, "ID"
  end

  # ===== 파일명 생성 =====

  test "generates filename with timestamp" do
    service = Admin::CsvExportService.new(@users, columns: @columns, filename_prefix: "users")
    filename = service.filename

    assert filename.start_with?("users_")
    assert filename.end_with?(".csv")
    assert_match(/users_\d{14}\.csv/, filename) # users_YYYYMMDDHHmmss.csv
  end

  test "uses custom filename prefix" do
    service = Admin::CsvExportService.new(@users, columns: @columns, filename_prefix: "export_test")
    filename = service.filename

    assert filename.start_with?("export_test_")
  end

  # ===== 특수 케이스 처리 =====

  test "escapes special characters in CSV" do
    # 쉼표, 따옴표, 줄바꿈이 포함된 데이터 처리
    user = users(:one)
    user.update!(name: 'Test, "User"')

    service = Admin::CsvExportService.new(User.where(id: user.id), columns: @columns, filename_prefix: "users")
    csv = service.generate

    # CSV 파싱이 성공해야 함
    parsed = CSV.parse(csv.sub("\xEF\xBB\xBF", ""))
    assert_equal 2, parsed.count # 헤더 + 1행
  end

  test "handles nil values" do
    # nil이 포함된 컬럼 테스트 (bio는 nullable)
    user = users(:one)
    user.update!(bio: nil)

    columns_with_nullable = {
      id: "ID",
      name: "이름",
      bio: "소개"
    }

    service = Admin::CsvExportService.new(User.where(id: user.id), columns: columns_with_nullable, filename_prefix: "users")
    csv = service.generate

    # nil은 빈 문자열로 처리되어야 함
    assert_not_includes csv, "nil"
    refute_match(/,nil,/, csv)
  end

  # ===== 날짜 포맷팅 =====

  test "formats datetime columns" do
    service = Admin::CsvExportService.new(@users, columns: @columns, filename_prefix: "users")
    csv = service.generate

    # 날짜가 YYYY-MM-DD HH:MM 형식으로 포맷되어야 함
    assert_match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}/, csv)
  end

  # ===== 커스텀 값 처리 =====

  test "supports lambda for column values" do
    columns_with_lambda = {
      id: "ID",
      name: "이름",
      status: ->(record) { record.deleted? ? "탈퇴" : "활동 중" }
    }

    service = Admin::CsvExportService.new(@users, columns: columns_with_lambda, filename_prefix: "users")
    csv = service.generate

    assert_includes csv, "활동 중"
  end

  test "supports nested attributes" do
    # posts_count_value 같은 서브쿼리 결과 접근
    users_with_count = User.select(
      "users.*",
      "(SELECT COUNT(*) FROM posts WHERE posts.user_id = users.id) AS posts_count_value"
    ).where(id: users(:one).id)

    columns = {
      id: "ID",
      posts_count_value: "게시글 수"
    }

    service = Admin::CsvExportService.new(users_with_count, columns: columns, filename_prefix: "users")
    csv = service.generate

    # 서브쿼리 결과가 CSV에 포함되어야 함
    assert_match(/게시글 수/, csv)
  end
end
