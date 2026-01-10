# frozen_string_literal: true

module Ai
  module Agents
    module MarketAnalysis
      # 시장 분석 결과 검증 서비스
      #
      # LLM 응답을 검증하고 유효한 형식으로 정규화
      # 누락된 필드에 대해 fallback 값 제공
      #
      # 사용 예:
      #   validator = ResultValidator.new
      #   result = validator.validate(raw_result)
      class ResultValidator
        FALLBACK_RESULT = {
          market_analysis: {
            potential: "분석 필요",
            market_size: "시장 규모 조사 필요",
            trends: "트렌드 분석 필요",
            competitors: [],
            differentiation: "차별화 전략 필요"
          },
          market_opportunities: [],
          market_risks: []
        }.freeze

        def validate(result)
          return fallback_result if invalid_result?(result)

          {
            market_analysis: validate_market_analysis(result[:market_analysis]),
            market_opportunities: result[:market_opportunities] || [],
            market_risks: result[:market_risks] || []
          }
        end

        def fallback_result
          FALLBACK_RESULT.deep_dup
        end

        private

        def invalid_result?(result)
          result.nil? || result[:error] || result[:raw_response]
        end

        def validate_market_analysis(market_analysis)
          return fallback_result[:market_analysis] unless market_analysis.is_a?(Hash)

          fallback = fallback_result[:market_analysis]
          {
            potential: market_analysis[:potential] || fallback[:potential],
            market_size: market_analysis[:market_size] || fallback[:market_size],
            trends: market_analysis[:trends] || fallback[:trends],
            competitors: market_analysis[:competitors] || fallback[:competitors],
            differentiation: market_analysis[:differentiation] || fallback[:differentiation]
          }
        end
      end
    end
  end
end
