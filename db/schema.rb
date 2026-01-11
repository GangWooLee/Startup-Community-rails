# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_01_11_050426) do
  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admin_view_logs", force: :cascade do |t|
    t.string "action", null: false
    t.integer "admin_id", null: false
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.text "reason", null: false
    t.integer "target_id", null: false
    t.string "target_type", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.index ["admin_id"], name: "index_admin_view_logs_on_admin_id"
    t.index ["created_at"], name: "index_admin_view_logs_on_created_at"
    t.index ["target_type", "target_id"], name: "index_admin_view_logs_on_target"
    t.index ["target_type", "target_id"], name: "index_admin_view_logs_on_target_type_and_target_id"
  end

  create_table "bookmarks", force: :cascade do |t|
    t.integer "bookmarkable_id", null: false
    t.string "bookmarkable_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["bookmarkable_type", "bookmarkable_id"], name: "index_bookmarks_on_bookmarkable_type_and_bookmarkable_id"
    t.index ["user_id", "bookmarkable_type", "bookmarkable_id"], name: "index_bookmarks_on_user_and_bookmarkable", unique: true
    t.index ["user_id", "created_at"], name: "index_bookmarks_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_bookmarks_on_user_id"
  end

  create_table "chat_room_participants", force: :cascade do |t|
    t.integer "chat_room_id", null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.datetime "last_read_at"
    t.integer "unread_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["chat_room_id", "user_id"], name: "index_chat_room_participants_on_chat_room_id_and_user_id", unique: true
    t.index ["chat_room_id"], name: "index_chat_room_participants_on_chat_room_id"
    t.index ["deleted_at"], name: "index_chat_room_participants_on_deleted_at"
    t.index ["user_id", "chat_room_id"], name: "index_chat_room_participants_on_user_id_and_chat_room_id"
    t.index ["user_id", "deleted_at"], name: "index_participants_on_user_and_deleted"
    t.index ["user_id"], name: "index_chat_room_participants_on_user_id"
  end

  create_table "chat_rooms", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "deal_status", default: "pending"
    t.integer "initiator_id"
    t.datetime "last_message_at"
    t.integer "messages_count", default: 0, null: false
    t.integer "source_post_id"
    t.datetime "updated_at", null: false
    t.index ["initiator_id"], name: "index_chat_rooms_on_initiator_id"
    t.index ["last_message_at"], name: "index_chat_rooms_on_last_message_at"
    t.index ["source_post_id"], name: "index_chat_rooms_on_source_post_id"
  end

  create_table "comments", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.integer "depth", default: 0, null: false
    t.integer "likes_count", default: 0
    t.integer "parent_id"
    t.integer "post_id", null: false
    t.integer "replies_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["parent_id", "created_at"], name: "index_comments_on_parent_id_and_created_at"
    t.index ["parent_id"], name: "index_comments_on_parent_id"
    t.index ["post_id", "created_at"], name: "index_comments_on_post_id_and_created_at"
    t.index ["post_id"], name: "index_comments_on_post_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "email_verifications", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.datetime "expires_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "verified", default: false, null: false
    t.index ["email", "code"], name: "index_email_verifications_on_email_and_code"
    t.index ["email"], name: "index_email_verifications_on_email"
  end

  create_table "follows", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "followed_id", null: false
    t.integer "follower_id", null: false
    t.datetime "updated_at", null: false
    t.index ["followed_id", "created_at"], name: "index_follows_on_followed_id_and_created_at"
    t.index ["followed_id"], name: "index_follows_on_followed_id"
    t.index ["follower_id", "followed_id"], name: "index_follows_on_follower_id_and_followed_id", unique: true
    t.index ["follower_id"], name: "index_follows_on_follower_id"
  end

  create_table "idea_analyses", force: :cascade do |t|
    t.json "analysis_result", null: false
    t.datetime "created_at", null: false
    t.integer "current_stage", default: 0
    t.json "follow_up_answers"
    t.text "idea", null: false
    t.boolean "is_real_analysis", default: true
    t.boolean "partial_success", default: false
    t.integer "score"
    t.string "status", default: "completed", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["status"], name: "index_idea_analyses_on_status"
    t.index ["user_id", "created_at"], name: "index_idea_analyses_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_idea_analyses_on_user_id"
  end

  create_table "inquiries", force: :cascade do |t|
    t.text "admin_response"
    t.string "category", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.boolean "is_private", default: false, null: false
    t.datetime "responded_at"
    t.integer "responded_by_id"
    t.string "status", default: "pending", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["category"], name: "index_inquiries_on_category"
    t.index ["responded_by_id"], name: "index_inquiries_on_responded_by_id"
    t.index ["status"], name: "index_inquiries_on_status"
    t.index ["user_id"], name: "index_inquiries_on_user_id"
  end

  create_table "job_posts", force: :cascade do |t|
    t.string "budget"
    t.integer "category", default: 0, null: false
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.integer "project_type", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.integer "views_count", default: 0
    t.index ["category"], name: "index_job_posts_on_category"
    t.index ["created_at"], name: "index_job_posts_on_created_at"
    t.index ["status"], name: "index_job_posts_on_status"
    t.index ["user_id", "created_at"], name: "index_job_posts_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_job_posts_on_user_id"
  end

  create_table "likes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "likeable_id", null: false
    t.string "likeable_type", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["likeable_type", "likeable_id"], name: "index_likes_on_likeable_type_and_likeable_id"
    t.index ["user_id", "likeable_type", "likeable_id"], name: "index_likes_on_user_and_likeable", unique: true
    t.index ["user_id"], name: "index_likes_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.integer "chat_room_id", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.string "message_type", default: "text"
    t.json "metadata"
    t.integer "sender_id", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_room_id", "created_at"], name: "index_messages_on_chat_room_id_and_created_at"
    t.index ["chat_room_id"], name: "index_messages_on_chat_room_id"
    t.index ["created_at"], name: "index_messages_on_created_at_desc", order: :desc
    t.index ["sender_id"], name: "index_messages_on_sender_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.string "action", null: false
    t.integer "actor_id", null: false
    t.datetime "created_at", null: false
    t.integer "notifiable_id", null: false
    t.string "notifiable_type", null: false
    t.datetime "read_at"
    t.integer "recipient_id", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id", "created_at"], name: "index_notifications_on_actor_and_created"
    t.index ["actor_id"], name: "index_notifications_on_actor_id"
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable"
    t.index ["recipient_id", "read_at", "created_at"], name: "index_notifications_on_recipient_and_status"
    t.index ["recipient_id"], name: "index_notifications_on_recipient_id"
  end

  create_table "oauth_identities", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "provider", null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["provider", "uid"], name: "index_oauth_identities_on_provider_and_uid", unique: true
    t.index ["user_id", "provider"], name: "index_oauth_identities_on_user_id_and_provider", unique: true
    t.index ["user_id"], name: "index_oauth_identities_on_user_id"
  end

  create_table "orders", force: :cascade do |t|
    t.integer "amount", null: false
    t.datetime "cancelled_at"
    t.integer "chat_room_id"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "offer_message_id"
    t.string "order_number", null: false
    t.integer "order_type", default: 0, null: false
    t.datetime "paid_at"
    t.integer "post_id"
    t.datetime "refunded_at"
    t.integer "seller_id", null: false
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["chat_room_id"], name: "index_orders_on_chat_room_id"
    t.index ["offer_message_id"], name: "index_orders_on_offer_message_id"
    t.index ["order_number"], name: "index_orders_on_order_number", unique: true
    t.index ["order_type"], name: "index_orders_on_order_type"
    t.index ["post_id", "status"], name: "index_orders_on_post_id_and_status"
    t.index ["post_id"], name: "index_orders_on_post_id"
    t.index ["seller_id", "created_at"], name: "index_orders_on_seller_id_and_created_at"
    t.index ["seller_id"], name: "index_orders_on_seller_id"
    t.index ["status"], name: "index_orders_on_status"
    t.index ["user_id", "created_at"], name: "index_orders_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "payments", force: :cascade do |t|
    t.string "account_holder"
    t.string "account_number"
    t.integer "amount", null: false
    t.datetime "approved_at"
    t.string "bank_code"
    t.string "bank_name"
    t.datetime "cancelled_at"
    t.string "card_company"
    t.string "card_number"
    t.string "card_type"
    t.datetime "created_at", null: false
    t.datetime "due_date"
    t.string "failure_code"
    t.string "failure_message"
    t.string "method"
    t.string "method_detail"
    t.integer "order_id", null: false
    t.string "payment_key"
    t.json "raw_response"
    t.string "receipt_url"
    t.integer "status", default: 0, null: false
    t.string "toss_order_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["order_id"], name: "index_payments_on_order_id"
    t.index ["payment_key"], name: "index_payments_on_payment_key", unique: true
    t.index ["status", "due_date"], name: "index_payments_on_virtual_account_pending"
    t.index ["status"], name: "index_payments_on_status"
    t.index ["toss_order_id"], name: "index_payments_on_toss_order_id", unique: true
    t.index ["user_id", "created_at"], name: "index_payments_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_payments_on_user_id"
  end

  create_table "post_views", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "post_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["post_id"], name: "index_post_views_on_post_id"
    t.index ["user_id", "post_id"], name: "index_post_views_on_user_id_and_post_id", unique: true
    t.index ["user_id"], name: "index_post_views_on_user_id"
  end

  create_table "posts", force: :cascade do |t|
    t.boolean "available_now", default: true
    t.integer "category", default: 0, null: false
    t.integer "comments_count", default: 0
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.text "experience"
    t.integer "likes_count", default: 0
    t.string "portfolio_url"
    t.integer "price"
    t.boolean "price_negotiable", default: false
    t.string "service_type"
    t.string "skills"
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.integer "views_count", default: 0
    t.string "work_period"
    t.string "work_type"
    t.index ["category"], name: "index_posts_on_category"
    t.index ["created_at"], name: "index_posts_on_created_at"
    t.index ["status", "category", "created_at"], name: "index_posts_on_status_category_created_at"
    t.index ["status"], name: "index_posts_on_status"
    t.index ["title"], name: "index_posts_on_title_for_search"
    t.index ["user_id", "created_at"], name: "index_posts_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "reports", force: :cascade do |t|
    t.text "admin_note"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "reason", null: false
    t.integer "reportable_id", null: false
    t.string "reportable_type", null: false
    t.integer "reporter_id", null: false
    t.datetime "resolved_at"
    t.integer "resolved_by_id"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["reportable_type", "reportable_id"], name: "index_reports_on_reportable"
    t.index ["reporter_id", "reportable_type", "reportable_id"], name: "index_reports_on_reporter_and_reportable", unique: true
    t.index ["reporter_id"], name: "index_reports_on_reporter_id"
    t.index ["resolved_by_id"], name: "index_reports_on_resolved_by_id"
  end

  create_table "talent_listings", force: :cascade do |t|
    t.integer "category", default: 0, null: false
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.integer "project_type", default: 0, null: false
    t.string "rate"
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.integer "views_count", default: 0
    t.index ["category"], name: "index_talent_listings_on_category"
    t.index ["created_at"], name: "index_talent_listings_on_created_at"
    t.index ["status"], name: "index_talent_listings_on_status"
    t.index ["user_id", "created_at"], name: "index_talent_listings_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_talent_listings_on_user_id"
  end

  create_table "user_deletions", force: :cascade do |t|
    t.json "activity_stats"
    t.integer "admin_view_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "destroy_scheduled_at"
    t.string "email_hash"
    t.string "email_original"
    t.string "ip_address"
    t.datetime "last_viewed_at"
    t.integer "last_viewed_by"
    t.string "name_original"
    t.datetime "permanently_deleted_at"
    t.string "phone_original"
    t.string "reason_category"
    t.text "reason_detail"
    t.datetime "requested_at", null: false
    t.datetime "restorable_until"
    t.text "snapshot_data"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.json "user_snapshot", null: false
    t.index ["destroy_scheduled_at"], name: "index_user_deletions_on_destroy_scheduled_at"
    t.index ["email_hash"], name: "index_user_deletions_on_email_hash"
    t.index ["restorable_until"], name: "index_user_deletions_on_restorable_until"
    t.index ["status"], name: "index_user_deletions_on_status"
    t.index ["user_id", "status"], name: "index_user_deletions_on_user_id_and_status"
    t.index ["user_id"], name: "index_user_deletions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.text "achievements"
    t.string "affiliation"
    t.integer "ai_analysis_limit"
    t.integer "ai_bonus_credits", default: 0, null: false
    t.json "availability_statuses", default: []
    t.integer "avatar_type", default: 0
    t.string "avatar_url"
    t.text "bio"
    t.datetime "created_at", null: false
    t.text "currently_learning"
    t.string "custom_status"
    t.datetime "deleted_at"
    t.string "email", null: false
    t.json "experiences", default: []
    t.integer "followers_count", default: 0, null: false
    t.integer "following_count", default: 0, null: false
    t.string "github_url"
    t.datetime "guidelines_accepted_at"
    t.boolean "is_admin", default: false, null: false
    t.boolean "is_anonymous", default: true
    t.datetime "last_sign_in_at"
    t.string "linkedin_url"
    t.string "location", limit: 50
    t.string "looking_for", limit: 200
    t.string "name", null: false
    t.string "nickname"
    t.boolean "notifications_enabled", default: true, null: false
    t.string "open_chat_url"
    t.string "password_digest", null: false
    t.datetime "password_reset_sent_at"
    t.string "password_reset_token"
    t.string "portfolio_url"
    t.boolean "privacy_about", default: false, null: false
    t.datetime "privacy_accepted_at"
    t.boolean "privacy_activity", default: false, null: false
    t.boolean "privacy_experience", default: false, null: false
    t.boolean "privacy_posts", default: false, null: false
    t.boolean "profile_completed", default: false
    t.string "provider"
    t.string "remember_digest"
    t.string "role_title"
    t.string "skills"
    t.string "status_message", limit: 100
    t.datetime "terms_accepted_at"
    t.string "terms_version", default: "1.0"
    t.text "toolbox"
    t.string "uid"
    t.datetime "updated_at", null: false
    t.text "work_style"
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["is_admin"], name: "index_users_on_is_admin"
    t.index ["name"], name: "index_users_on_name_for_search"
    t.index ["nickname"], name: "index_users_on_nickname", unique: true
    t.index ["password_reset_token"], name: "index_users_on_password_reset_token", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["role_title"], name: "index_users_on_role_title_for_search"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "admin_view_logs", "users", column: "admin_id"
  add_foreign_key "bookmarks", "users"
  add_foreign_key "chat_room_participants", "chat_rooms"
  add_foreign_key "chat_room_participants", "users"
  add_foreign_key "chat_rooms", "posts", column: "source_post_id"
  add_foreign_key "chat_rooms", "users", column: "initiator_id"
  add_foreign_key "comments", "comments", column: "parent_id", on_delete: :cascade
  add_foreign_key "comments", "posts"
  add_foreign_key "comments", "users"
  add_foreign_key "follows", "users", column: "followed_id"
  add_foreign_key "follows", "users", column: "follower_id"
  add_foreign_key "idea_analyses", "users"
  add_foreign_key "inquiries", "users"
  add_foreign_key "inquiries", "users", column: "responded_by_id"
  add_foreign_key "job_posts", "users"
  add_foreign_key "likes", "users"
  add_foreign_key "messages", "chat_rooms"
  add_foreign_key "messages", "users", column: "sender_id"
  add_foreign_key "notifications", "users", column: "actor_id"
  add_foreign_key "notifications", "users", column: "recipient_id"
  add_foreign_key "oauth_identities", "users"
  add_foreign_key "orders", "chat_rooms"
  add_foreign_key "orders", "messages", column: "offer_message_id"
  add_foreign_key "orders", "posts"
  add_foreign_key "orders", "users"
  add_foreign_key "orders", "users", column: "seller_id"
  add_foreign_key "payments", "orders"
  add_foreign_key "payments", "users"
  add_foreign_key "post_views", "posts"
  add_foreign_key "post_views", "users"
  add_foreign_key "posts", "users"
  add_foreign_key "reports", "users", column: "reporter_id"
  add_foreign_key "reports", "users", column: "resolved_by_id"
  add_foreign_key "talent_listings", "users"
  add_foreign_key "user_deletions", "users"
end
