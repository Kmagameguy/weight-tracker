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

ActiveRecord::Schema[8.1].define(version: 2026_05_25_132028) do
  create_table "food_entries", force: :cascade do |t|
    t.integer "calories", default: 0, null: false
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["date"], name: "index_food_entries_on_date"
    t.index ["user_id"], name: "index_food_entries_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "weight_entries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.decimal "weight", precision: 4, scale: 1, null: false
    t.index ["user_id", "date"], name: "index_weight_entries_on_user_id_and_date", unique: true
    t.index ["user_id"], name: "index_weight_entries_on_user_id"
  end

  add_foreign_key "food_entries", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "weight_entries", "users"
end
