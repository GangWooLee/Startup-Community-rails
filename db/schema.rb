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

ActiveRecord::Schema[8.1].define(version: 2025_12_27_124200) do
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

  create_table "users", force: :cascade do |t|
    t.text "achievements"
    t.string "affiliation"
    t.json "availability_statuses", default: []
    t.string "avatar_url"
    t.text "bio"
    t.datetime "created_at", null: false
    t.string "custom_status"
    t.string "email", null: false
    t.string "github_url"
    t.boolean "is_admin", default: false, null: false
    t.datetime "last_sign_in_at"
    t.string "linkedin_url"
    t.string "name", null: false
    t.string "open_chat_url"
    t.string "password_digest", null: false
    t.string "portfolio_url"
    t.string "provider"
    t.string "role_title"
    t.string "skills"
    t.string "uid"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["is_admin"], name: "index_users_on_is_admin"
    t.index ["name"], name: "index_users_on_name_for_search"
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["role_title"], name: "index_users_on_role_title_for_search"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "bookmarks", "users"
  add_foreign_key "chat_room_participants", "chat_rooms"
  add_foreign_key "chat_room_participants", "users"
  add_foreign_key "chat_rooms", "posts", column: "source_post_id"
  add_foreign_key "chat_rooms", "users", column: "initiator_id"
  add_foreign_key "comments", "comments", column: "parent_id", on_delete: :cascade
  add_foreign_key "comments", "posts"
  add_foreign_key "comments", "users"
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
  add_foreign_key "posts", "users"
  add_foreign_key "talent_listings", "users"
end
