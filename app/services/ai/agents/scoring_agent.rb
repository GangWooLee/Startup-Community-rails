# frozen_string_literal: true

module Ai
  module Agents
    # 점수 에이전트 - Pentagonal Analysis (5차원 VC 스타일 평가)
    # 아이디어 종합 점수 산출, 강점/약점 분석, 필요 전문성 도출
    # 모든 이전 에이전트 결과를 종합하여 최종 평가
    #
    # 입력: idea, follow_up_answers, previous_results[:summary, :target_user, :market_analysis, :strategy]
    # 출력: {
    #   dimension_scores: { market, problem, moat, feasibility, business },
    #   total_score, grade, radar_chart_data,
    #   score: { overall, weak_areas, strong_areas, improvement_tips },
    #   required_expertise, confidence_level
    # }
    class ScoringAgent < BaseAgent
      # 5차원 평가 기준 (Pentagonal Analysis)
      DIMENSIONS = {
        market: { weight: 30, max: 30, label: "시장성", korean: "시장 분석" },
        problem: { weight: 25, max: 25, label: "문제 심각성", korean: "타겟 정의" },
        moat: { weight: 20, max: 20, label: "차별성", korean: "차별화" },
        feasibility: { weight: 15, max: 15, label: "실현 가능성", korean: "기술 구체화" },
        business: { weight: 10, max: 10, label: "수익 모델", korean: "수익 모델" }
      }.freeze

      # 약점 영역 표준화 (ExpertScorePredictor와 매칭을 위해)
      # 5차원과 연동되도록 매핑
      STANDARD_WEAK_AREAS = [
        "시장 분석",     # market
        "기술 구체화",   # feasibility
        "타겟 정의",     # problem
        "차별화",        # moat
        "수익 모델",     # business
        "MVP 정의"       # feasibility (secondary)
      ].freeze

      # Grade 기준
      GRADE_THRESHOLDS = {
        "S" => 90,
        "A" => 80,
        "B" => 70,
        "C" => 60,
        "D" => 0
      }.freeze

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
          dimension_scores: default_dimension_scores,
          total_score: 50,
          grade: "C",
          radar_chart_data: [ 5, 5, 5, 5, 5 ],
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

      def default_dimension_scores
        {
          market: {
            score: 15,
            breakdown: { tam: 5, competition: 5, trend: 5 },
            market_size: {
              tam: { revenue: "분석 필요", users: "분석 필요" },
              sam: { revenue: "분석 필요", users: "분석 필요" },
              som: { revenue: "분석 필요", users: "분석 필요" }
            },
            feedback: "분석 필요"
          },
          problem: { score: 12, breakdown: { pain: 7, frequency: 5 }, feedback: "분석 필요" },
          moat: {
            score: 10,
            breakdown: { advantage: 5, improvement: 5 },
            competitors: { direct: [], indirect: [] },
            feedback: "분석 필요"
          },
          feasibility: { score: 8, breakdown: { mvp: 8 }, feedback: "분석 필요" },
          business: {
            score: 5,
            breakdown: { willingness: 5 },
            business_type: "미정",
            revenue_model: "분석 필요",
            feedback: "분석 필요"
          }
        }
      end

      def build_messages
        format_messages_for_gemini(
          [ { role: "user", content: user_prompt } ],
          system_prompt: system_prompt
        )
      end

      def system_prompt
        <<~PROMPT
          당신은 실리콘밸리의 냉철한 벤처 투자자(VC)입니다.
          사용자의 아이디어를 다음 5가지 기준(Pentagonal Analysis)에 따라 엄격하게 평가합니다.

          ## 평가 방식 (Chain of Thought)
          각 차원을 순서대로 분석하고, 세부 지표별 점수와 근거를 제시하세요.

          ## 평가 기준표 (Rubric)

          ### A. Market (시장성) - 30점 만점
          1. TAM (시장 규모) - 10점
             - 10점: 조 단위 글로벌 시장 또는 폭발적 성장 시장 (AI, 노령화 등)
             - 5점: 안정적이지만 성장이 더딘 시장
             - 1점: 너무 좁은 니치 마켓 또는 사양 산업

          2. Competition (경쟁 강도) - 10점
             - 10점: 뚜렷한 지배자가 없는 블루오션
             - 5점: 경쟁자가 있지만 틈새 공략 가능
             - 1점: 네이버/카카오/구글이 장악한 레드오션

          3. Trend (트렌드 부합성) - 10점
             - 10점: 현재 메가 트렌드와 일치 (Up-trend)
             - 1점: 트렌드에 역행하거나 유행이 지남

          **추가 분석 (market_size 필드에 포함):**
          - TAM/SAM/SOM을 매출 규모와 사용자 수로 표현
            - TAM (Total Addressable Market): 전체 시장 규모 (예: "10조원", "5000만명")
            - SAM (Serviceable Available Market): 서비스 가능 시장 (예: "1조원", "500만명")
            - SOM (Serviceable Obtainable Market): 초기 획득 가능 시장 (예: "100억원", "50만명")

          ### B. Problem (문제 심각성) - 25점 만점
          1. Pain (고통의 강도) - 15점
             - 15점: "Hair on fire" - 해결 안 하면 손해/고통이 막심함 (진통제)
             - 7점: 있으면 좋지만 없어도 사는데 지장 없음 (비타민)
             - 0점: 사용자가 문제라고 인식조차 못 함

          2. Frequency (발생 빈도) - 10점
             - 10점: 매일/매주 겪는 문제 (습관 형성 가능)
             - 1점: 1년에 한 번 겪을까 말까 (결혼, 이사 등)

          ### C. Moat (차별성 & 경쟁우위) - 20점 만점
          1. Unfair Advantage - 10점
             - 10점: 독점 데이터, 특허, 네트워크 효과 등 남들이 따라 할 수 없는 무기
             - 1점: 아이디어만 있고 기술 장벽 없음 (누구나 내일 당장 개발 가능)

          2. Improvement (기존 대비 개선도) - 10점
             - 10점: 기존 방식보다 10배 더 싸거나 빠름
             - 1점: 기존 방식과 비슷하거나 약간 더 예쁨

          **추가 분석 (competitors 필드에 포함):**
          - 직접 경쟁사 (direct): 같은 문제를 같은 방식으로 해결하는 기업 (최대 3개)
          - 간접 경쟁사 (indirect): 같은 문제를 다른 방식으로 해결하거나 대체재 (최대 3개)

          ### D. Feasibility (실현 가능성) - 15점 만점
          1. MVP 난이도 - 15점
             - 15점: 1인 개발/노코드로 1달 내 출시 가능 (Lean Start)
             - 7점: 3~6개월 정도 개발 필요
             - 1점: 고도의 R&D나 법적 규제 해소가 선행되어야 함 (Hard Tech)

          ### E. Business (수익 모델) - 10점 만점
          1. Willingness to Pay (지불 의사) - 10점
             - 10점: 고객이 돈을 낼 명분이 확실함 (비용 절감, 매출 증대)
             - 1점: "무료면 쓰겠지만 돈 내긴 싫다" (광고 모델 의존)

          **추가 분석:**
          - business_type: B2C, B2B, B2B2C, C2C, B2G 중 선택
          - revenue_model: 구독, 거래 수수료, 광고, SaaS, 라이선스, 중개 수수료 등

          ## 출력 형식 (JSON)
          반드시 다음 JSON 형식으로만 응답하세요:
          ```json
          {
            "dimension_scores": {
              "market": {
                "score": 24,
                "breakdown": { "tam": 8, "competition": 7, "trend": 9 },
                "market_size": {
                  "tam": { "revenue": "10조원", "users": "5000만명" },
                  "sam": { "revenue": "1조원", "users": "500만명" },
                  "som": { "revenue": "100억원", "users": "50만명" }
                },
                "feedback": "시장 규모와 트렌드는 좋으나 경쟁이 치열합니다"
              },
              "problem": {
                "score": 20,
                "breakdown": { "pain": 12, "frequency": 8 },
                "feedback": "심각한 고통을 해결하지만 발생 빈도가 낮습니다"
              },
              "moat": {
                "score": 14,
                "breakdown": { "advantage": 6, "improvement": 8 },
                "competitors": {
                  "direct": ["경쟁사A", "경쟁사B"],
                  "indirect": ["대체재A", "대체재B"]
                },
                "feedback": "기술 장벽이 낮아 모방 위험이 있습니다"
              },
              "feasibility": {
                "score": 12,
                "breakdown": { "mvp": 12 },
                "feedback": "3개월 내 MVP 출시 가능합니다"
              },
              "business": {
                "score": 8,
                "breakdown": { "willingness": 8 },
                "business_type": "B2B",
                "revenue_model": "SaaS 구독",
                "feedback": "B2B SaaS 모델로 지불 의사가 명확합니다"
              }
            },
            "total_score": 78,
            "grade": "A",
            "radar_chart_data": [8, 8, 7, 8, 8],
            "score": {
              "overall": 78,
              "weak_areas": ["차별화", "기술 구체화"],
              "strong_areas": ["시장 분석", "타겟 정의", "수익 모델"],
              "improvement_tips": [
                "경쟁사 대비 10배 개선점을 명확히 정의하세요",
                "특허나 독점 데이터 확보 방안을 고려하세요",
                "MVP 범위를 최소화하여 빠르게 검증하세요"
              ]
            },
            "required_expertise": {
              "roles": ["Developer", "Marketer"],
              "skills": ["React", "Growth Hacking", "B2B Sales", "데이터 분석", "UX"],
              "description": "기술 개발과 초기 고객 확보를 위한 팀 구성 필요"
            },
            "confidence_level": "High"
          }
          ```

          ## 규칙
          - total_score = 5개 차원 점수의 합계 (0-100)
          - grade: S(90+), A(80-89), B(70-79), C(60-69), D(60 미만)
          - radar_chart_data: 각 차원을 10점 만점으로 환산 [market, problem, moat, feasibility, business]
          - weak_areas: 점수가 낮은 차원 2-3개 (시장 분석, 기술 구체화, 타겟 정의, 차별화, 수익 모델, MVP 정의 중 선택)
          - strong_areas: 점수가 높은 차원 2-3개
          - improvement_tips: 실행 가능한 구체적인 조언 3개
          - roles: Developer, Designer, Marketer, PM 등
          - skills: 구체적인 기술/역량 5개 이내
          - confidence_level: 분석 데이터 충분도에 따라 High/Medium/Low
          - JSON 외의 다른 텍스트는 출력하지 않음
          - 점수는 객관적으로 평가하되, 극단적인 점수도 가능 (매우 훌륭하면 90+, 문제가 많으면 30-40점대도 가능)
          - market_size, competitors, business_type, revenue_model은 반드시 포함
        PROMPT
      end

      def user_prompt
        prompt = build_base_context
        prompt += build_previous_results_context
        prompt += "\n\n위 정보를 바탕으로 Pentagonal Analysis(5차원 평가)를 수행해주세요."
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

        dimension_scores = validate_dimension_scores(result[:dimension_scores])
        total_score = calculate_total_score(dimension_scores)
        grade = calculate_grade(total_score)
        radar_data = calculate_radar_data(dimension_scores)
        weak_areas = infer_weak_areas(dimension_scores)

        {
          dimension_scores: dimension_scores,
          total_score: total_score,
          grade: grade,
          radar_chart_data: radar_data,
          score: validate_score(result[:score], total_score, weak_areas),
          required_expertise: validate_required_expertise(result[:required_expertise]),
          confidence_level: result[:confidence_level] || "Medium"
        }
      end

      def validate_dimension_scores(scores)
        return default_dimension_scores unless scores.is_a?(Hash)

        validated = {}

        DIMENSIONS.each do |key, config|
          dim_score = scores[key] || scores[key.to_s]
          if dim_score.is_a?(Hash)
            score = [ [ dim_score[:score].to_i, 0 ].max, config[:max] ].min
            base_result = {
              score: score,
              breakdown: dim_score[:breakdown] || {},
              feedback: dim_score[:feedback] || "분석 완료"
            }

            # 차원별 추가 필드 처리
            case key
            when :market
              base_result[:market_size] = dim_score[:market_size] || default_dimension_scores[:market][:market_size]
            when :moat
              base_result[:competitors] = dim_score[:competitors] || default_dimension_scores[:moat][:competitors]
            when :business
              base_result[:business_type] = dim_score[:business_type] || default_dimension_scores[:business][:business_type]
              base_result[:revenue_model] = dim_score[:revenue_model] || default_dimension_scores[:business][:revenue_model]
            end

            validated[key] = base_result
          else
            validated[key] = default_dimension_scores[key]
          end
        end

        validated
      end

      def calculate_total_score(dimension_scores)
        total = dimension_scores.values.sum { |d| d[:score].to_i }
        [ [ total, 0 ].max, 100 ].min
      end

      def calculate_grade(total_score)
        GRADE_THRESHOLDS.find { |_grade, threshold| total_score >= threshold }&.first || "D"
      end

      def calculate_radar_data(dimension_scores)
        # 각 차원을 10점 만점으로 환산
        DIMENSIONS.keys.map do |key|
          score = dimension_scores[key][:score].to_f
          max = DIMENSIONS[key][:max].to_f
          ((score / max) * 10).round
        end
      end

      def infer_weak_areas(dimension_scores)
        # 점수가 낮은 순으로 정렬하여 약점 영역 추출
        sorted = dimension_scores.sort_by { |_key, data| data[:score].to_f / DIMENSIONS[_key][:max] }
        sorted.first(2).map { |key, _data| DIMENSIONS[key][:korean] }
      end

      def validate_score(score, total_score, inferred_weak_areas)
        score ||= {}

        weak_areas = if score[:weak_areas].is_a?(Array) && score[:weak_areas].any?
          standardize_weak_areas(score[:weak_areas])
        else
          inferred_weak_areas
        end

        {
          overall: total_score,
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
