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

ActiveRecord::Schema[8.1].define(version: 2026_11_06_011353) do
  create_table "api_tokens", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "token_digest", null: false
    t.string "name"
    t.datetime "last_used_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token_digest"], name: "index_api_tokens_on_token_digest", unique: true
    t.index ["user_id"], name: "index_api_tokens_on_user_id"
  end

  create_table "blood_pressure_readings", force: :cascade do |t|
    t.integer "systolic", null: false
    t.integer "diastolic", null: false
    t.date "date", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "uuid", null: false
    t.index ["user_id", "date"], name: "index_blood_pressure_readings_on_user_id_and_date", unique: true
    t.index ["user_id"], name: "index_blood_pressure_readings_on_user_id"
    t.index ["uuid"], name: "index_blood_pressure_readings_on_uuid", unique: true
  end

  create_table "day_tags", force: :cascade do |t|
    t.integer "tag_id", null: false
    t.date "date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "uuid", null: false
    t.index ["date"], name: "index_day_tags_on_date"
    t.index ["tag_id", "date"], name: "index_day_tags_on_tag_id_and_date", unique: true
    t.index ["tag_id"], name: "index_day_tags_on_tag_id"
    t.index ["uuid"], name: "index_day_tags_on_uuid", unique: true
  end

  create_table "deletions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "record_type", null: false
    t.string "uuid", null: false
    t.datetime "deleted_at", null: false
    t.index ["user_id", "deleted_at"], name: "index_deletions_on_user_id_and_deleted_at"
  end

  create_table "food_entries", force: :cascade do |t|
    t.string "name", null: false
    t.integer "calories", default: 0, null: false
    t.date "date", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "uuid", null: false
    t.index ["date"], name: "index_food_entries_on_date"
    t.index ["user_id"], name: "index_food_entries_on_user_id"
    t.index ["uuid"], name: "index_food_entries_on_uuid", unique: true
  end

  create_table "journal_entries", force: :cascade do |t|
    t.date "date", null: false
    t.text "note"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "uuid", null: false
    t.index ["user_id", "date"], name: "index_journal_entries_on_user_id_and_date", unique: true
    t.index ["user_id"], name: "index_journal_entries_on_user_id"
    t.index ["uuid"], name: "index_journal_entries_on_uuid", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "uuid", null: false
    t.index ["user_id", "name"], name: "index_tags_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_tags_on_user_id"
    t.index ["uuid"], name: "index_tags_on_uuid", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "daily_calorie_goal"
    t.string "timezone", default: "Etc/UTC", null: false
    t.boolean "calorie_tracking_enabled", default: true, null: false
    t.boolean "weight_tracking_enabled", default: true, null: false
    t.boolean "blood_pressure_tracking_enabled", default: true, null: false
    t.boolean "journaling_enabled", default: true, null: false
    t.boolean "tagging_enabled", default: true, null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "weight_entries", force: :cascade do |t|
    t.decimal "weight", precision: 4, scale: 1, null: false
    t.date "date", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "uuid", null: false
    t.index ["user_id", "date"], name: "index_weight_entries_on_user_id_and_date", unique: true
    t.index ["user_id"], name: "index_weight_entries_on_user_id"
    t.index ["uuid"], name: "index_weight_entries_on_uuid", unique: true
  end

  add_foreign_key "api_tokens", "users"
  add_foreign_key "blood_pressure_readings", "users"
  add_foreign_key "day_tags", "tags"
  add_foreign_key "food_entries", "users"
  add_foreign_key "journal_entries", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "tags", "users"
  add_foreign_key "weight_entries", "users"
end
