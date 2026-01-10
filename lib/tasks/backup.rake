# frozen_string_literal: true

namespace :backup do
  desc "Backup SQLite databases to S3 or local storage"
  task database: :environment do
    require "fileutils"

    timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
    backup_dir = Rails.root.join("tmp", "backups", timestamp)
    FileUtils.mkdir_p(backup_dir)

    # SQLite database files to backup
    databases = {
      "production" => Rails.root.join("storage", "production.sqlite3"),
      "production_cache" => Rails.root.join("storage", "production_cache.sqlite3"),
      "production_queue" => Rails.root.join("storage", "production_queue.sqlite3"),
      "production_cable" => Rails.root.join("storage", "production_cable.sqlite3")
    }

    backed_up_files = []

    databases.each do |name, path|
      next unless File.exist?(path)

      backup_file = backup_dir.join("#{name}_#{timestamp}.sqlite3")

      # Use SQLite backup command for safe copy during writes
      # This ensures data integrity even if writes are happening
      begin
        system("sqlite3 #{path} \".backup '#{backup_file}'\"")
        if File.exist?(backup_file)
          backed_up_files << backup_file
          puts "[Backup] Created: #{backup_file}"
        else
          # Fallback to file copy if sqlite3 command fails
          FileUtils.cp(path, backup_file)
          backed_up_files << backup_file
          puts "[Backup] Created (copy): #{backup_file}"
        end
      rescue StandardError => e
        puts "[Backup] ERROR backing up #{name}: #{e.message}"
      end
    end

    if backed_up_files.empty?
      puts "[Backup] No databases to backup (SQLite files not found)"
      next
    end

    # Upload to S3 if configured
    if upload_to_s3?(backed_up_files, timestamp)
      puts "[Backup] S3 upload completed"
      # Clean up local backup after S3 upload
      FileUtils.rm_rf(backup_dir)
      puts "[Backup] Local backup cleaned up"
    else
      puts "[Backup] Keeping local backup at: #{backup_dir}"
      # Keep only last 7 days of local backups
      cleanup_old_backups
    end

    puts "[Backup] Completed at #{timestamp}"
  end

  desc "List available backups"
  task list: :environment do
    backup_base = Rails.root.join("tmp", "backups")
    unless Dir.exist?(backup_base)
      puts "No local backups found"
      return
    end

    puts "Local backups:"
    Dir.glob(backup_base.join("*")).sort.reverse.each do |dir|
      next unless File.directory?(dir)
      files = Dir.glob(File.join(dir, "*.sqlite3"))
      total_size = files.sum { |f| File.size(f) }
      puts "  #{File.basename(dir)} (#{files.size} files, #{(total_size / 1024.0 / 1024.0).round(2)} MB)"
    end
  end

  desc "Restore database from backup"
  task :restore, [ :timestamp ] => :environment do |_t, args|
    unless args[:timestamp]
      puts "Usage: rails backup:restore[TIMESTAMP]"
      puts "Example: rails backup:restore[20260105_040000]"
      exit 1
    end

    backup_dir = Rails.root.join("tmp", "backups", args[:timestamp])
    unless Dir.exist?(backup_dir)
      puts "Backup not found: #{backup_dir}"
      exit 1
    end

    puts "WARNING: This will overwrite current databases!"
    puts "Press Ctrl+C to cancel, or Enter to continue..."
    $stdin.gets

    Dir.glob(backup_dir.join("*.sqlite3")).each do |backup_file|
      # Extract original database name
      basename = File.basename(backup_file)
      db_name = basename.sub(/_\d{8}_\d{6}\.sqlite3$/, "")
      target = Rails.root.join("storage", "#{db_name}.sqlite3")

      puts "[Restore] #{basename} -> #{target}"
      FileUtils.cp(backup_file, target)
    end

    puts "[Restore] Completed"
  end

  private

  def upload_to_s3?(files, timestamp)
    bucket_name = Rails.application.credentials.dig(:production, :aws, :backup_bucket)
    return false unless bucket_name

    begin
      require "aws-sdk-s3"

      s3 = Aws::S3::Resource.new(
        access_key_id: Rails.application.credentials.dig(:production, :aws, :access_key_id),
        secret_access_key: Rails.application.credentials.dig(:production, :aws, :secret_access_key),
        region: Rails.application.credentials.dig(:production, :aws, :region) || "ap-northeast-2"
      )

      bucket = s3.bucket(bucket_name)

      files.each do |file|
        object_key = "backups/#{timestamp}/#{File.basename(file)}"
        bucket.object(object_key).upload_file(file)
        puts "[S3] Uploaded: #{object_key}"
      end

      # Also keep a 'latest' reference
      files.each do |file|
        db_name = File.basename(file).sub(/_\d{8}_\d{6}\.sqlite3$/, "")
        latest_key = "backups/latest/#{db_name}.sqlite3"
        bucket.object(latest_key).upload_file(file)
      end

      true
    rescue LoadError
      puts "[S3] aws-sdk-s3 not available"
      false
    rescue StandardError => e
      puts "[S3] Upload failed: #{e.message}"
      false
    end
  end

  def cleanup_old_backups
    backup_base = Rails.root.join("tmp", "backups")
    return unless Dir.exist?(backup_base)

    # Keep only last 7 days
    cutoff = 7.days.ago
    Dir.glob(backup_base.join("*")).each do |dir|
      next unless File.directory?(dir)
      timestamp_str = File.basename(dir)
      begin
        backup_time = Time.strptime(timestamp_str, "%Y%m%d_%H%M%S")
        if backup_time < cutoff
          FileUtils.rm_rf(dir)
          puts "[Cleanup] Removed old backup: #{timestamp_str}"
        end
      rescue ArgumentError
        # Skip directories that don't match timestamp format
      end
    end
  end
end
