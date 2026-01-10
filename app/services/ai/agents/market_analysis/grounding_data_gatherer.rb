# frozen_string_literal: true

module Ai
  module Agents
    module MarketAnalysis
      # 실시간 웹 검색 데이터 수집 서비스
      #
      # Gemini Grounding Tool을 사용하여 시장 데이터 수집
      # 시장 규모, 경쟁사, 트렌드 3가지 검색 수행
      #
      # 사용 예:
      #   gatherer = GroundingDataGatherer.new(industry: "푸드테크")
      #   data = gatherer.gather
      #   # => { market_size: "...", competitors: "...", trends: "..." }
      class GroundingDataGatherer
        attr_reader :industry, :grounding_tool

        def initialize(industry:, grounding_tool: nil)
          @industry = industry
          @grounding_tool = grounding_tool || Ai::Tools::GeminiGroundingTool.new
        end

        def gather
          Rails.logger.info("[GroundingDataGatherer] Gathering data for: #{industry}")

          results = {}
          results[:market_size] = search_market_size
          results[:competitors] = search_competitors
          results[:trends] = search_trends
          results
        end

        private

        def search_market_size
          result = grounding_tool.search_market_data(query: "한국 #{industry} 시장 규모")
          result&.content.presence
        rescue StandardError => e
          Rails.logger.warn("[GroundingDataGatherer] Market size search failed: #{e.message}")
          nil
        end

        def search_competitors
          result = grounding_tool.search_competitors(query: "한국 #{industry} 주요 기업 스타트업")
          result&.content.presence
        rescue StandardError => e
          Rails.logger.warn("[GroundingDataGatherer] Competitor search failed: #{e.message}")
          nil
        end

        def search_trends
          result = grounding_tool.search_trends(query: "#{industry} 트렌드 전망")
          result&.content.presence
        rescue StandardError => e
          Rails.logger.warn("[GroundingDataGatherer] Trend search failed: #{e.message}")
          nil
        end
      end
    end
  end
end
