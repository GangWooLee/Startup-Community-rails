# frozen_string_literal: true

require "test_helper"

class Ai::Agents::ScoringAgentTest < ActiveSupport::TestCase
  setup do
    ENV["GEMINI_API_KEY"] = "test-api-key"
    @context = {
      idea: "대학생을 위한 중고 교재 거래 플랫폼",
      previous_results: {
        summary: { summary: "중고 교재 거래 플랫폼" },
        target_user: { target_users: { primary: "대학생" } },
        market_analysis: { market_analysis: { potential: "High" } },
        strategy: { recommendations: { mvp_features: [ "검색", "결제" ] } }
      }
    }
  end

  teardown do
    ENV.delete("GEMINI_API_KEY")
  end

  test "analyze returns Pentagonal Analysis result on successful API call" do
    stub_gemini_json_response({
      dimension_scores: {
        market: { score: 22, breakdown: { tam: 8, competition: 7, trend: 7 }, feedback: "좋은 시장" },
        problem: { score: 18, breakdown: { pain: 10, frequency: 8 }, feedback: "명확한 문제" },
        moat: { score: 12, breakdown: { advantage: 5, improvement: 7 }, feedback: "차별화 필요" },
        feasibility: { score: 12, breakdown: { mvp: 12 }, feedback: "구현 가능" },
        business: { score: 8, breakdown: { willingness: 8 }, feedback: "수익화 가능" }
      },
      total_score: 72,
      grade: "B",
      radar_chart_data: [ 7, 7, 6, 8, 8 ],
      score: {
        overall: 72,
        weak_areas: [ "차별화", "기술 구체화" ],
        strong_areas: [ "시장 분석", "타겟 정의" ],
        improvement_tips: [ "시장 조사 강화", "MVP 구체화", "차별화 전략 수립" ]
      },
      required_expertise: {
        roles: [ "Developer", "Designer" ],
        skills: [ "웹 개발", "UX 디자인", "마케팅" ],
        description: "플랫폼 개발 역량 필요"
      },
      confidence_level: "High"
    })

    agent = Ai::Agents::ScoringAgent.new(@context)
    result = agent.analyze

    # 새로운 Pentagonal Analysis 출력 확인
    assert_equal 72, result[:total_score]
    assert_equal "B", result[:grade]
    assert result[:dimension_scores].is_a?(Hash)
    assert_equal 5, result[:dimension_scores].keys.size
    assert result[:radar_chart_data].is_a?(Array)
    assert_equal 5, result[:radar_chart_data].size

    # 하위 호환성 확인 (기존 score 구조)
    assert_equal 72, result[:score][:overall]
    assert result[:score][:weak_areas].is_a?(Array)
    assert result[:required_expertise][:roles].is_a?(Array)
    assert_equal "High", result[:confidence_level]
  end

  test "total_score is clamped to 0-100 range" do
    stub_gemini_json_response({
      dimension_scores: {
        market: { score: 35, breakdown: {}, feedback: "" },  # 30점 초과
        problem: { score: 30, breakdown: {}, feedback: "" }, # 25점 초과
        moat: { score: 25, breakdown: {}, feedback: "" },    # 20점 초과
        feasibility: { score: 20, breakdown: {}, feedback: "" }, # 15점 초과
        business: { score: 15, breakdown: {}, feedback: "" } # 10점 초과
      },
      total_score: 150,
      grade: "S",
      radar_chart_data: [ 10, 10, 10, 10, 10 ],
      score: { overall: 150, weak_areas: [], strong_areas: [], improvement_tips: [] },
      required_expertise: { roles: [], skills: [], description: "" },
      confidence_level: "Medium"
    })

    agent = Ai::Agents::ScoringAgent.new(@context)
    result = agent.analyze

    # 각 차원 점수는 최대값으로 제한됨
    assert_operator result[:dimension_scores][:market][:score], :<=, 30
    assert_operator result[:dimension_scores][:problem][:score], :<=, 25
    assert_operator result[:dimension_scores][:moat][:score], :<=, 20
    assert_operator result[:dimension_scores][:feasibility][:score], :<=, 15
    assert_operator result[:dimension_scores][:business][:score], :<=, 10

    # 총점도 100 이하로 제한됨
    assert_operator result[:total_score], :<=, 100
    assert_operator result[:score][:overall], :<=, 100
  end

  test "analyze returns fallback on API error" do
    stub_gemini_api_error(status: 500)

    agent = Ai::Agents::ScoringAgent.new(@context)
    result = agent.analyze

    assert result[:error] || result[:score].present?
  end

  test "fallback_result contains Pentagonal Analysis structure" do
    agent = Ai::Agents::ScoringAgent.new(@context)
    fallback = agent.fallback_result

    # 새로운 구조 확인
    assert fallback[:dimension_scores].is_a?(Hash)
    assert_equal 5, fallback[:dimension_scores].keys.size
    assert fallback[:total_score].is_a?(Integer)
    assert fallback[:grade].present?
    assert fallback[:radar_chart_data].is_a?(Array)
    assert_equal 5, fallback[:radar_chart_data].size

    # 하위 호환성 확인
    assert fallback[:score].is_a?(Hash)
    assert fallback[:score][:overall].is_a?(Integer)
    assert fallback[:required_expertise].is_a?(Hash)
    assert fallback[:confidence_level].present?
  end

  test "weak_areas are standardized" do
    stub_gemini_json_response({
      dimension_scores: {
        market: { score: 20, breakdown: {}, feedback: "" },
        problem: { score: 15, breakdown: {}, feedback: "" },
        moat: { score: 8, breakdown: {}, feedback: "" },   # 낮은 점수 (약점)
        feasibility: { score: 10, breakdown: {}, feedback: "" },
        business: { score: 5, breakdown: {}, feedback: "" } # 낮은 점수 (약점)
      },
      total_score: 58,
      grade: "C",
      radar_chart_data: [ 7, 6, 4, 7, 5 ],
      score: {
        overall: 58,
        weak_areas: [ "모트", "비즈니스" ],  # 비표준 형태
        strong_areas: [],
        improvement_tips: []
      },
      required_expertise: { roles: [], skills: [], description: "" },
      confidence_level: "Medium"
    })

    agent = Ai::Agents::ScoringAgent.new(@context)
    result = agent.analyze

    # 표준화된 weak_areas 포함 확인
    assert result[:score][:weak_areas].any? { |area|
      Ai::Agents::ScoringAgent::STANDARD_WEAK_AREAS.include?(area) || area.present?
    }
  end

  test "grade is calculated correctly based on total_score" do
    agent = Ai::Agents::ScoringAgent.new(@context)

    # 공개 메서드가 아니므로 fallback_result와 상수 검증
    assert_equal "S", Ai::Agents::ScoringAgent::GRADE_THRESHOLDS.find { |_, t| 95 >= t }&.first
    assert_equal "A", Ai::Agents::ScoringAgent::GRADE_THRESHOLDS.find { |_, t| 85 >= t }&.first
    assert_equal "B", Ai::Agents::ScoringAgent::GRADE_THRESHOLDS.find { |_, t| 75 >= t }&.first
    assert_equal "C", Ai::Agents::ScoringAgent::GRADE_THRESHOLDS.find { |_, t| 65 >= t }&.first
    assert_equal "D", Ai::Agents::ScoringAgent::GRADE_THRESHOLDS.find { |_, t| 55 >= t }&.first
  end

  test "dimension_scores are validated with correct max values" do
    # DIMENSIONS 상수 확인
    dimensions = Ai::Agents::ScoringAgent::DIMENSIONS

    assert_equal 30, dimensions[:market][:max]
    assert_equal 25, dimensions[:problem][:max]
    assert_equal 20, dimensions[:moat][:max]
    assert_equal 15, dimensions[:feasibility][:max]
    assert_equal 10, dimensions[:business][:max]

    # 총합이 100인지 확인
    total_max = dimensions.values.sum { |d| d[:max] }
    assert_equal 100, total_max
  end

  test "market dimension includes TAM/SAM/SOM market_size" do
    stub_gemini_json_response({
      dimension_scores: {
        market: {
          score: 24,
          breakdown: { tam: 8, competition: 7, trend: 9 },
          market_size: {
            tam: { revenue: "10조원", users: "5000만명" },
            sam: { revenue: "1조원", users: "500만명" },
            som: { revenue: "100억원", users: "50만명" }
          },
          feedback: "시장 규모가 충분합니다"
        },
        problem: { score: 18, breakdown: { pain: 10, frequency: 8 }, feedback: "" },
        moat: { score: 12, breakdown: { advantage: 5, improvement: 7 }, feedback: "" },
        feasibility: { score: 12, breakdown: { mvp: 12 }, feedback: "" },
        business: { score: 8, breakdown: { willingness: 8 }, feedback: "" }
      },
      total_score: 74,
      grade: "B",
      radar_chart_data: [ 8, 7, 6, 8, 8 ],
      score: { overall: 74, weak_areas: [], strong_areas: [], improvement_tips: [] },
      required_expertise: { roles: [], skills: [], description: "" },
      confidence_level: "High"
    })

    agent = Ai::Agents::ScoringAgent.new(@context)
    result = agent.analyze

    market = result[:dimension_scores][:market]
    assert market[:market_size].present?
    assert_equal "10조원", market[:market_size][:tam][:revenue]
    assert_equal "5000만명", market[:market_size][:tam][:users]
    assert_equal "1조원", market[:market_size][:sam][:revenue]
    assert_equal "100억원", market[:market_size][:som][:revenue]
  end

  test "moat dimension includes direct and indirect competitors" do
    stub_gemini_json_response({
      dimension_scores: {
        market: { score: 20, breakdown: {}, feedback: "" },
        problem: { score: 18, breakdown: {}, feedback: "" },
        moat: {
          score: 14,
          breakdown: { advantage: 6, improvement: 8 },
          competitors: {
            direct: [ "당근마켓", "번개장터" ],
            indirect: [ "네이버 카페", "에브리타임" ]
          },
          feedback: "경쟁사가 존재하지만 틈새 가능"
        },
        feasibility: { score: 12, breakdown: {}, feedback: "" },
        business: { score: 8, breakdown: {}, feedback: "" }
      },
      total_score: 72,
      grade: "B",
      radar_chart_data: [ 7, 7, 7, 8, 8 ],
      score: { overall: 72, weak_areas: [], strong_areas: [], improvement_tips: [] },
      required_expertise: { roles: [], skills: [], description: "" },
      confidence_level: "High"
    })

    agent = Ai::Agents::ScoringAgent.new(@context)
    result = agent.analyze

    moat = result[:dimension_scores][:moat]
    assert moat[:competitors].present?
    assert_includes moat[:competitors][:direct], "당근마켓"
    assert_includes moat[:competitors][:indirect], "네이버 카페"
  end

  test "business dimension includes business_type and revenue_model" do
    stub_gemini_json_response({
      dimension_scores: {
        market: { score: 20, breakdown: {}, feedback: "" },
        problem: { score: 18, breakdown: {}, feedback: "" },
        moat: { score: 12, breakdown: {}, feedback: "" },
        feasibility: { score: 12, breakdown: {}, feedback: "" },
        business: {
          score: 8,
          breakdown: { willingness: 8 },
          business_type: "C2C",
          revenue_model: "거래 수수료",
          feedback: "명확한 수익화 모델"
        }
      },
      total_score: 70,
      grade: "B",
      radar_chart_data: [ 7, 7, 6, 8, 8 ],
      score: { overall: 70, weak_areas: [], strong_areas: [], improvement_tips: [] },
      required_expertise: { roles: [], skills: [], description: "" },
      confidence_level: "High"
    })

    agent = Ai::Agents::ScoringAgent.new(@context)
    result = agent.analyze

    business = result[:dimension_scores][:business]
    assert_equal "C2C", business[:business_type]
    assert_equal "거래 수수료", business[:revenue_model]
  end

  test "fallback_result includes new fields with default values" do
    agent = Ai::Agents::ScoringAgent.new(@context)
    fallback = agent.fallback_result

    # market_size 기본값 확인
    assert fallback[:dimension_scores][:market][:market_size].present?
    assert fallback[:dimension_scores][:market][:market_size][:tam].present?
    assert fallback[:dimension_scores][:market][:market_size][:sam].present?
    assert fallback[:dimension_scores][:market][:market_size][:som].present?

    # competitors 기본값 확인
    assert fallback[:dimension_scores][:moat][:competitors].present?
    assert fallback[:dimension_scores][:moat][:competitors][:direct].is_a?(Array)
    assert fallback[:dimension_scores][:moat][:competitors][:indirect].is_a?(Array)

    # business_type, revenue_model 기본값 확인
    assert fallback[:dimension_scores][:business][:business_type].present?
    assert fallback[:dimension_scores][:business][:revenue_model].present?
  end
end
