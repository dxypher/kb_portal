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

ActiveRecord::Schema[8.0].define(version: 2025_09_22_230357) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "documents", force: :cascade do |t|
    t.integer "team_id"
    t.string "title"
    t.string "source_type"
    t.text "body"
    t.integer "tokens"
    t.string "visibility"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id", "title"], name: "index_documents_on_team_id_and_title"
  end

  create_table "memberships", force: :cascade do |t|
    t.integer "team_id"
    t.integer "user_id"
    t.string "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id", "user_id"], name: "index_memberships_on_team_id_and_user_id", unique: true
  end

  create_table "summaries", force: :cascade do |t|
    t.bigint "document_id", null: false
    t.bigint "team_id", null: false
    t.text "content"
    t.string "llm_name"
    t.integer "tokens_in"
    t.integer "tokens_out"
    t.integer "latency_ms"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_id"], name: "index_summaries_on_document_id"
    t.index ["team_id"], name: "index_summaries_on_team_id"
  end

  create_table "teams", force: :cascade do |t|
    t.string "name"
    t.string "plan"
    t.integer "quota_daily"
    t.datetime "quota_reset_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "password_digest"
    t.string "name"
    t.datetime "last_sign_in_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "summaries", "documents"
  add_foreign_key "summaries", "teams"
end
