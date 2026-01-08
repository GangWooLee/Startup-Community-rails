# frozen_string_literal: true

module Ai
  # 전문가가 아이디어 점수를 얼마나 향상시킬 수 있는지 예측
  # 분석 결과의 weak_areas와 전문가의 스킬/역할을 매칭하여 점수 향상분 계산
  #
  # 사용법:
  #   predictor = Ai::ExpertScorePredictor.new(analysis_result)
  #   predictions = predictor.predict_all(experts)
  #   # => [{ user: expert1, score_boost: 25, boost_area: "시장 분석", why: "..." }, ...]
  #
  class ExpertScorePredictor
    # 약점 영역 → 관련 스킬/역할 매핑
    WEAK_AREA_MAPPINGS = {
      "시장 분석" => {
        roles: %w[marketer pm 마케터 기획자 사업개발 bd],
        skills: %w[마케팅 시장조사 리서치 분석 데이터분석 ga 그로스]
      },
      "기술 구체화" => {
        roles: %w[developer engineer 개발자 엔지니어 테크리드],
        skills: %w[개발 코딩 풀스택 백엔드 프론트엔드 react node python java]
      },
      "타겟 정의" => {
        roles: %w[pm uxr 기획자 리서처 사업개발],
        skills: %w[ux사용자리서치 고객분석 페르소나 인터뷰 서비스기획]
      },
      "차별화" => {
        roles: %w[designer pm 디자이너 기획자 브랜드매니저],
        skills: %w[ux ui 디자인 브랜딩 제품기획 서비스디자인]
      },
      "수익 모델" => {
        roles: %w[pm coo cfo 기획자 사업개발 bd],
        skills: %w[비즈니스 수익화 bm 사업모델 재무 스타트업]
      },
      "MVP 정의" => {
        roles: %w[pm developer 기획자 개발자 cto],
        skills: %w[mvp 린스타트업 애자일 프로덕트 제품기획]
      }
    }.freeze

    # 점수 계산 상수
    MAX_SCORE_BOOST = 30       # 최대 점수 향상
    MIN_SCORE_BOOST = 5        # 최소 점수 향상
    ROLE_MATCH_WEIGHT = 10     # 역할 매칭 시 기본 점수
    SKILL_MATCH_WEIGHT = 5     # 스킬 매칭 시 점수 (개당)
    MAX_SKILL_MATCHES = 3      # 스킬 매칭 최대 횟수

    def initialize(analysis_result)
      @analysis = analysis_result || {}
      @weak_areas = extract_weak_areas
      @current_score = @analysis.dig(:score, :overall) || 50
    end

    # 모든 전문가에 대한 점수 예측
    def predict_all(experts)
      experts.map.with_index do |expert, index|
        predict(expert, index)
      end
    end

    # 단일 전문가에 대한 점수 예측
    def predict(expert, index = 0)
      best_match = find_best_match(expert)

      {
        user: expert,
        score_boost: best_match[:score_boost],
        boost_area: best_match[:area],
        why: generate_why_text(expert, best_match)
      }
    end

    private

    # 분석 결과에서 약점 영역 추출
    def extract_weak_areas
      weak_areas = @analysis.dig(:score, :weak_areas) || []
      return [ "기술 구체화", "시장 분석" ] if weak_areas.empty? # 기본값

      weak_areas
    end

    # 전문가의 스킬/역할과 약점 영역 매칭 분석
    def find_best_match(expert)
      user_skills = normalize_skills(expert.skills_array)
      user_role = normalize_role(expert.role_title)

      best_match = {
        area: @weak_areas.first || "전문성",
        score_boost: MIN_SCORE_BOOST,
        matched_skills: [],
        role_matched: false
      }

      @weak_areas.each do |weak_area|
        mapping = WEAK_AREA_MAPPINGS[weak_area]
        next unless mapping

        match_result = calculate_area_match(expert, mapping, user_skills, user_role)

        if match_result[:score] > best_match[:score_boost]
          best_match = {
            area: weak_area,
            score_boost: [ [ match_result[:score], MAX_SCORE_BOOST ].min, MIN_SCORE_BOOST ].max,
            matched_skills: match_result[:matched_skills],
            role_matched: match_result[:role_matched]
          }
        end
      end

      best_match
    end

    # 특정 약점 영역에 대한 전문가 매칭 점수 계산
    def calculate_area_match(expert, mapping, user_skills, user_role)
      score = 0
      matched_skills = []
      role_matched = false

      # 역할 매칭 체크
      mapping[:roles].each do |target_role|
        if user_role.include?(target_role.downcase)
          score += ROLE_MATCH_WEIGHT
          role_matched = true
          break
        end
      end

      # 스킬 매칭 체크
      skill_matches = 0
      mapping[:skills].each do |target_skill|
        user_skills.each do |user_skill|
          if user_skill.include?(target_skill.downcase) || target_skill.downcase.include?(user_skill)
            matched_skills << user_skill unless matched_skills.include?(user_skill)
            skill_matches += 1
            break
          end
        end
        break if skill_matches >= MAX_SKILL_MATCHES
      end
      score += skill_matches * SKILL_MATCH_WEIGHT

      # 활동 상태 보너스
      score += 3 if expert.has_availability_status?

      # 경험 기반 보너스 (bio가 있는 경우)
      score += 2 if expert.bio.present? && expert.bio.length > 20

      {
        score: score,
        matched_skills: matched_skills,
        role_matched: role_matched
      }
    end

    # "왜 이 전문가인가" 설명 생성 (간단 버전 - 카드용)
    def generate_why_text(expert, match_result)
      parts = []

      # 역할 기반 설명
      if match_result[:role_matched] && expert.role_title.present?
        parts << "#{expert.role_title} 경험"
      end

      # 스킬 기반 설명
      if match_result[:matched_skills].any?
        skill_text = match_result[:matched_skills].first(2).join(", ")
        parts << "#{skill_text} 보유"
      end

      # 활동 상태 기반 설명
      if expert.has_availability_status?
        badge = expert.availability_badges.first
        parts << badge[:label] if badge
      end

      # 조합하여 설명 생성
      if parts.any?
        "#{match_result[:area]} 보완에 적합 - #{parts.join(', ')}"
      else
        "#{match_result[:area]} 영역 전문성 보유"
      end
    end

    # 상세 추천 이유 생성 (오버레이용)
    def generate_detailed_why_text(expert, match_result)
      area = match_result[:area]
      matched_skills = match_result[:matched_skills]
      role_matched = match_result[:role_matched]

      # 기본 문장 구성
      intro = "현재 아이디어의 약점인 '#{area}' 영역을 "

      # 역할 기반 설명
      if role_matched && expert.role_title.present?
        intro += "#{expert.role_title}로서의 전문 경험을 통해 보완할 수 있습니다. "
      else
        intro += "전문적인 역량으로 보완할 수 있습니다. "
      end

      # 스킬 기반 상세 설명
      if matched_skills.any?
        skills_text = matched_skills.join(", ")
        intro += "특히 #{skills_text} 역량이 #{area} 개선에 직접적인 도움이 됩니다."
      end

      # bio가 있으면 경험 요약 추가
      if expert.bio.present? && expert.bio.length > 30
        intro += " 실제 프로젝트 경험과 전문성을 바탕으로 실용적인 조언을 제공할 수 있습니다."
      end

      intro
    end

    # 스킬 배열 정규화
    def normalize_skills(skills)
      return [] unless skills.is_a?(Array)

      skills.map { |s| s.to_s.downcase.strip }.reject(&:blank?)
    end

    # 역할 정규화
    def normalize_role(role)
      role.to_s.downcase.strip
    end
  end
end
