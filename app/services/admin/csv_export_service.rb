# frozen_string_literal: true

require "csv"

# 관리자 CSV 내보내기 서비스
# 다양한 모델의 데이터를 CSV 형식으로 내보내기
#
# @example 기본 사용
#   columns = { id: "ID", name: "이름", email: "이메일" }
#   service = Admin::CsvExportService.new(User.all, columns: columns, filename_prefix: "users")
#   send_data service.generate, filename: service.filename, type: "text/csv; charset=utf-8"
#
# @example Lambda로 커스텀 값
#   columns = {
#     id: "ID",
#     status: ->(user) { user.deleted? ? "탈퇴" : "활동 중" }
#   }
#
module Admin
  class CsvExportService
    # UTF-8 BOM (Excel에서 한글 깨짐 방지)
    UTF8_BOM = "\xEF\xBB\xBF"

    # @param records [ActiveRecord::Relation] 내보낼 레코드
    # @param columns [Hash] { attribute_name => "헤더명" } 또는 { attribute_name => lambda }
    # @param filename_prefix [String] 파일명 접두어 (예: "users")
    def initialize(records, columns:, filename_prefix:)
      @records = records
      @columns = columns
      @filename_prefix = filename_prefix
    end

    # CSV 문자열 생성
    # @return [String] UTF-8 BOM이 포함된 CSV 문자열
    def generate
      CSV.generate(UTF8_BOM.dup, force_quotes: true) do |csv|
        # 헤더 행 추가
        csv << headers

        # 데이터 행 추가
        @records.each do |record|
          csv << row_values(record)
        end
      end
    end

    # 타임스탬프가 포함된 파일명
    # @return [String] 예: "users_20260116143022.csv"
    def filename
      timestamp = Time.current.strftime("%Y%m%d%H%M%S")
      "#{@filename_prefix}_#{timestamp}.csv"
    end

    private

    # 헤더 이름 배열
    def headers
      @columns.map do |key, value|
        # Lambda인 경우 키를 헤더명으로 사용 (예: :status)
        # 문자열인 경우 그대로 사용
        value.is_a?(Proc) ? key.to_s.titleize : value.to_s
      end
    end

    # 한 레코드의 값 배열
    def row_values(record)
      @columns.map do |key, value|
        raw_value = extract_value(record, key, value)
        format_value(raw_value)
      end
    end

    # 레코드에서 값 추출
    def extract_value(record, key, value_or_lambda)
      if value_or_lambda.is_a?(Proc)
        # Lambda인 경우 실행
        value_or_lambda.call(record)
      else
        # 일반 속성 접근
        record.send(key)
      end
    rescue NoMethodError
      # 속성이 없는 경우 nil 반환
      nil
    end

    # 값 포맷팅
    def format_value(value)
      case value
      when nil
        ""
      when Time, DateTime, ActiveSupport::TimeWithZone
        value.strftime("%Y-%m-%d %H:%M")
      when Date
        value.strftime("%Y-%m-%d")
      when true
        "예"
      when false
        "아니오"
      else
        value.to_s
      end
    end
  end
end
