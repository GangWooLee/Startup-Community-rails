# frozen_string_literal: true

require "test_helper"

module Ai
  module Agents
    module MarketAnalysis
      class ResultValidatorTest < ActiveSupport::TestCase
        setup do
          @validator = ResultValidator.new
        end

        # ==========================================================================
        # Fallback Result Tests
        # ==========================================================================

        test "fallback_result returns valid structure" do
          result = @validator.fallback_result

          assert_kind_of Hash, result
          assert_kind_of Hash, result[:market_analysis]
          assert_kind_of Array, result[:market_opportunities]
          assert_kind_of Array, result[:market_risks]
        end

        test "fallback_result returns deep copy" do
          result1 = @validator.fallback_result
          result2 = @validator.fallback_result

          result1[:market_analysis][:potential] = "modified"

          refute_equal result1[:market_analysis][:potential], result2[:market_analysis][:potential]
        end

        # ==========================================================================
        # Valid Result Tests
        # ==========================================================================

        test "validate returns validated result for valid input" do
          input = {
            market_analysis: {
              potential: "높음",
              market_size: "약 5조원",
              trends: "성장 중",
              competitors: ["경쟁사A", "경쟁사B"],
              differentiation: "차별점"
            },
            market_opportunities: ["기회1", "기회2"],
            market_risks: ["리스크1", "리스크2"]
          }

          result = @validator.validate(input)

          assert_equal "높음", result[:market_analysis][:potential]
          assert_equal "약 5조원", result[:market_analysis][:market_size]
          assert_equal ["기회1", "기회2"], result[:market_opportunities]
          assert_equal ["리스크1", "리스크2"], result[:market_risks]
        end

        # ==========================================================================
        # Invalid Result Tests
        # ==========================================================================

        test "validate returns fallback for nil result" do
          result = @validator.validate(nil)

          assert_equal @validator.fallback_result, result
        end

        test "validate returns fallback for result with error key" do
          result = @validator.validate({ error: "Something went wrong" })

          assert_equal @validator.fallback_result, result
        end

        test "validate returns fallback for result with raw_response key" do
          result = @validator.validate({ raw_response: "unparseable response" })

          assert_equal @validator.fallback_result, result
        end

        # ==========================================================================
        # Partial Result Tests
        # ==========================================================================

        test "validate fills missing market_analysis fields with fallback" do
          input = {
            market_analysis: {
              potential: "높음"
              # market_size, trends, competitors, differentiation 누락
            },
            market_opportunities: ["기회1"],
            market_risks: []
          }

          result = @validator.validate(input)

          assert_equal "높음", result[:market_analysis][:potential]
          assert_equal "시장 규모 조사 필요", result[:market_analysis][:market_size]
          assert_equal "트렌드 분석 필요", result[:market_analysis][:trends]
          assert_equal [], result[:market_analysis][:competitors]
          assert_equal "차별화 전략 필요", result[:market_analysis][:differentiation]
        end

        test "validate returns empty arrays for missing opportunities and risks" do
          input = {
            market_analysis: {
              potential: "중간"
            }
            # market_opportunities, market_risks 누락
          }

          result = @validator.validate(input)

          assert_equal [], result[:market_opportunities]
          assert_equal [], result[:market_risks]
        end

        test "validate handles non-hash market_analysis" do
          input = {
            market_analysis: "invalid string",
            market_opportunities: [],
            market_risks: []
          }

          result = @validator.validate(input)

          # market_analysis가 해시가 아니면 fallback 사용
          assert_equal "분석 필요", result[:market_analysis][:potential]
        end

        # ==========================================================================
        # FALLBACK_RESULT Constant Tests
        # ==========================================================================

        test "FALLBACK_RESULT is frozen" do
          assert ResultValidator::FALLBACK_RESULT.frozen?
        end

        test "FALLBACK_RESULT has all required keys" do
          fallback = ResultValidator::FALLBACK_RESULT

          assert fallback.key?(:market_analysis)
          assert fallback.key?(:market_opportunities)
          assert fallback.key?(:market_risks)

          analysis = fallback[:market_analysis]
          assert analysis.key?(:potential)
          assert analysis.key?(:market_size)
          assert analysis.key?(:trends)
          assert analysis.key?(:competitors)
          assert analysis.key?(:differentiation)
        end
      end
    end
  end
end
