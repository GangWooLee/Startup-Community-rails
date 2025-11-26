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

ActiveRecord::Schema[8.1].define(version: 2025_11_25_210530) do
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

  create_table "posts", force: :cascade do |t|
    t.integer "comments_count", default: 0
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.integer "likes_count", default: 0
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.integer "views_count", default: 0
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
    t.string "avatar_url"
    t.text "bio"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.datetime "last_sign_in_at"
    t.string "name", null: false
    t.string "password_digest", null: false
    t.string "role_title"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "bookmarks", "users"
  add_foreign_key "comments", "posts"
  add_foreign_key "comments", "users"
  add_foreign_key "job_posts", "users"
  add_foreign_key "likes", "users"
  add_foreign_key "posts", "users"
  add_foreign_key "talent_listings", "users"
end
