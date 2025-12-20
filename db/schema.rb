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

ActiveRecord::Schema[8.1].define(version: 2025_12_20_135128) do
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
    t.index ["bookmarkable_type", "bookmarkable_id"], name: "index_bookmarks_on_bookmarkable"
    t.index ["bookmarkable_type", "bookmarkable_id"], name: "index_bookmarks_on_bookmarkable_type_and_bookmarkable_id"
    t.index ["user_id", "bookmarkable_type", "bookmarkable_id"], name: "index_bookmarks_on_user_and_bookmarkable", unique: true
    t.index ["user_id", "created_at"], name: "index_bookmarks_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_bookmarks_on_user_id"
  end

  create_table "comments", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.integer "post_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
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
    t.index ["likeable_type", "likeable_id"], name: "index_likes_on_likeable"
    t.index ["likeable_type", "likeable_id"], name: "index_likes_on_likeable_type_and_likeable_id"
    t.index ["user_id", "likeable_type", "likeable_id"], name: "index_likes_on_user_and_likeable", unique: true
    t.index ["user_id"], name: "index_likes_on_user_id"
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

  create_table "posts", force: :cascade do |t|
    t.integer "category", default: 0, null: false
    t.integer "comments_count", default: 0
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.integer "likes_count", default: 0
    t.integer "price"
    t.boolean "price_negotiable", default: false
    t.string "service_type"
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.integer "views_count", default: 0
    t.string "work_period"
    t.index ["category"], name: "index_posts_on_category"
    t.index ["created_at"], name: "index_posts_on_created_at"
    t.index ["status"], name: "index_posts_on_status"
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
    t.string "affiliation"
    t.json "availability_statuses", default: []
    t.string "avatar_url"
    t.text "bio"
    t.datetime "created_at", null: false
    t.string "custom_status"
    t.string "email", null: false
    t.string "github_url"
    t.datetime "last_sign_in_at"
    t.string "linkedin_url"
    t.string "name", null: false
    t.string "password_digest", null: false
    t.string "portfolio_url"
    t.string "provider"
    t.string "role_title"
    t.string "skills"
    t.string "uid"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "bookmarks", "users"
  add_foreign_key "comments", "posts"
  add_foreign_key "comments", "users"
  add_foreign_key "job_posts", "users"
  add_foreign_key "likes", "users"
  add_foreign_key "oauth_identities", "users"
  add_foreign_key "posts", "users"
  add_foreign_key "talent_listings", "users"
end
