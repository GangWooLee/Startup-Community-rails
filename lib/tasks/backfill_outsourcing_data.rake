# frozen_string_literal: true

namespace :data do
  desc "기존 외주 글(구인/구직)에 새 필드 데이터 채우기"
  task backfill_outsourcing: :environment do
    puts "=== 외주 글 데이터 보완 시작 ==="

    # 서비스 타입별 기본 스킬
    SKILLS_BY_SERVICE_TYPE = {
      "planning" => "기획, 문서작성, PM, 커뮤니케이션",
      "design" => "Figma, Adobe XD, Photoshop, Illustrator",
      "development" => "React, Rails, Node.js, Python",
      "marketing" => "SNS 마케팅, 콘텐츠 제작, 데이터 분석, SEO",
      "video" => "Premiere Pro, After Effects, 영상 촬영",
      "other" => "기타"
    }.freeze

    # 진행 방식 옵션
    WORK_TYPES = %w[remote onsite hybrid].freeze

    # 가격 범위 (만원 단위)
    PRICE_RANGES = {
      "planning" => (100..500),
      "design" => (50..300),
      "development" => (200..800),
      "marketing" => (100..400),
      "video" => (100..500),
      "other" => (50..200)
    }.freeze

    # 구인 글 업데이트
    puts "\n[구인 글 업데이트]"
    Post.where(category: :hiring).find_each do |post|
      updates = {}

      # skills가 없으면 service_type에 맞는 기본값 설정
      if post.skills.blank? && post.service_type.present?
        updates[:skills] = SKILLS_BY_SERVICE_TYPE[post.service_type] || "기타"
      end

      # work_type이 없으면 랜덤 설정
      if post.work_type.blank?
        updates[:work_type] = WORK_TYPES.sample
      end

      # price가 없으면 service_type에 맞는 범위에서 랜덤 설정
      if post.price.nil? && post.service_type.present?
        range = PRICE_RANGES[post.service_type] || (50..200)
        updates[:price] = rand(range) * 10000 # 만원 단위
      end

      # work_period가 없으면 기본값 설정
      if post.work_period.blank?
        periods = [ "1주일", "2주", "1개월", "2개월", "3개월", "협의" ]
        updates[:work_period] = periods.sample
      end

      if updates.any?
        post.update_columns(updates)
        puts "  ID #{post.id}: #{updates.keys.join(', ')} 업데이트됨"
      else
        puts "  ID #{post.id}: 이미 완료됨"
      end
    end

    # 구직 글 업데이트
    puts "\n[구직 글 업데이트]"
    Post.where(category: :seeking).find_each do |post|
      updates = {}

      # skills가 없으면 service_type에 맞는 기본값 설정
      if post.skills.blank? && post.service_type.present?
        updates[:skills] = SKILLS_BY_SERVICE_TYPE[post.service_type] || "기타"
      end

      # work_type이 없으면 랜덤 설정
      if post.work_type.blank?
        updates[:work_type] = WORK_TYPES.sample
      end

      # price가 없으면 시급/일당 기준으로 설정
      if post.price.nil?
        updates[:price] = rand(30..80) * 10000 # 시급 3~8만원
      end

      # portfolio_url이 없으면 예시 URL 또는 빈 값 유지
      # (실제 데이터가 아니므로 빈 값으로 유지)

      # experience가 없으면 기본 텍스트 설정
      if post.experience.blank?
        experiences = [
          "관련 분야 3년 경력 보유",
          "스타트업에서 다양한 프로젝트 경험",
          "프리랜서로 2년간 활동",
          "대기업 및 중소기업 프로젝트 다수 수행",
          "개인 프로젝트 및 사이드 프로젝트 경험 다수"
        ]
        updates[:experience] = experiences.sample
      end

      if updates.any?
        post.update_columns(updates)
        puts "  ID #{post.id}: #{updates.keys.join(', ')} 업데이트됨"
      else
        puts "  ID #{post.id}: 이미 완료됨"
      end
    end

    puts "\n=== 데이터 보완 완료 ==="
    puts "구인 글: #{Post.where(category: :hiring).count}개"
    puts "구직 글: #{Post.where(category: :seeking).count}개"
  end
end
