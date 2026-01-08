# frozen_string_literal: true

# 익명 프로필용 닉네임 생성 서비스
# 두 가지 스타일 지원:
# 1. UD# 스타일: "UD#3845" (Undrew 브랜드)
# 2. 한국어 스타일: "열정적인 창업가" (형용사 + 명사)
class NicknameGenerator
  ADJECTIVES = %w[
    열정적인 차분한 힙한 성장하는 빠른 새벽의
    창의적인 꼼꼼한 대담한 유쾌한 진지한 도전하는
    호기심많은 끈기있는 유연한 똑똑한 용감한 따뜻한
    날카로운 감성적인 논리적인 섬세한 단단한 밝은
  ].freeze

  NOUNS = %w[
    창업가 메이커 기획자 개발자 디자이너
    투자자 마케터 전략가 혁신가 탐험가
    빌더 크리에이터 해커 몽상가 실행가
    아티스트 엔지니어 스토리텔러 분석가 리더
  ].freeze

  MAX_ATTEMPTS = 100

  class << self
    # 50% 확률로 UD# 형식, 50% 확률로 형용사+명사 형식
    def generate
      rand < 0.5 ? generate_ud_style : generate_korean_style
    end

    # UD# 스타일 닉네임 생성 (예: UD#3845)
    def generate_ud_style
      attempts = 0
      loop do
        nickname = "UD##{rand(1000..9999)}"
        return nickname unless User.exists?(nickname: nickname)

        attempts += 1
        return generate_korean_style if attempts >= MAX_ATTEMPTS
      end
    end

    # 한국어 스타일 닉네임 생성 (예: 열정적인 창업가)
    def generate_korean_style
      attempts = 0
      loop do
        nickname = "#{ADJECTIVES.sample} #{NOUNS.sample}"
        return nickname unless User.exists?(nickname: nickname)

        attempts += 1
        return fallback_nickname if attempts >= MAX_ATTEMPTS
      end
    end

    # 재생성 (현재 스타일 무관하게 새로 생성)
    def regenerate
      generate
    end

    private

    # 모든 조합이 소진됐을 경우 대비 (거의 발생하지 않음)
    def fallback_nickname
      "User#{SecureRandom.hex(4).upcase}"
    end
  end
end
