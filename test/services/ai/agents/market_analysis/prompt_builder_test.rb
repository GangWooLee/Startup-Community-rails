# frozen_string_literal: true

require "test_helper"

module Ai
  module Agents
    module MarketAnalysis
      class PromptBuilderTest < ActiveSupport::TestCase
        setup do
          @idea = "커뮤니티 기반 창업 플랫폼"
          @follow_up_answers = {
            target: "초보 창업자",
            problem: "정보 부족",
            differentiator: "신뢰 기반 프로필"
          }
          @previous_results = {
            summary: {
              summary: "창업자 네트워킹 플랫폼",
              core_value: "신뢰 기반 연결",
              problem_statement: "창업 정보 파편화"
            },
            target_user: {
              target_users: {
                primary: "20-30대 초기 창업자",
                characteristics: [ "IT 관심", "사이드프로젝트" ]
              },
              user_pain_points: [ "멘토 부족", "팀원 구하기 어려움" ]
            }
          }
        end

        # ==========================================================================
        # System Prompt Tests
        # ==========================================================================

        test "system_prompt with :direct mode returns basic prompt" do
          builder = PromptBuilder.new(idea: @idea)
          prompt = builder.system_prompt(:direct)

          assert_includes prompt, "시장 분석 및 경쟁 전략 전문가"
          assert_includes prompt, "JSON"
          assert_includes prompt, "market_analysis"
          refute_includes prompt, "실시간"
          refute_includes prompt, "도구"
        end

        test "system_prompt with :grounding mode includes grounding instructions" do
          builder = PromptBuilder.new(idea: @idea)
          prompt = builder.system_prompt(:grounding)

          assert_includes prompt, "실시간 검색 결과"
          assert_includes prompt, "Google Search"
          assert_includes prompt, "JSON"
        end

        test "system_prompt with :static mode includes tool instructions" do
          builder = PromptBuilder.new(idea: @idea)
          prompt = builder.system_prompt(:static)

          assert_includes prompt, "get_market_size"
          assert_includes prompt, "get_market_trends"
          assert_includes prompt, "find_competitors"
          assert_includes prompt, "get_competitor_info"
        end

        test "system_prompt defaults to :direct mode" do
          builder = PromptBuilder.new(idea: @idea)

          assert_equal builder.system_prompt, builder.system_prompt(:direct)
        end

        # ==========================================================================
        # User Prompt Tests
        # ==========================================================================

        test "user_prompt includes idea" do
          builder = PromptBuilder.new(idea: @idea)
          prompt = builder.user_prompt

          assert_includes prompt, @idea
          assert_includes prompt, "## 아이디어"
        end

        test "user_prompt includes follow_up_answers with translations" do
          builder = PromptBuilder.new(idea: @idea, follow_up_answers: @follow_up_answers)
          prompt = builder.user_prompt

          assert_includes prompt, "## 추가 정보"
          assert_includes prompt, "타겟 사용자: 초보 창업자"
          assert_includes prompt, "해결하려는 문제: 정보 부족"
          assert_includes prompt, "차별화 포인트: 신뢰 기반 프로필"
        end

        test "user_prompt includes previous summary results" do
          builder = PromptBuilder.new(
            idea: @idea,
            previous_results: @previous_results
          )
          prompt = builder.user_prompt

          assert_includes prompt, "## 아이디어 요약"
          assert_includes prompt, "핵심 요약: 창업자 네트워킹 플랫폼"
          assert_includes prompt, "핵심 가치: 신뢰 기반 연결"
          assert_includes prompt, "문제 정의: 창업 정보 파편화"
        end

        test "user_prompt includes previous target_user results" do
          builder = PromptBuilder.new(
            idea: @idea,
            previous_results: @previous_results
          )
          prompt = builder.user_prompt

          assert_includes prompt, "## 타겟 사용자 분석"
          assert_includes prompt, "주요 타겟: 20-30대 초기 창업자"
          assert_includes prompt, "사용자 특성: IT 관심, 사이드프로젝트"
          assert_includes prompt, "사용자 고민: 멘토 부족, 팀원 구하기 어려움"
        end

        test "user_prompt ends with analysis request" do
          builder = PromptBuilder.new(idea: @idea)
          prompt = builder.user_prompt

          assert_includes prompt, "시장 분석을 수행해주세요"
        end

        # ==========================================================================
        # User Prompt with Grounding Tests
        # ==========================================================================

        test "user_prompt_with_grounding includes search context" do
          builder = PromptBuilder.new(idea: @idea)
          search_context = {
            market_size: "국내 커뮤니티 플랫폼 시장 약 3000억원",
            competitors: "블라인드, 로켓펀치, 원티드",
            trends: "AI 기반 매칭 서비스 성장"
          }

          prompt = builder.user_prompt_with_grounding(search_context)

          assert_includes prompt, "## 실시간 웹 검색 결과"
          assert_includes prompt, "### 시장 규모 데이터"
          assert_includes prompt, "국내 커뮤니티 플랫폼 시장 약 3000억원"
          assert_includes prompt, "### 경쟁사 정보"
          assert_includes prompt, "블라인드, 로켓펀치, 원티드"
          assert_includes prompt, "### 트렌드 정보"
          assert_includes prompt, "AI 기반 매칭 서비스 성장"
        end

        test "user_prompt_with_grounding handles partial search context" do
          builder = PromptBuilder.new(idea: @idea)
          search_context = {
            market_size: "시장 규모 데이터만 있음"
            # competitors, trends 없음
          }

          prompt = builder.user_prompt_with_grounding(search_context)

          assert_includes prompt, "### 시장 규모 데이터"
          refute_includes prompt, "### 경쟁사 정보"
          refute_includes prompt, "### 트렌드 정보"
        end

        test "user_prompt_with_grounding handles empty search context" do
          builder = PromptBuilder.new(idea: @idea)

          prompt = builder.user_prompt_with_grounding({})

          # 기본 user_prompt와 동일해야 함
          assert_equal builder.user_prompt, prompt
        end

        test "user_prompt_with_grounding handles nil search context" do
          builder = PromptBuilder.new(idea: @idea)

          prompt = builder.user_prompt_with_grounding(nil)

          assert_equal builder.user_prompt, prompt
        end

        # ==========================================================================
        # Edge Case Tests
        # ==========================================================================

        test "handles nil follow_up_answers" do
          builder = PromptBuilder.new(idea: @idea, follow_up_answers: nil)

          assert_nothing_raised { builder.user_prompt }
        end

        test "handles nil previous_results" do
          builder = PromptBuilder.new(idea: @idea, previous_results: nil)

          assert_nothing_raised { builder.user_prompt }
        end

        test "skips blank follow_up_answer values" do
          builder = PromptBuilder.new(
            idea: @idea,
            follow_up_answers: { target: "창업자", problem: "", differentiator: nil }
          )
          prompt = builder.user_prompt

          assert_includes prompt, "타겟 사용자: 창업자"
          refute_includes prompt, "해결하려는 문제:"
          refute_includes prompt, "차별화 포인트:"
        end

        # ==========================================================================
        # Key Translation Tests
        # ==========================================================================

        test "translates known keys correctly" do
          builder = PromptBuilder.new(
            idea: @idea,
            follow_up_answers: { target: "A", problem: "B", differentiator: "C" }
          )
          prompt = builder.user_prompt

          assert_includes prompt, "타겟 사용자: A"
          assert_includes prompt, "해결하려는 문제: B"
          assert_includes prompt, "차별화 포인트: C"
        end

        test "humanizes unknown keys" do
          builder = PromptBuilder.new(
            idea: @idea,
            follow_up_answers: { unknown_key: "value" }
          )
          prompt = builder.user_prompt

          assert_includes prompt, "Unknown key: value"
        end
      end
    end
  end
end
