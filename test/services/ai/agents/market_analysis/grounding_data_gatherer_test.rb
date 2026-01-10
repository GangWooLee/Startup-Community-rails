# frozen_string_literal: true

require "test_helper"

module Ai
  module Agents
    module MarketAnalysis
      class GroundingDataGathererTest < ActiveSupport::TestCase
        setup do
          @industry = "푸드테크"
        end

        # ==========================================================================
        # Successful Gathering Tests
        # ==========================================================================

        test "gather returns hash with expected keys" do
          mock_tool = MockGroundingTool.new(
            market_data: "시장 규모: 약 5조원",
            competitors: "배달의민족, 쿠팡이츠",
            trends: "AI 추천 성장"
          )

          gatherer = GroundingDataGatherer.new(industry: @industry, grounding_tool: mock_tool)
          result = gatherer.gather

          assert_kind_of Hash, result
          assert result.key?(:market_size)
          assert result.key?(:competitors)
          assert result.key?(:trends)
        end

        test "gather returns market_size from tool" do
          mock_tool = MockGroundingTool.new(market_data: "시장 규모: 약 5조원")

          gatherer = GroundingDataGatherer.new(industry: @industry, grounding_tool: mock_tool)
          result = gatherer.gather

          assert_equal "시장 규모: 약 5조원", result[:market_size]
        end

        test "gather returns competitors from tool" do
          mock_tool = MockGroundingTool.new(competitors: "배달의민족, 쿠팡이츠")

          gatherer = GroundingDataGatherer.new(industry: @industry, grounding_tool: mock_tool)
          result = gatherer.gather

          assert_equal "배달의민족, 쿠팡이츠", result[:competitors]
        end

        test "gather returns trends from tool" do
          mock_tool = MockGroundingTool.new(trends: "AI 기반 추천")

          gatherer = GroundingDataGatherer.new(industry: @industry, grounding_tool: mock_tool)
          result = gatherer.gather

          assert_equal "AI 기반 추천", result[:trends]
        end

        # ==========================================================================
        # Error Handling Tests
        # ==========================================================================

        test "gather returns nil for failed searches" do
          mock_tool = MockGroundingTool.new(raise_error: true)

          gatherer = GroundingDataGatherer.new(industry: @industry, grounding_tool: mock_tool)
          result = gatherer.gather

          assert_nil result[:market_size]
          assert_nil result[:competitors]
          assert_nil result[:trends]
        end

        test "gather continues after individual search failures" do
          mock_tool = MockGroundingTool.new(
            market_data: nil,
            competitors: nil,
            trends: "트렌드 정보만 있음"
          )

          gatherer = GroundingDataGatherer.new(industry: @industry, grounding_tool: mock_tool)
          result = gatherer.gather

          assert_nil result[:market_size]
          assert_nil result[:competitors]
          assert_equal "트렌드 정보만 있음", result[:trends]
        end

        # ==========================================================================
        # Empty Content Tests
        # ==========================================================================

        test "gather returns nil for empty content" do
          mock_tool = MockGroundingTool.new(market_data: "", competitors: "  ", trends: nil)

          gatherer = GroundingDataGatherer.new(industry: @industry, grounding_tool: mock_tool)
          result = gatherer.gather

          assert_nil result[:market_size]
          assert_nil result[:competitors]
          assert_nil result[:trends]
        end

        # ==========================================================================
        # Query Construction Tests
        # ==========================================================================

        test "logs industry name" do
          mock_tool = MockGroundingTool.new
          gatherer = GroundingDataGatherer.new(industry: "핀테크", grounding_tool: mock_tool)

          assert_nothing_raised { gatherer.gather }
          assert_equal "핀테크", gatherer.industry
        end

        test "accepts industry via constructor" do
          gatherer = GroundingDataGatherer.new(industry: "에듀테크", grounding_tool: MockGroundingTool.new)

          assert_equal "에듀테크", gatherer.industry
        end
      end

      # Mock grounding tool for testing
      class MockGroundingTool
        def initialize(market_data: nil, competitors: nil, trends: nil, raise_error: false)
          @market_data = market_data
          @competitors = competitors
          @trends = trends
          @raise_error = raise_error
        end

        def search_market_data(query:)
          raise StandardError, "API Error" if @raise_error
          MockResult.new(@market_data)
        end

        def search_competitors(query:)
          raise StandardError, "API Error" if @raise_error
          MockResult.new(@competitors)
        end

        def search_trends(query:)
          raise StandardError, "API Error" if @raise_error
          MockResult.new(@trends)
        end

        class MockResult
          attr_reader :content

          def initialize(content)
            @content = content
          end
        end
      end
    end
  end
end
