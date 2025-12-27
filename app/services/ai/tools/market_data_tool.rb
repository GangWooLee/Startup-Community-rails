# frozen_string_literal: true

module Ai
  module Tools
    # 시장 데이터 조회 도구
    # 한국 주요 산업별 시장 규모, 성장률 데이터를 제공
    # 외부 API 없이 정적 데이터 기반으로 동작
    #
    # 사용법:
    #   tool = Ai::Tools::MarketDataTool.new
    #   tool.get_market_size(industry: "이커머스")
    #   tool.get_market_trends(industry: "에듀테크")
    #
    class MarketDataTool
      extend Langchain::ToolDefinition
      include Langchain::ToolDefinition::InstanceMethods

      # 한국 주요 산업별 시장 규모 데이터 (2024년 기준)
      MARKET_DATA = {
        # 테크/플랫폼
        "이커머스" => { size: "200조원", growth: "15%", year: 2024, tam: "500조원" },
        "푸드테크" => { size: "30조원", growth: "12%", year: 2024, tam: "80조원" },
        "에듀테크" => { size: "10조원", growth: "20%", year: 2024, tam: "30조원" },
        "핀테크" => { size: "25조원", growth: "18%", year: 2024, tam: "100조원" },
        "헬스테크" => { size: "8조원", growth: "25%", year: 2024, tam: "50조원" },
        "HR테크" => { size: "3조원", growth: "15%", year: 2024, tam: "15조원" },
        "프롭테크" => { size: "5조원", growth: "22%", year: 2024, tam: "30조원" },
        "리걸테크" => { size: "1조원", growth: "30%", year: 2024, tam: "10조원" },

        # 커뮤니티/소셜
        "소셜미디어" => { size: "5조원", growth: "8%", year: 2024, tam: "20조원" },
        "커뮤니티플랫폼" => { size: "2조원", growth: "15%", year: 2024, tam: "10조원" },
        "창업커뮤니티" => { size: "3000억원", growth: "20%", year: 2024, tam: "1조원" },
        "네트워킹" => { size: "1조원", growth: "12%", year: 2024, tam: "5조원" },

        # 콘텐츠/미디어
        "콘텐츠" => { size: "15조원", growth: "10%", year: 2024, tam: "50조원" },
        "OTT" => { size: "3조원", growth: "25%", year: 2024, tam: "10조원" },
        "웹툰" => { size: "2조원", growth: "15%", year: 2024, tam: "8조원" },
        "게임" => { size: "20조원", growth: "8%", year: 2024, tam: "50조원" },

        # 서비스
        "배달" => { size: "30조원", growth: "5%", year: 2024, tam: "50조원" },
        "모빌리티" => { size: "10조원", growth: "18%", year: 2024, tam: "40조원" },
        "공유경제" => { size: "3조원", growth: "15%", year: 2024, tam: "15조원" },
        "구독경제" => { size: "5조원", growth: "20%", year: 2024, tam: "20조원" },
        "외주플랫폼" => { size: "2조원", growth: "25%", year: 2024, tam: "10조원" },
        "프리랜서" => { size: "15조원", growth: "15%", year: 2024, tam: "30조원" },

        # B2B
        "SaaS" => { size: "8조원", growth: "25%", year: 2024, tam: "30조원" },
        "클라우드" => { size: "10조원", growth: "30%", year: 2024, tam: "40조원" },
        "AI" => { size: "5조원", growth: "40%", year: 2024, tam: "50조원" },
        "빅데이터" => { size: "3조원", growth: "20%", year: 2024, tam: "15조원" }
      }.freeze

      # 산업별 트렌드 데이터
      MARKET_TRENDS = {
        "이커머스" => "라이브커머스, 소셜커머스, D2C 브랜드가 급성장. 개인화 추천과 AI 도입 가속화.",
        "푸드테크" => "밀키트, 간편식, 식물성 대체육 시장 확대. 친환경 포장재 수요 증가.",
        "에듀테크" => "AI 튜터링, 메타버스 교육, 성인 리스킬링 시장 급성장. B2B 기업교육 확대.",
        "핀테크" => "간편결제 보편화, BNPL 서비스 확산, 마이데이터 기반 맞춤 금융 성장.",
        "헬스테크" => "비대면 진료 정착, 디지털 치료제 도입, 웨어러블 헬스케어 확산.",
        "HR테크" => "AI 채용, 원격근무 솔루션, 직원경험 플랫폼 수요 증가.",
        "프롭테크" => "부동산 중개 플랫폼 경쟁 심화, 공유오피스, 스마트홈 시장 성장.",
        "리걸테크" => "AI 계약서 분석, 법률 챗봇, 온라인 법률서비스 도입 초기 단계.",
        "소셜미디어" => "숏폼 동영상 중심 재편, 크리에이터 이코노미 성장.",
        "커뮤니티플랫폼" => "버티컬 커뮤니티 세분화, 익명성 기반 플랫폼 성장.",
        "창업커뮤니티" => "스타트업 네트워킹, 외주 매칭, 액셀러레이터 연계 플랫폼 성장.",
        "네트워킹" => "비즈니스 네트워킹, 동종업계 커뮤니티, 사이드프로젝트 매칭 수요 증가.",
        "콘텐츠" => "숏폼 콘텐츠, UGC 플랫폼, AI 생성 콘텐츠 시장 급성장.",
        "배달" => "배달비 인상으로 성장 둔화, 퀵커머스와 신선식품 배달 경쟁.",
        "모빌리티" => "전기차 충전 인프라, 자율주행, MaaS 플랫폼 투자 확대.",
        "SaaS" => "노코드/로우코드 도구, 협업 솔루션, 버티컬 SaaS 성장.",
        "AI" => "생성형 AI 도입 본격화, LLM 기반 서비스, AI 에이전트 시장 급성장.",
        "외주플랫폼" => "IT 외주, 디자인 외주, 마케팅 외주 플랫폼 성장. 품질 인증 중요성 증가.",
        "프리랜서" => "개발자, 디자이너, 마케터 중심 프리랜서 시장 확대. 긱 이코노미 정착."
      }.freeze

      # 함수 정의: 산업별 시장 규모 조회
      define_function :get_market_size, description: "한국 산업별 시장 규모와 성장률을 조회합니다" do
        property :industry, type: "string", description: "산업 분야명 (예: 이커머스, 에듀테크, SaaS)", required: true
      end

      # 함수 정의: 산업별 트렌드 조회
      define_function :get_market_trends, description: "한국 산업별 최신 시장 트렌드를 조회합니다" do
        property :industry, type: "string", description: "산업 분야명 (예: 이커머스, 에듀테크, SaaS)", required: true
      end

      # 함수 정의: 유사 산업 검색
      define_function :search_similar_industries, description: "키워드와 관련된 산업 분야를 검색합니다" do
        property :keyword, type: "string", description: "검색 키워드 (예: 교육, 금융, 배달)", required: true
      end

      def initialize
        # 외부 의존성 없음
      end

      # 산업별 시장 규모 조회
      def get_market_size(industry:)
        data = find_market_data(industry)

        if data
          content = <<~RESULT
            [시장 규모 정보]
            산업: #{industry}
            시장 규모: #{data[:size]} (#{data[:year]}년 기준)
            연평균 성장률: #{data[:growth]}
            TAM (총 시장 규모): #{data[:tam]}
          RESULT
          tool_response(content: content.strip)
        else
          similar = find_similar_industries(industry)
          content = if similar.any?
            "정확한 '#{industry}' 데이터가 없습니다. 유사 산업: #{similar.join(', ')}"
          else
            "해당 산업의 시장 데이터가 없습니다. 일반적인 추정 분석을 진행합니다."
          end
          tool_response(content: content)
        end
      end

      # 산업별 트렌드 조회
      def get_market_trends(industry:)
        trend = find_trend(industry)

        if trend
          content = <<~RESULT
            [시장 트렌드]
            산업: #{industry}
            트렌드: #{trend}
          RESULT
          tool_response(content: content.strip)
        else
          similar = find_similar_industries(industry)
          content = if similar.any?
            "정확한 '#{industry}' 트렌드가 없습니다. 유사 산업: #{similar.join(', ')}"
          else
            "해당 산업의 트렌드 데이터가 없습니다."
          end
          tool_response(content: content)
        end
      end

      # 유사 산업 검색
      def search_similar_industries(keyword:)
        matches = find_similar_industries(keyword)

        if matches.any?
          content = "관련 산업 분야: #{matches.join(', ')}"
          tool_response(content: content)
        else
          tool_response(content: "관련 산업 분야를 찾을 수 없습니다.")
        end
      end

      private

      def find_market_data(industry)
        # 정확한 매칭
        return MARKET_DATA[industry] if MARKET_DATA[industry]

        # 부분 매칭
        MARKET_DATA.find { |key, _| key.include?(industry) || industry.include?(key) }&.last
      end

      def find_trend(industry)
        # 정확한 매칭
        return MARKET_TRENDS[industry] if MARKET_TRENDS[industry]

        # 부분 매칭
        MARKET_TRENDS.find { |key, _| key.include?(industry) || industry.include?(key) }&.last
      end

      def find_similar_industries(keyword)
        MARKET_DATA.keys.select do |key|
          key.include?(keyword) || keyword.include?(key) ||
            keyword.chars.any? { |char| key.include?(char) }
        end.first(3)
      end
    end
  end
end
