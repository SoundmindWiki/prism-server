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

ActiveRecord::Schema[8.1].define(version: 2026_09_23_090000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "audit_logs", force: :cascade do |t|
    t.string "action", null: false
    t.string "actor_name", null: false
    t.datetime "created_at", null: false
    t.jsonb "details", default: {}, null: false
    t.string "target_label"
    t.string "target_type"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["action"], name: "index_audit_logs_on_action"
    t.index ["created_at"], name: "index_audit_logs_on_created_at"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "color", default: "slate", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.bigint "parent_id"
    t.integer "position", default: 0, null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_id", "position"], name: "index_categories_on_parent_id_and_position"
    t.index ["parent_id"], name: "index_categories_on_parent_id"
    t.index ["position"], name: "index_categories_on_position"
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "domains", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.bigint "parent_id"
    t.integer "position", default: 0, null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_id", "position"], name: "index_domains_on_parent_id_and_position"
    t.index ["parent_id"], name: "index_domains_on_parent_id"
    t.index ["slug"], name: "index_domains_on_slug", unique: true
  end

  create_table "prompt_domains", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "domain_id", null: false
    t.bigint "prompt_id", null: false
    t.datetime "updated_at", null: false
    t.index ["domain_id"], name: "index_prompt_domains_on_domain_id"
    t.index ["prompt_id", "domain_id"], name: "index_prompt_domains_on_prompt_id_and_domain_id", unique: true
    t.index ["prompt_id"], name: "index_prompt_domains_on_prompt_id"
  end

  create_table "prompt_tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "prompt_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "updated_at", null: false
    t.index ["prompt_id", "tag_id"], name: "index_prompt_tags_on_prompt_id_and_tag_id", unique: true
    t.index ["prompt_id"], name: "index_prompt_tags_on_prompt_id"
    t.index ["tag_id"], name: "index_prompt_tags_on_tag_id"
  end

  create_table "prompt_versions", force: :cascade do |t|
    t.text "body", null: false
    t.string "change_note"
    t.datetime "created_at", null: false
    t.bigint "editor_id"
    t.string "model_hint"
    t.bigint "prompt_id", null: false
    t.text "summary"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.text "usage_notes"
    t.jsonb "variables", default: [], null: false
    t.integer "version_number", null: false
    t.index ["editor_id"], name: "index_prompt_versions_on_editor_id"
    t.index ["prompt_id", "version_number"], name: "index_prompt_versions_on_prompt_id_and_version_number", unique: true
    t.index ["prompt_id"], name: "index_prompt_versions_on_prompt_id"
  end

  create_table "prompts", force: :cascade do |t|
    t.bigint "author_id", null: false
    t.text "body", null: false
    t.bigint "category_id", null: false
    t.integer "copy_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.bigint "last_editor_id"
    t.string "model_hint"
    t.string "slug", null: false
    t.string "status", default: "published", null: false
    t.text "summary"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.text "usage_notes"
    t.jsonb "variables", default: [], null: false
    t.integer "view_count", default: 0, null: false
    t.index ["author_id"], name: "index_prompts_on_author_id"
    t.index ["category_id"], name: "index_prompts_on_category_id"
    t.index ["last_editor_id"], name: "index_prompts_on_last_editor_id"
    t.index ["slug"], name: "index_prompts_on_slug", unique: true
    t.index ["status"], name: "index_prompts_on_status"
    t.index ["updated_at"], name: "index_prompts_on_updated_at"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "ip_address"
    t.datetime "last_active_at", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["expires_at"], name: "index_sessions_on_expires_at"
    t.index ["token"], name: "index_sessions_on_token", unique: true
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tags_on_name", unique: true
    t.index ["slug"], name: "index_tags_on_slug", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "department"
    t.string "email", null: false
    t.string "job_rank"
    t.string "job_title"
    t.datetime "last_signed_in_at"
    t.string "name", null: false
    t.string "password_digest"
    t.string "role", default: "member", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_users_on_active"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "audit_logs", "users", on_delete: :nullify
  add_foreign_key "categories", "categories", column: "parent_id"
  add_foreign_key "domains", "domains", column: "parent_id"
  add_foreign_key "prompt_domains", "domains"
  add_foreign_key "prompt_domains", "prompts"
  add_foreign_key "prompt_tags", "prompts"
  add_foreign_key "prompt_tags", "tags"
  add_foreign_key "prompt_versions", "prompts"
  add_foreign_key "prompt_versions", "users", column: "editor_id"
  add_foreign_key "prompts", "categories"
  add_foreign_key "prompts", "users", column: "author_id"
  add_foreign_key "prompts", "users", column: "last_editor_id"
  add_foreign_key "sessions", "users"
end
