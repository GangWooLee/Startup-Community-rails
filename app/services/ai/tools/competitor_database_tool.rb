# frozen_string_literal: true

module Ai
  module Tools
    # 경쟁사 데이터베이스 조회 도구
    # 한국 스타트업/서비스 분야별 주요 경쟁사 정보 제공
    # 외부 API 없이 정적 데이터 기반으로 동작
    #
    # 사용법:
    #   tool = Ai::Tools::CompetitorDatabaseTool.new
    #   tool.find_competitors(category: "이커머스")
    #   tool.get_competitor_info(name: "토스")
    #
    class CompetitorDatabaseTool
      extend Langchain::ToolDefinition
      include Langchain::ToolDefinition::InstanceMethods

      # 분야별 주요 경쟁사/서비스 데이터
      COMPETITORS = {
        # 이커머스/쇼핑
        "이커머스" => ["쿠팡", "네이버쇼핑", "11번가", "G마켓", "옥션", "위메프", "티몬"],
        "패션" => ["무신사", "지그재그", "에이블리", "29CM", "W컨셉", "하이버", "브랜디"],
        "중고거래" => ["당근마켓", "번개장터", "중고나라", "헬로마켓"],
        "명품" => ["발란", "트렌비", "머스트잇", "캐치패션"],

        # 배달/음식
        "배달" => ["배달의민족", "요기요", "쿠팡이츠"],
        "식품" => ["마켓컬리", "오아시스마켓", "쿠팡프레시", "네이버장보기"],
        "밀키트" => ["마이셰프", "프레시지", "얌샘", "잇츠온"],

        # 금융/핀테크
        "금융" => ["토스", "카카오뱅크", "케이뱅크", "네이버페이", "카카오페이"],
        "핀테크" => ["토스", "뱅크샐러드", "핀다", "페이히어"],
        "투자" => ["토스증권", "카카오페이증권", "삼성증권", "키움증권"],
        "보험" => ["토스보험", "카카오페이손해보험", "캐롯손해보험"],

        # 채용/HR
        "채용" => ["원티드", "로켓펀치", "리멤버", "잡플래닛", "사람인", "잡코리아"],
        "HR테크" => ["플렉스", "그리팅", "샤플", "원티드스페이스"],
        "외주" => ["크몽", "숨고", "라우드소싱", "위시켓", "프리모아"],
        "프리랜서" => ["크몽", "탈잉", "클래스101", "숨고"],

        # 부동산
        "부동산" => ["직방", "다방", "피터팬", "호갱노노", "네이버부동산"],
        "공유오피스" => ["위워크", "패스트파이브", "스파크플러스", "마이워크스페이스"],

        # 교육
        "에듀테크" => ["클래스101", "인프런", "유데미", "코세라", "패스트캠퍼스"],
        "온라인강의" => ["클래스101", "탈잉", "프립", "인프런"],
        "코딩교육" => ["코드스테이츠", "부트캠프", "스파르타코딩클럽", "위코드"],

        # 헬스케어
        "헬스테크" => ["닥터나우", "굿닥", "똑닥", "캐시워크"],
        "피트니스" => ["프릭", "버핏서울", "힐리어리"],

        # 모빌리티
        "모빌리티" => ["카카오T", "타다", "쏘카", "그린카"],
        "카셰어링" => ["쏘카", "그린카", "피플카"],
        "킥보드" => ["킥고잉", "지쿠터", "빔", "라임"],

        # 콘텐츠
        "OTT" => ["넷플릭스", "웨이브", "티빙", "쿠팡플레이", "왓챠"],
        "웹툰" => ["네이버웹툰", "카카오페이지", "리디", "레진코믹스"],
        "음악" => ["멜론", "지니뮤직", "플로", "스포티파이", "바이브"],

        # 소셜/커뮤니티
        "소셜미디어" => ["인스타그램", "틱톡", "트위터", "스레드", "블루스카이"],
        "커뮤니티" => ["에브리타임", "블라인드", "디시인사이드", "뽐뿌", "클리앙"],
        "창업커뮤니티" => ["디스콰이어트", "스타트업베이", "비사이드", "오픈서베이"],
        "네트워킹" => ["링크드인", "리멤버", "로켓펀치", "원티드"],

        # B2B/SaaS
        "SaaS" => ["채널톡", "노션", "잔디", "플렉스", "샤플"],
        "협업도구" => ["노션", "슬랙", "잔디", "두레이", "콜라비"],
        "마케팅" => ["채널톡", "그루비", "빅인사이트", "와이즐리"],
        "CRM" => ["채널톡", "센드버드", "그루비"],

        # AI
        "AI" => ["뤼튼", "타입캐스트", "보이스루", "스켈터랩스"],
        "챗봇" => ["채널톡", "깃플", "센드버드", "카카오i"]
      }.freeze

      # 주요 스타트업 상세 정보
      COMPANY_INFO = {
        "토스" => {
          founded: 2013,
          category: "핀테크",
          valuation: "15조원+",
          users: "2000만+",
          features: ["간편송금", "투자", "보험", "대출", "신용점수"],
          strength: "금융 슈퍼앱, 직관적인 UX"
        },
        "쿠팡" => {
          founded: 2010,
          category: "이커머스",
          valuation: "60조원+",
          users: "3000만+",
          features: ["로켓배송", "로켓프레시", "쿠팡이츠", "쿠팡플레이"],
          strength: "물류 인프라, 로켓배송"
        },
        "당근마켓" => {
          founded: 2015,
          category: "중고거래",
          valuation: "3조원+",
          users: "3000만+",
          features: ["중고거래", "동네업체", "알바", "부동산"],
          strength: "하이퍼로컬, 동네 신뢰 기반"
        },
        "무신사" => {
          founded: 2001,
          category: "패션",
          valuation: "5조원+",
          users: "1000만+",
          features: ["패션 쇼핑", "스트릿 브랜드", "무신사 스탠다드"],
          strength: "MZ세대 패션 플랫폼 1위"
        },
        "배달의민족" => {
          founded: 2010,
          category: "배달",
          valuation: "4조원+ (인수)",
          users: "2000만+",
          features: ["음식 배달", "B마트", "배민상회"],
          strength: "시장점유율 1위, 브랜드 인지도"
        },
        "원티드" => {
          founded: 2015,
          category: "채용",
          valuation: "5000억원+",
          users: "500만+",
          features: ["AI 채용매칭", "커리어", "리퍼럴"],
          strength: "IT/스타트업 채용 특화"
        },
        "클래스101" => {
          founded: 2018,
          category: "에듀테크",
          valuation: "3000억원+",
          users: "200만+",
          features: ["온라인 클래스", "크리에이터 강의", "취미/자기계발"],
          strength: "크리에이터 중심 교육 콘텐츠"
        },
        "직방" => {
          founded: 2010,
          category: "부동산",
          valuation: "2조원+",
          users: "1000만+",
          features: ["원룸/오피스텔", "아파트", "빌라", "삼성SDS 인수"],
          strength: "부동산 정보 플랫폼 1위"
        },
        "채널톡" => {
          founded: 2014,
          category: "SaaS",
          valuation: "2000억원+",
          users: "10만+ 기업",
          features: ["고객상담", "마케팅 자동화", "CRM"],
          strength: "B2B 올인원 솔루션"
        },
        "디스콰이어트" => {
          founded: 2021,
          category: "창업커뮤니티",
          valuation: "비공개",
          users: "10만+",
          features: ["IT 제품 런칭", "스타트업 커뮤니티", "사이드프로젝트"],
          strength: "프로덕트 메이커 커뮤니티"
        }
      }.freeze

      # 함수 정의: 분야별 경쟁사 조회
      define_function :find_competitors, description: "사업 분야별 주요 경쟁사 목록을 조회합니다" do
        property :category, type: "string", description: "사업 분야 (예: 이커머스, 핀테크, 채용)", required: true
      end

      # 함수 정의: 기업 상세 정보 조회
      define_function :get_competitor_info, description: "특정 기업/서비스의 상세 정보를 조회합니다" do
        property :name, type: "string", description: "기업명 (예: 토스, 쿠팡, 당근마켓)", required: true
      end

      # 함수 정의: 키워드로 경쟁사 검색
      define_function :search_competitors, description: "키워드와 관련된 경쟁사를 검색합니다" do
        property :keyword, type: "string", description: "검색 키워드", required: true
      end

      def initialize
        # 외부 의존성 없음
      end

      # 분야별 경쟁사 조회
      def find_competitors(category:)
        competitors = find_by_category(category)

        if competitors.any?
          content = <<~RESULT
            [#{category} 분야 주요 경쟁사]
            #{competitors.map.with_index(1) { |c, i| "#{i}. #{c}" }.join("\n")}

            총 #{competitors.size}개 서비스
          RESULT
          tool_response(content: content.strip)
        else
          similar_categories = find_similar_categories(category)
          content = if similar_categories.any?
            "정확한 '#{category}' 분야가 없습니다. 유사 분야: #{similar_categories.join(', ')}"
          else
            "해당 분야의 경쟁사 데이터가 없습니다."
          end
          tool_response(content: content)
        end
      end

      # 기업 상세 정보 조회
      def get_competitor_info(name:)
        info = COMPANY_INFO[name]

        if info
          content = <<~RESULT
            [#{name} 상세 정보]
            설립: #{info[:founded]}년
            분야: #{info[:category]}
            기업가치: #{info[:valuation]}
            사용자: #{info[:users]}
            주요 기능: #{info[:features].join(', ')}
            강점: #{info[:strength]}
          RESULT
          tool_response(content: content.strip)
        else
          tool_response(content: "#{name}의 상세 정보가 없습니다.")
        end
      end

      # 키워드로 경쟁사 검색
      def search_competitors(keyword:)
        # 모든 경쟁사에서 키워드 검색
        matches = []
        COMPETITORS.each do |category, companies|
          companies.each do |company|
            if company.include?(keyword) || keyword.include?(company)
              matches << { name: company, category: category }
            end
          end
        end

        # 카테고리에서도 검색
        COMPETITORS.each do |category, companies|
          if category.include?(keyword) || keyword.include?(category)
            companies.first(3).each do |company|
              matches << { name: company, category: category } unless matches.any? { |m| m[:name] == company }
            end
          end
        end

        if matches.any?
          content = matches.first(10).map { |m| "- #{m[:name]} (#{m[:category]})" }.join("\n")
          tool_response(content: "검색 결과:\n#{content}")
        else
          tool_response(content: "검색 결과가 없습니다.")
        end
      end

      private

      def find_by_category(category)
        # 정확한 매칭
        return COMPETITORS[category] if COMPETITORS[category]

        # 부분 매칭
        COMPETITORS.find { |key, _| key.include?(category) || category.include?(key) }&.last || []
      end

      def find_similar_categories(keyword)
        COMPETITORS.keys.select do |key|
          key.include?(keyword) || keyword.include?(key) ||
            keyword.chars.any? { |char| key.include?(char) }
        end.first(3)
      end
    end
  end
end
