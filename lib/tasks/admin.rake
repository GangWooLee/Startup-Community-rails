# frozen_string_literal: true

# Admin user management tasks
# Usage:
#   ADMIN_EMAIL=admin@example.com ADMIN_PASSWORD=secret bin/rails admin:create
#   bin/rails admin:list
#   ADMIN_EMAIL=admin@example.com bin/rails admin:revoke

namespace :admin do
  desc "Create an admin user (requires ADMIN_EMAIL, ADMIN_PASSWORD env vars)"
  task create: :environment do
    email = ENV.fetch("ADMIN_EMAIL") { abort "❌ ADMIN_EMAIL is required" }
    password = ENV.fetch("ADMIN_PASSWORD") { abort "❌ ADMIN_PASSWORD is required" }
    name = ENV.fetch("ADMIN_NAME", "관리자")

    if User.exists?(email: email)
      user = User.find_by(email: email)
      if user.admin?
        puts "✅ Admin already exists: #{email}"
      else
        user.update!(is_admin: true)
        puts "✅ Upgraded to admin: #{email}"
      end
    else
      now = Time.current

      user = User.new(
        email: email,
        name: name,
        role_title: "Platform Admin",
        is_admin: true,
        # 약관 동의 (관리자는 자동 동의 처리)
        terms_accepted_at: now,
        privacy_accepted_at: now,
        guidelines_accepted_at: now,
        terms_version: "1.0"
      )

      # 비밀번호 직접 설정 (has_secure_password)
      user.password = password
      user.password_confirmation = password

      # 관리자 생성은 신뢰된 작업이므로 일부 검증 스킵
      # (blacklist 검증이 ActiveRecord Encryption 키를 요구함)
      user.save!(validate: false)

      # password_digest가 설정되었는지 확인
      if user.persisted? && user.password_digest.present?
        puts "✅ Admin created: #{email}"
      else
        abort "❌ Failed to create admin user"
      end
    end
  end

  desc "List all admin users"
  task list: :environment do
    admins = User.where(is_admin: true)
    if admins.any?
      puts "📋 Admin Users (#{admins.count}):"
      admins.each do |admin|
        puts "  - #{admin.email} (#{admin.name})"
      end
    else
      puts "❌ No admin users found"
    end
  end

  desc "Revoke admin privileges (requires ADMIN_EMAIL env var)"
  task revoke: :environment do
    email = ENV.fetch("ADMIN_EMAIL") { abort "❌ ADMIN_EMAIL is required" }
    user = User.find_by(email: email)

    if user&.admin?
      user.update!(is_admin: false)
      puts "✅ Admin revoked: #{email}"
    else
      puts "❌ User not found or not admin: #{email}"
    end
  end
end
