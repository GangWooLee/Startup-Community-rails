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
          Rails.logger.info("[GroundingDataGatherer] Gathering data for: #{industry} (parallel)")

          # 3개 검색을 병렬 실행 (각 검색은 독립적)
          futures = {
            market_size: Concurrent::Future.execute { search_market_size },
            competitors: Concurrent::Future.execute { search_competitors },
            trends: Concurrent::Future.execute { search_trends }
          }

          # 결과 수집 (개별 타임아웃 30초)
          results = {}
          futures.each do |key, future|
            begin
              results[key] = future.value(30) # 30초 타임아웃
            rescue Concurrent::TimeoutError
              Rails.logger.warn("[GroundingDataGatherer] #{key} timed out")
              results[key] = nil
            end
          end

          gathered_keys = results.keys.select { |k| results[k].present? }
          Rails.logger.info("[GroundingDataGatherer] Gathered: #{gathered_keys.join(', ')} (#{gathered_keys.size}/3)")
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
