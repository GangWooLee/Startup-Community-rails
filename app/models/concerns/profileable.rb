# frozen_string_literal: true

# 프로필 관련 기능 (익명 프로필, 아바타, 스킬 등)
# 사용: include Profileable
#
# 제공 메서드:
# - display_name: 커뮤니티에서 표시될 이름
# - display_avatar_path: 커뮤니티에서 표시될 아바타 경로
# - using_anonymous_avatar?: 익명 아바타 사용 중인지 확인
# - has_profile_image?: 프로필 이미지가 있는지 확인
# - profile_image_url: 프로필 이미지 URL
# - skills_array: 스킬 배열
# - achievements_array: 성과 배열
# - toolbox_array: 도구 배열
# - work_style_items: 작업 스타일 Q&A
# - cover_gradient: 커버 이미지 기본 그라디언트
# - cover_image_url: 커버 이미지 URL
# - has_cover_image?: 커버 이미지 여부
module Profileable
  extend ActiveSupport::Concern

  included do
    # 커버 이미지 기본 그라디언트 (업로드 없을 때 사용)
    COVER_GRADIENTS = [
      "from-amber-100 via-orange-50 to-rose-50",
      "from-sky-100 via-blue-50 to-indigo-50",
      "from-emerald-100 via-teal-50 to-cyan-50",
      "from-violet-100 via-purple-50 to-fuchsia-50",
      "from-slate-100 via-gray-50 to-zinc-50",
      "from-lime-100 via-green-50 to-emerald-50"
    ].freeze
  end

  # ==========================================================================
  # 익명 프로필 시스템
  # ==========================================================================

  # 커뮤니티에서 표시될 이름
  # 익명 모드 ON: 닉네임 사용 (없으면 실명)
  # 익명 모드 OFF: 실명 사용
  def display_name
    return name unless profile_completed?
    is_anonymous? ? (nickname.presence || name) : name
  end

  # 커뮤니티에서 표시될 아바타 경로
  # 익명 모드: public 폴더의 익명 아바타 (avatar_type 0-3 → anonymous1-4)
  # 실명 모드: 업로드한 아바타 또는 OAuth 아바타
  def display_avatar_path
    if profile_completed? && is_anonymous?
      "/anonymous#{avatar_type + 1}-.png"
    elsif avatar.attached?
      Rails.application.routes.url_helpers.rails_blob_path(avatar, only_path: true)
    elsif avatar_url.present?
      avatar_url
    end
  end

  # 익명 아바타 사용 중인지 확인
  def using_anonymous_avatar?
    profile_completed? && is_anonymous?
  end

  # ==========================================================================
  # 프로필 섹션별 가시성 (익명 모드 시 세분화된 공개/비공개 설정)
  # ==========================================================================

  # 소개 탭 가시성 확인
  # @param viewer [User, nil] 조회하는 사용자 (nil이면 비로그인)
  # @return [Boolean] true면 공개, false면 블러 처리
  def about_visible_to?(viewer)
    return true unless is_anonymous?       # 익명 모드가 아니면 항상 공개
    return true if viewer == self          # 본인은 항상 볼 수 있음
    privacy_about                          # 설정값에 따라 공개 여부 결정
  end

  # 게시글 탭 가시성 확인
  def posts_visible_to?(viewer)
    return true unless is_anonymous?
    return true if viewer == self
    privacy_posts
  end

  # 활동 탭 가시성 확인
  def activity_visible_to?(viewer)
    return true unless is_anonymous?
    return true if viewer == self
    privacy_activity
  end

  # 경력/프로젝트 탭 가시성 확인
  def experience_visible_to?(viewer)
    return true unless is_anonymous?
    return true if viewer == self
    privacy_experience
  end

  # 프로필 이미지가 있는지 확인
  def has_profile_image?
    avatar.attached? || avatar_url.present?
  end

  # 프로필 이미지 URL 반환 (Active Storage 우선, 없으면 OAuth URL, 없으면 nil)
  def profile_image_url
    if avatar.attached?
      Rails.application.routes.url_helpers.rails_blob_path(avatar, only_path: true)
    elsif avatar_url.present?
      avatar_url
    end
  end

  # ==========================================================================
  # 스킬/성과/도구 배열 관리
  # ==========================================================================

  # 스킬을 배열로 반환
  def skills_array
    return [] if skills.blank?
    skills.split(",").map(&:strip).reject(&:blank?)
  end

  # 스킬 배열을 문자열로 저장
  def skills_array=(arr)
    self.skills = arr.is_a?(Array) ? arr.join(", ") : arr
  end

  # 주요 성과/포트폴리오를 배열로 반환 (줄바꿈으로 구분)
  def achievements_array
    return [] if achievements.blank?
    achievements.split("\n").map(&:strip).reject(&:blank?)
  end

  # 성과 배열을 문자열로 저장
  def achievements_array=(arr)
    self.achievements = arr.is_a?(Array) ? arr.join("\n") : arr
  end

  # 도구 & 장비를 배열로 반환 (쉼표 구분)
  def toolbox_array
    return [] if toolbox.blank?
    toolbox.split(",").map(&:strip).reject(&:blank?)
  end

  # 도구 배열을 문자열로 저장
  def toolbox_array=(arr)
    self.toolbox = arr.is_a?(Array) ? arr.join(", ") : arr
  end

  # ==========================================================================
  # 작업 스타일 Q&A
  # ==========================================================================

  # 작업 스타일 Q&A 파싱 (JSON 형식)
  # 예: [{"question": "선호 커뮤니케이션", "answer": "슬랙 DM"}]
  def work_style_items
    return [] if work_style.blank?
    items = JSON.parse(work_style, symbolize_names: true)
    items.is_a?(Array) ? items : []
  rescue JSON::ParserError
    []
  end

  # 작업 스타일 설정 (배열 또는 JSON 문자열)
  def work_style_items=(arr)
    self.work_style = arr.is_a?(Array) ? arr.to_json : arr
  end

  # ==========================================================================
  # 커버 이미지 관련 메서드
  # ==========================================================================

  # 커버 이미지 기본 그라디언트 반환 (사용자 ID 기반)
  def cover_gradient
    COVER_GRADIENTS[id % COVER_GRADIENTS.length]
  end

  # 커버 이미지 URL 반환 (업로드 이미지 우선)
  def cover_image_url
    if cover_image.attached?
      Rails.application.routes.url_helpers.rails_blob_path(cover_image, only_path: true)
    end
  end

  # 커버 이미지가 있는지 확인
  def has_cover_image?
    cover_image.attached?
  end
end
