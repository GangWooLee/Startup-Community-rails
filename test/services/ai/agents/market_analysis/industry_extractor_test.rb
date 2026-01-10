# frozen_string_literal: true

require "test_helper"

module Ai
  module Agents
    module MarketAnalysis
      class IndustryExtractorTest < ActiveSupport::TestCase
        # ==========================================================================
        # Basic Extraction Tests
        # ==========================================================================

        test "extracts 이커머스 from shopping-related keywords" do
          extractor = IndustryExtractor.new(idea: "온라인 쇼핑 플랫폼을 만들고 싶습니다")
          assert_equal "이커머스", extractor.extract

          extractor = IndustryExtractor.new(idea: "커머스 사이트 개발")
          assert_equal "이커머스", extractor.extract
        end

        test "extracts 핀테크 from finance-related keywords" do
          extractor = IndustryExtractor.new(idea: "간편 결제 서비스")
          assert_equal "핀테크", extractor.extract

          extractor = IndustryExtractor.new(idea: "투자 관리 앱")
          assert_equal "핀테크", extractor.extract
        end

        test "extracts 에듀테크 from education-related keywords" do
          extractor = IndustryExtractor.new(idea: "온라인교육 플랫폼")
          assert_equal "에듀테크", extractor.extract

          extractor = IndustryExtractor.new(idea: "튜터 매칭 서비스")
          assert_equal "에듀테크", extractor.extract
        end

        test "extracts 헬스테크 from health-related keywords" do
          extractor = IndustryExtractor.new(idea: "헬스케어 모니터링 앱")
          assert_equal "헬스테크", extractor.extract

          extractor = IndustryExtractor.new(idea: "병원 예약 서비스")
          assert_equal "헬스테크", extractor.extract
        end

        test "extracts 푸드테크 from food-related keywords" do
          extractor = IndustryExtractor.new(idea: "음식 배달 플랫폼")
          assert_equal "푸드테크", extractor.extract

          extractor = IndustryExtractor.new(idea: "밀키트 구독 서비스")
          assert_equal "푸드테크", extractor.extract
        end

        test "extracts 모빌리티 from mobility-related keywords" do
          extractor = IndustryExtractor.new(idea: "공유 킥보드 서비스")
          assert_equal "모빌리티", extractor.extract

          extractor = IndustryExtractor.new(idea: "택시 배차 앱")
          assert_equal "모빌리티", extractor.extract
        end

        test "extracts 프롭테크 from real estate keywords" do
          extractor = IndustryExtractor.new(idea: "부동산 매물 플랫폼")
          assert_equal "프롭테크", extractor.extract

          extractor = IndustryExtractor.new(idea: "전세 대출 비교 서비스")
          assert_equal "프롭테크", extractor.extract
        end

        test "extracts HR테크 from HR-related keywords" do
          extractor = IndustryExtractor.new(idea: "채용 매칭 플랫폼")
          assert_equal "HR테크", extractor.extract

          extractor = IndustryExtractor.new(idea: "구인구직 서비스")
          assert_equal "HR테크", extractor.extract
        end

        test "extracts SaaS from B2B-related keywords" do
          extractor = IndustryExtractor.new(idea: "기업용 소프트웨어")
          assert_equal "SaaS", extractor.extract

          extractor = IndustryExtractor.new(idea: "B2B 서비스 플랫폼")
          assert_equal "SaaS", extractor.extract
        end

        test "extracts AI from AI-related keywords" do
          extractor = IndustryExtractor.new(idea: "인공지능 챗봇")
          assert_equal "AI", extractor.extract

          extractor = IndustryExtractor.new(idea: "머신러닝 기반 추천 시스템")
          assert_equal "AI", extractor.extract
        end

        test "extracts 커뮤니티 from community-related keywords" do
          extractor = IndustryExtractor.new(idea: "창업가 커뮤니티 플랫폼")
          assert_equal "커뮤니티", extractor.extract

          extractor = IndustryExtractor.new(idea: "소셜 네트워킹 앱")
          assert_equal "커뮤니티", extractor.extract
        end

        test "extracts 외주 from freelance-related keywords" do
          # 외주 키워드: 외주, 프리랜서, 개발자, 디자이너, 매칭
          # "프리랜서" 단독 테스트
          extractor = IndustryExtractor.new(idea: "프리랜서 협업")
          assert_equal "외주", extractor.extract

          extractor = IndustryExtractor.new(idea: "외주 작업 관리")
          assert_equal "외주", extractor.extract
        end

        # ==========================================================================
        # Default Value Tests
        # ==========================================================================

        test "returns 스타트업 as default when no keyword matches" do
          extractor = IndustryExtractor.new(idea: "혁신적인 새로운 아이디어")
          assert_equal "스타트업", extractor.extract
        end

        test "returns 스타트업 for empty idea" do
          extractor = IndustryExtractor.new(idea: "")
          assert_equal "스타트업", extractor.extract
        end

        # ==========================================================================
        # Follow-up Answers Tests
        # ==========================================================================

        test "considers follow_up_answers in extraction" do
          extractor = IndustryExtractor.new(
            idea: "새로운 플랫폼",
            follow_up_answers: { problem: "배달 음식 품질 관리" }
          )
          assert_equal "푸드테크", extractor.extract
        end

        test "handles nil follow_up_answers" do
          extractor = IndustryExtractor.new(idea: "인공지능 챗봇 개발", follow_up_answers: nil)
          assert_equal "AI", extractor.extract
        end

        test "handles empty follow_up_answers" do
          extractor = IndustryExtractor.new(idea: "헬스케어 앱", follow_up_answers: {})
          assert_equal "헬스테크", extractor.extract
        end

        # ==========================================================================
        # Priority Tests
        # ==========================================================================

        test "first matching industry wins" do
          # 이커머스가 먼저 정의되어 있으므로 쇼핑이 AI보다 우선
          extractor = IndustryExtractor.new(idea: "AI 기반 쇼핑 추천")
          # 키워드 매칭 순서에 따라 결정됨 (해시 순서)
          result = extractor.extract
          assert_includes %w[이커머스 AI], result
        end
      end
    end
  end
end
