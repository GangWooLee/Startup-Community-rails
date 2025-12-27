# frozen_string_literal: true

module Ai
  # 스타트업 아이디어 분석 Agent
  # 사용자가 입력한 아이디어를 분석하여 구조화된 피드백 제공
  # 100점 단일 종합점수 시스템
  class IdeaAnalyzer < BaseAgent
    SYSTEM_PROMPT = <<~PROMPT
      당신은 스타트업 아이디어 분석 전문가입니다.
      사용자가 제시한 아이디어를 분석하여 100점 만점으로 종합 평가해주세요.

      분석 결과는 반드시 아래 JSON 형식으로 반환해주세요:

      ```json
      {
        "summary": "아이디어의 핵심을 한 문장으로 요약 (예: '대학생을 위한 AI 기반 스터디 매칭 플랫폼')",
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
          "overall": 65,
          "weak_areas": ["시장 분석", "기술 구체화"],
          "strong_areas": ["아이디어 독창성", "타겟 명확성"],
          "improvement_tips": [
            "타겟 시장의 규모를 구체화하세요",
            "경쟁 서비스와의 차별점을 명확히 하세요",
            "MVP 기능을 더 좁혀보세요"
          ]
        },
        "actions": [
          {
            "title": "핵심 타깃 1줄 정의하기",
            "description": "주 사용자가 누구인지 한 문장으로 정리하세요"
          },
          {
            "title": "경쟁 서비스 분석",
            "description": "유사 서비스 3개 이상 조사하고 차별점 도출"
          },
          {
            "title": "MVP 기능 리스트",
            "description": "반드시 필요한 핵심 기능 5개 이내로 정리"
          }
        ],
        "required_expertise": {
          "roles": ["Developer", "Designer", "PM", "Marketer 등 필요한 역할"],
          "skills": ["React", "Node.js", "UI/UX", "마케팅 등 필요한 기술/스킬"],
          "description": "이 아이디어를 실현하기 위해 필요한 팀 구성을 한 문장으로 설명"
        }
      }
      ```

      ## 100점 평가 기준
      - 90-100점: 즉시 실행 가능한 훌륭한 아이디어
      - 70-89점: 보완하면 충분히 성공 가능
      - 50-69점: 핵심 영역 개선 필요
      - 30-49점: 전면적인 재검토 권장
      - 0-29점: 아이디어 재설계 필요

      ## 약점 영역 (weak_areas) 선택지
      - 시장 분석: 시장 규모, 경쟁사, 트렌드 파악이 부족
      - 기술 구체화: 기술 스택, 개발 방향이 불명확
      - 타겟 정의: 타겟 사용자가 명확하지 않음
      - 차별화: 기존 서비스와의 차별점이 약함
      - 수익 모델: 수익화 방안이 불분명
      - MVP 정의: 핵심 기능 정의가 부족

      ## 강점 영역 (strong_areas) 선택지
      - 아이디어 독창성: 새로운 관점의 아이디어
      - 타겟 명확성: 타겟 사용자가 잘 정의됨
      - 시장 기회: 시장 진입 타이밍이 좋음
      - 기술 명확성: 기술 구현 방향이 명확
      - 차별화 강점: 뚜렷한 차별화 포인트 보유

      ## 분석 시 고려사항
      - 한국 시장 상황을 우선적으로 고려
      - 실현 가능한 MVP 중심으로 조언
      - 초기 창업자가 이해하기 쉬운 언어 사용
      - 긍정적이면서도 현실적인 피드백 제공
      - actions는 점수를 올리기 위해 지금 바로 할 수 있는 구체적인 행동 3개
    PROMPT

    def initialize(idea)
      super()
      @idea = idea
    end

    # 아이디어 분석 실행
    def analyze
      with_error_handling do
        messages = build_chat_messages
        response = llm.chat(messages: messages)

        # 빈 응답 체크
        raise "Empty response from AI" if response.chat_completion.blank?

        # 토큰 사용량 로깅
        log_token_usage(response, "IdeaAnalyzer")

        result = parse_json_response(response.chat_completion)

        # 분석 결과 검증 및 기본값 설정
        validate_and_normalize(result)
      end
    end

    private

    # LLM 제공자에 따라 적절한 메시지 형식 반환
    def build_chat_messages
      if using_gemini?
        # Gemini: parts 형식 사용, system prompt를 첫 메시지로
        format_messages_for_gemini(
          [{ role: "user", content: build_user_prompt }],
          system_prompt: SYSTEM_PROMPT
        )
      else
        # OpenAI: 표준 형식
        [
          { role: "system", content: SYSTEM_PROMPT },
          { role: "user", content: build_user_prompt }
        ]
      end
    end

    def build_user_prompt
      <<~PROMPT
        다음 스타트업 아이디어를 분석해주세요:

        #{@idea}

        위 아이디어에 대해 100점 만점으로 종합 평가하고, 약점/강점 영역, 개선 팁, 지금 바로 할 수 있는 액션 3개를 제시해주세요.
      PROMPT
    end

    # 분석 결과 검증 및 기본값 설정
    def validate_and_normalize(result)
      return fallback_response if result[:error] || result[:raw_response]

      # 점수 정규화
      score = normalize_score(result[:score])

      {
        summary: result[:summary] || "분석 결과를 가져오는 중 오류가 발생했습니다.",
        target_users: result[:target_users] || default_target_users,
        market_analysis: result[:market_analysis] || default_market_analysis,
        recommendations: result[:recommendations] || default_recommendations,
        score: score,
        actions: result[:actions] || default_actions,
        required_expertise: result[:required_expertise] || default_required_expertise,
        analyzed_at: Time.current,
        idea: @idea
      }
    end

    # 점수 구조 정규화
    def normalize_score(score_data)
      return default_score if score_data.nil?

      overall = score_data[:overall] || 0
      # 1-10 점수를 받았다면 10배로 변환
      overall = overall * 10 if overall > 0 && overall <= 10

      {
        overall: [[overall, 0].max, 100].min, # 0-100 범위로 제한
        weak_areas: score_data[:weak_areas] || [],
        strong_areas: score_data[:strong_areas] || [],
        improvement_tips: score_data[:improvement_tips] || []
      }
    end

    def fallback_response
      {
        summary: "아이디어 분석을 완료하지 못했습니다. 잠시 후 다시 시도해주세요.",
        target_users: default_target_users,
        market_analysis: default_market_analysis,
        recommendations: default_recommendations,
        score: default_score,
        actions: default_actions,
        required_expertise: default_required_expertise,
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
        overall: 0,
        weak_areas: [],
        strong_areas: [],
        improvement_tips: []
      }
    end

    def default_actions
      [
        { title: "타겟 사용자 정의", description: "주 사용자가 누구인지 명확히 정리하세요" },
        { title: "경쟁 분석", description: "유사 서비스를 조사하고 차별점을 찾으세요" },
        { title: "MVP 기능 정리", description: "핵심 기능을 5개 이내로 좁혀보세요" }
      ]
    end

    def default_required_expertise
      {
        roles: [],
        skills: [],
        description: ""
      }
    end
  end
end
