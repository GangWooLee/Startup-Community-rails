# frozen_string_literal: true

module Ai
  module Agents
    module MarketAnalysis
      # 아이디어에서 산업 분야 추출 서비스
      #
      # 키워드 매칭으로 아이디어의 산업 분야를 분류
      # 12개 주요 산업 카테고리 지원
      #
      # 사용 예:
      #   extractor = IndustryExtractor.new(idea: "음식 배달 앱", follow_up_answers: {})
      #   extractor.extract  # => "푸드테크"
      class IndustryExtractor
        INDUSTRY_KEYWORDS = {
          "이커머스" => %w[쇼핑 커머스 판매 마켓 온라인스토어],
          "핀테크" => %w[금융 결제 투자 송금 뱅킹 보험],
          "에듀테크" => %w[교육 학습 강의 튜터 온라인교육],
          "헬스테크" => %w[건강 의료 헬스케어 병원 진료],
          "푸드테크" => %w[음식 배달 식품 레스토랑 밀키트],
          "모빌리티" => %w[이동 차량 배차 택시 킥보드],
          "프롭테크" => %w[부동산 집 매물 임대 전세],
          "HR테크" => %w[채용 인사 HR 구인 구직],
          "SaaS" => %w[소프트웨어 서비스 B2B 기업용],
          "AI" => %w[인공지능 AI 머신러닝 자동화],
          "커뮤니티" => %w[커뮤니티 네트워킹 소셜 플랫폼],
          "외주" => %w[외주 프리랜서 개발자 디자이너 매칭]
        }.freeze

        DEFAULT_INDUSTRY = "스타트업"

        attr_reader :idea, :follow_up_answers

        def initialize(idea:, follow_up_answers: {})
          @idea = idea
          @follow_up_answers = follow_up_answers || {}
        end

        def extract
          idea_text = build_search_text
          find_matching_industry(idea_text)
        end

        private

        def build_search_text
          "#{idea} #{follow_up_answers.values.join(' ')}"
        end

        def find_matching_industry(text)
          INDUSTRY_KEYWORDS.each do |industry, keywords|
            return industry if keywords.any? { |kw| text.include?(kw) }
          end

          DEFAULT_INDUSTRY
        end
      end
    end
  end
end
