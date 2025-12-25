# frozen_string_literal: true

# 아이디어에 필요한 전문성을 기반으로 사용자를 매칭하는 서비스
#
# 사용법:
#   required_expertise = { roles: ["Developer", "Designer"], skills: ["React", "Node.js"] }
#   experts = ExpertMatcher.new(required_expertise, exclude_user_id: current_user.id).find_matches
#
class ExpertMatcher
  MAX_EXPERTS = 5

  # 점수 가중치
  ROLE_MATCH_SCORE = 3      # 역할이 매칭될 때
  SKILL_MATCH_SCORE = 2     # 스킬이 매칭될 때
  AVAILABILITY_BONUS = 1    # 활동 상태가 있을 때

  def initialize(required_expertise, exclude_user_id: nil)
    @roles = normalize_array(required_expertise[:roles])
    @skills = normalize_array(required_expertise[:skills])
    @exclude_user_id = exclude_user_id
  end

  # 매칭되는 전문가 목록 반환 (최대 5명)
  def find_matches
    return [] if @roles.empty? && @skills.empty?

    users = base_query
    scored_users = calculate_scores(users)

    scored_users
      .sort_by { |entry| -entry[:score] }
      .first(MAX_EXPERTS)
      .map { |entry| entry[:user] }
  end

  private

  # 기본 사용자 쿼리 (본인 제외)
  def base_query
    query = User.all
    query = query.where.not(id: @exclude_user_id) if @exclude_user_id
    query
  end

  # 모든 사용자의 매칭 점수 계산
  def calculate_scores(users)
    users.map do |user|
      score = calculate_match_score(user)
      { user: user, score: score } if score > 0
    end.compact
  end

  # 개별 사용자의 매칭 점수 계산
  def calculate_match_score(user)
    score = 0
    user_skills = user.skills_array.map(&:downcase)
    user_role = user.role_title&.downcase || ""

    # 역할 매칭 (3점)
    @roles.each do |role|
      if role_matches?(user_role, role)
        score += ROLE_MATCH_SCORE
      end
    end

    # 스킬 매칭 (2점씩)
    @skills.each do |skill|
      if skill_matches?(user_skills, skill)
        score += SKILL_MATCH_SCORE
      end
    end

    # 활동상태 보너스 (1점)
    if user.has_availability_status?
      score += AVAILABILITY_BONUS
    end

    score
  end

  # 역할 매칭 로직 (부분 매칭 허용)
  def role_matches?(user_role, target_role)
    return false if user_role.blank?

    target = target_role.downcase

    # 정확한 매칭 또는 부분 포함
    user_role.include?(target) || target.include?(user_role)
  end

  # 스킬 매칭 로직 (부분 매칭 허용)
  def skill_matches?(user_skills, target_skill)
    return false if user_skills.empty?

    target = target_skill.downcase

    user_skills.any? do |user_skill|
      user_skill.include?(target) || target.include?(user_skill)
    end
  end

  # 배열 정규화 (nil, 빈 값 처리)
  def normalize_array(arr)
    return [] unless arr.is_a?(Array)

    arr.compact.map(&:to_s).reject(&:blank?)
  end
end
