# frozen_string_literal: true

module Ai
  module Agents
    # 점수 에이전트
    # 아이디어 종합 점수 산출, 강점/약점 분석, 필요 전문성 도출
    # 모든 이전 에이전트 결과를 종합하여 최종 평가
    #
    # 입력: idea, follow_up_answers, previous_results[:summary, :target_user, :market_analysis, :strategy]
    # 출력: { score: { overall, weak_areas, strong_areas, improvement_tips }, required_expertise, confidence_level }
    class ScoringAgent < BaseAgent
      # 약점 영역 표준화 (ExpertScorePredictor와 매칭을 위해)
      STANDARD_WEAK_AREAS = [
        "시장 분석",
        "기술 구체화",
        "타겟 정의",
        "차별화",
        "수익 모델",
        "MVP 정의"
      ].freeze

      def initialize(context)
        @idea = context[:idea]
        @follow_up_answers = context[:follow_up_answers] || {}
        @previous_results = context[:previous_results] || {}
        super(llm: LangchainConfig.llm_for_agent(:scoring))
      end

      def analyze
        with_error_handling do
          response = llm.chat(messages: build_messages)
          log_token_usage(response, "ScoringAgent")

          result = parse_json_response(response.chat_completion)
          validate_result(result)
        end
      end

      def fallback_result
        {
          score: {
            overall: 50,
            weak_areas: [ "시장 분석", "기술 구체화" ],
            strong_areas: [ "아이디어 독창성" ],
            improvement_tips: [ "분석 결과를 기반으로 개선점을 확인하세요" ]
          },
          required_expertise: {
            roles: [ "Developer", "Designer" ],
            skills: [ "MVP", "스타트업" ],
            description: "분석 기반 전문성 추천이 필요합니다"
          },
          confidence_level: "Medium"
        }
      end

      private

      def build_messages
        format_messages_for_gemini(
          [ { role: "user", content: user_prompt } ],
          system_prompt: system_prompt
        )
      end

      def system_prompt
        weak_areas_list = STANDARD_WEAK_AREAS.join(", ")

        <<~PROMPT
          당신은 스타트업 아이디어 평가 전문가입니다.
          분석 결과를 종합하여 객관적인 점수와 개선점을 제시합니다.

          반드시 다음 JSON 형식으로만 응답하세요:
          ```json
          {
            "score": {
              "overall": 65,
              "weak_areas": ["약점 영역1", "약점 영역2"],
              "strong_areas": ["강점 영역1", "강점 영역2"],
              "improvement_tips": [
                "개선 팁 1",
                "개선 팁 2",
                "개선 팁 3"
              ]
            },
            "required_expertise": {
              "roles": ["필요한 역할1", "필요한 역할2"],
              "skills": ["스킬1", "스킬2", "스킬3", "스킬4", "스킬5"],
              "description": "필요한 전문성에 대한 설명 (50자 이내)"
            },
            "confidence_level": "High/Medium/Low"
          }
          ```

          규칙:
          - overall 점수는 0-100 사이 정수, 현실적으로 평가 (50-80 사이가 일반적)
          - weak_areas는 반드시 다음 중에서만 선택: #{weak_areas_list}
          - weak_areas는 2-3개 선택
          - strong_areas는 구체적인 강점 2-3개
          - improvement_tips는 실행 가능한 구체적인 조언 3개
          - roles는 Developer, Designer, Marketer, PM 등
          - skills는 구체적인 기술/역량 5개 이내
          - confidence_level은 분석 데이터 충분도에 따라 결정
          - JSON 외의 다른 텍스트는 출력하지 않음
        PROMPT
      end

      def user_prompt
        prompt = build_base_context
        prompt += build_previous_results_context
        prompt += "\n\n위 분석 결과를 종합하여 아이디어 점수와 필요 전문성을 평가해주세요."
        prompt
      end

      def build_base_context
        prompt = "## 아이디어\n#{@idea}"

        if @follow_up_answers.present?
          prompt += "\n\n## 추가 정보"
          @follow_up_answers.each do |key, value|
            next if value.blank?
            label = translate_key(key)
            prompt += "\n- #{label}: #{value}"
          end
        end

        prompt
      end

      def build_previous_results_context
        prompt = ""

        # 요약 결과
        if @previous_results[:summary].present?
          summary = @previous_results[:summary]
          prompt += "\n\n## 아이디어 요약"
          prompt += "\n- 핵심 요약: #{summary[:summary]}" if summary[:summary]
          prompt += "\n- 핵심 가치: #{summary[:core_value]}" if summary[:core_value]
          prompt += "\n- 문제 정의: #{summary[:problem_statement]}" if summary[:problem_statement]
        end

        # 타겟 사용자 결과
        if @previous_results[:target_user].present?
          target = @previous_results[:target_user]
          prompt += "\n\n## 타겟 사용자 분석"
          if target[:target_users].present?
            prompt += "\n- 주요 타겟: #{target[:target_users][:primary]}"
            if target[:target_users][:personas].present?
              prompt += "\n- 페르소나 수: #{target[:target_users][:personas].size}개 정의됨"
            end
          end
        end

        # 시장 분석 결과
        if @previous_results[:market_analysis].present?
          market = @previous_results[:market_analysis]
          prompt += "\n\n## 시장 분석"
          if market[:market_analysis].present?
            ma = market[:market_analysis]
            prompt += "\n- 시장 잠재력: #{ma[:potential]}" if ma[:potential]
            prompt += "\n- 시장 규모: #{ma[:market_size]}" if ma[:market_size]
            prompt += "\n- 경쟁사 수: #{ma[:competitors].size}개" if ma[:competitors].present?
            prompt += "\n- 차별화: #{ma[:differentiation]}" if ma[:differentiation]
          end
          if market[:market_opportunities].present?
            prompt += "\n- 기회 요인: #{market[:market_opportunities].size}개"
          end
          if market[:market_risks].present?
            prompt += "\n- 리스크 요인: #{market[:market_risks].size}개"
          end
        end

        # 전략 결과
        if @previous_results[:strategy].present?
          strategy = @previous_results[:strategy]
          prompt += "\n\n## 전략 분석"
          if strategy[:recommendations].present?
            rec = strategy[:recommendations]
            prompt += "\n- MVP 기능: #{rec[:mvp_features].size}개 정의됨" if rec[:mvp_features].present?
            prompt += "\n- 도전과제: #{rec[:challenges].size}개 식별됨" if rec[:challenges].present?
            prompt += "\n- 다음 단계: #{rec[:next_steps].size}개 계획됨" if rec[:next_steps].present?
          end
          if strategy[:actions].present?
            prompt += "\n- 액션 아이템: #{strategy[:actions].size}개"
          end
        end

        prompt
      end

      def translate_key(key)
        case key.to_s
        when "target" then "타겟 사용자"
        when "problem" then "해결하려는 문제"
        when "differentiator" then "차별화 포인트"
        else key.to_s.humanize
        end
      end

      def validate_result(result)
        return fallback_result if result[:error] || result[:raw_response]

        {
          score: validate_score(result[:score]),
          required_expertise: validate_required_expertise(result[:required_expertise]),
          confidence_level: result[:confidence_level] || "Medium"
        }
      end

      def validate_score(score)
        return fallback_result[:score] unless score.is_a?(Hash)

        overall = score[:overall].to_i
        overall = [ [ overall, 0 ].max, 100 ].min # 0-100 범위로 제한

        # weak_areas 표준화 (ExpertScorePredictor와 매칭을 위해)
        weak_areas = standardize_weak_areas(score[:weak_areas])

        {
          overall: overall,
          weak_areas: weak_areas,
          strong_areas: score[:strong_areas] || fallback_result[:score][:strong_areas],
          improvement_tips: score[:improvement_tips] || fallback_result[:score][:improvement_tips]
        }
      end

      def standardize_weak_areas(weak_areas)
        return fallback_result[:score][:weak_areas] unless weak_areas.is_a?(Array)

        # 표준 영역명과 가장 비슷한 것으로 매핑
        weak_areas.map do |area|
          STANDARD_WEAK_AREAS.find { |std| std.include?(area) || area.include?(std) } || area
        end.uniq.first(3)
      end

      def validate_required_expertise(expertise)
        return fallback_result[:required_expertise] unless expertise.is_a?(Hash)

        {
          roles: expertise[:roles] || fallback_result[:required_expertise][:roles],
          skills: expertise[:skills] || fallback_result[:required_expertise][:skills],
          description: expertise[:description] || fallback_result[:required_expertise][:description]
        }
      end
    end
  end
end
