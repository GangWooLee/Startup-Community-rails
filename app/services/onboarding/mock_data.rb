# frozen_string_literal: true

module Onboarding
  # AI 분석 Mock 데이터 모듈
  #
  # LLM 미설정 시 사용할 기본 데이터 제공
  # - 추가 질문 (Follow-up Questions)
  # - 분석 결과 (Analysis Result)
  # - 필요 전문성 (Required Expertise)
  module MockData
    module_function

    # LLM 미설정 시 사용할 기본 추가 질문
    def default_follow_up_questions
      {
        questions: [
          {
            id: "target",
            question: "주요 타겟 사용자는 누구인가요?",
            placeholder: "타겟 사용자를 입력해주세요",
            examples: [ "20-30대 직장인", "대학생", "1인 가구" ],
            required: true
          },
          {
            id: "problem",
            question: "해결하려는 가장 큰 문제는 무엇인가요?",
            placeholder: "현재 겪고 있는 불편함을 입력해주세요",
            examples: [ "시간 부족", "비용 문제", "정보 접근성" ],
            required: true
          },
          {
            id: "differentiator",
            question: "기존 서비스와 다른 점은 무엇인가요? (선택)",
            placeholder: "차별화 포인트를 입력해주세요",
            examples: [ "AI 자동화", "커뮤니티 기반", "저렴한 가격" ],
            required: false
          }
        ]
      }
    end

    # Mock 필요 전문성 데이터
    def required_expertise
      {
        roles: [ "Developer", "Designer" ],
        skills: [ "React", "Node.js", "UI/UX", "스타트업", "MVP" ],
        description: "풀스택 개발자와 UI/UX 디자이너가 필요합니다"
      }
    end

    # LLM 미설정 시 사용할 Mock 분석 결과
    def analysis_result(idea:)
      {
        summary: "초기 창업자를 위한 커뮤니티 기반 네트워킹 플랫폼",
        target_users: target_users_data,
        market_analysis: market_analysis_data,
        recommendations: recommendations_data,
        score: score_data,
        actions: actions_data,
        required_expertise: required_expertise,
        analyzed_at: Time.current,
        idea: idea
      }
    end

    # 타겟 사용자 데이터
    def target_users_data
      {
        primary: "20-30대 초기 창업자 및 예비 창업자",
        characteristics: [
          "IT/스타트업에 관심 있는 대학생",
          "사이드프로젝트를 찾는 개발자/디자이너",
          "첫 창업을 준비하는 직장인"
        ],
        personas: [
          {
            name: "열정적 대학생 창업가",
            age_range: "20-25세",
            description: "IT 관련 학과를 전공하며 창업에 관심이 많고, 팀원을 구하고 싶어하는 대학생. 아이디어는 있지만 실행력이 부족한 경우가 많음."
          },
          {
            name: "전환을 꿈꾸는 직장인",
            age_range: "28-35세",
            description: "현 직장에서 3-5년 경력을 쌓았으며, 사이드 프로젝트로 창업을 준비 중인 직장인. 실행력은 있지만 시간이 부족함."
          }
        ]
      }
    end

    # 시장 분석 데이터
    def market_analysis_data
      {
        potential: "높음",
        market_size: "국내 스타트업 지원 플랫폼 시장 규모 약 3,000억원 (2024년 기준), 연평균 12% 성장 중",
        trends: "AI 기반 매칭 서비스와 커뮤니티 중심 네트워킹 플랫폼이 성장세. 특히 초기 창업자 대상 서비스가 급성장 중.",
        competitors: [ "블라인드", "리멤버", "로켓펀치", "원티드", "디스콰이어트" ],
        differentiation: "커뮤니티 활동과 외주 매칭을 통합한 신뢰 기반 플랫폼. 활동 기반 프로필로 신뢰도 검증 가능."
      }
    end

    # 추천 사항 데이터
    def recommendations_data
      {
        mvp_features: [
          "커뮤니티 게시판 (자유/질문/홍보 카테고리)",
          "프로필 기반 네트워킹 및 스킬 태그",
          "구인/구직 매칭 및 1:1 채팅"
        ],
        challenges: [
          "초기 사용자 확보가 어려울 수 있음 → 대학교/창업동아리 타겟 마케팅 권장",
          "콘텐츠 품질 유지가 관건 → 커뮤니티 가이드라인 및 모더레이션 필요",
          "경쟁사 대비 차별점 부각 필요 → 신뢰 기반 프로필 시스템 강조"
        ],
        next_steps: [
          "타겟 커뮤니티(대학교 창업동아리)에서 베타 테스트 진행",
          "핵심 사용자 그룹 100명 확보",
          "피드백 기반 기능 개선 및 반복",
          "외주 매칭 기능 추가 개발",
          "수익화 모델 검증 (프리미엄 구독, 매칭 수수료)"
        ]
      }
    end

    # 점수 데이터
    def score_data
      {
        overall: 72,
        weak_areas: [ "시장 분석", "수익 모델" ],
        strong_areas: [ "아이디어 독창성", "타겟 명확성" ],
        improvement_tips: [
          "타겟 시장의 규모를 구체화하세요",
          "수익화 모델을 명확히 정의하세요",
          "경쟁사 대비 차별점을 더 부각하세요"
        ]
      }
    end

    # 액션 아이템 데이터
    def actions_data
      [
        {
          title: "핵심 타깃 1줄 정의하기",
          description: "명확한 페르소나 설정으로 마케팅 전략의 기반을 만드세요. 예: '창업 1년 미만 IT 분야 초기 창업자'"
        },
        {
          title: "경쟁 서비스 분석",
          description: "유사 서비스 5개 이상 조사하고 각각의 강점/약점 분석. 나만의 차별점 3가지 도출"
        },
        {
          title: "MVP 기능 리스트",
          description: "반드시 필요한 핵심 기능 5개 이내로 정리. 우선순위를 정하고 1차 런칭 범위 확정"
        }
      ]
    end
  end
end
