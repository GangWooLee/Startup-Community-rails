# frozen_string_literal: true

module Ai
  # 스타트업 아이디어 분석 Agent
  # 사용자가 입력한 아이디어를 분석하여 구조화된 피드백 제공
  class IdeaAnalyzer < BaseAgent
    SYSTEM_PROMPT = <<~PROMPT
      당신은 스타트업 아이디어 분석 전문가입니다.
      사용자가 제시한 아이디어를 분석하여 다음 항목에 대해 상세히 평가해주세요.

      분석 결과는 반드시 아래 JSON 형식으로 반환해주세요:

      ```json
      {
        "summary": "아이디어의 핵심을 2-3문장으로 요약",
        "target_users": {
          "primary": "주요 타겟 사용자 설명",
          "characteristics": ["특성1", "특성2", "특성3"]
        },
        "market_analysis": {
          "potential": "시장 잠재력 평가 (높음/중간/낮음)",
          "competitors": ["경쟁사/서비스1", "경쟁사/서비스2"],
          "differentiation": "차별화 포인트"
        },
        "recommendations": {
          "mvp_features": ["MVP 핵심 기능1", "MVP 핵심 기능2", "MVP 핵심 기능3"],
          "challenges": ["예상 도전과제1", "예상 도전과제2"],
          "next_steps": ["다음 단계1", "다음 단계2", "다음 단계3"]
        },
        "score": {
          "innovation": 1-10,
          "feasibility": 1-10,
          "market_fit": 1-10,
          "overall": 1-10
        }
      }
      ```

      분석 시 다음을 고려해주세요:
      - 한국 시장 상황을 우선적으로 고려
      - 실현 가능한 MVP 중심으로 조언
      - 초기 창업자가 이해하기 쉬운 언어 사용
      - 긍정적이면서도 현실적인 피드백 제공
    PROMPT

    def initialize(idea)
      super()
      @idea = idea
    end

    # 아이디어 분석 실행
    def analyze
      with_error_handling do
        response = llm.chat(
          messages: [
            { role: "system", content: SYSTEM_PROMPT },
            { role: "user", content: build_user_prompt }
          ]
        )

        result = parse_json_response(response.chat_completion)

        # 분석 결과 검증 및 기본값 설정
        validate_and_normalize(result)
      end
    end

    private

    def build_user_prompt
      <<~PROMPT
        다음 스타트업 아이디어를 분석해주세요:

        #{@idea}

        위 아이디어에 대해 시장성, 타겟 사용자, 차별화 포인트, MVP 제안을 포함한 종합적인 분석을 해주세요.
      PROMPT
    end

    # 분석 결과 검증 및 기본값 설정
    def validate_and_normalize(result)
      return fallback_response if result[:error] || result[:raw_response]

      {
        summary: result[:summary] || "분석 결과를 가져오는 중 오류가 발생했습니다.",
        target_users: result[:target_users] || default_target_users,
        market_analysis: result[:market_analysis] || default_market_analysis,
        recommendations: result[:recommendations] || default_recommendations,
        score: result[:score] || default_score,
        analyzed_at: Time.current,
        idea: @idea
      }
    end

    def fallback_response
      {
        summary: "아이디어 분석을 완료하지 못했습니다. 잠시 후 다시 시도해주세요.",
        target_users: default_target_users,
        market_analysis: default_market_analysis,
        recommendations: default_recommendations,
        score: default_score,
        analyzed_at: Time.current,
        idea: @idea,
        error: true
      }
    end

    def default_target_users
      {
        primary: "분석 중...",
        characteristics: []
      }
    end

    def default_market_analysis
      {
        potential: "분석 중",
        competitors: [],
        differentiation: "분석 중..."
      }
    end

    def default_recommendations
      {
        mvp_features: [],
        challenges: [],
        next_steps: []
      }
    end

    def default_score
      {
        innovation: 0,
        feasibility: 0,
        market_fit: 0,
        overall: 0
      }
    end
  end
end
