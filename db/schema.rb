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

ActiveRecord::Schema[7.2].define(version: 2026_10_05_133100) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "games", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "lobby_id"
    t.bigint "white_player_id", null: false
    t.bigint "black_player_id", null: false
    t.string "status", default: "waiting", null: false
    t.string "turn", default: "white", null: false
    t.string "result"
    t.jsonb "board_state", default: {}, null: false
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["black_player_id"], name: "index_games_on_black_player_id"
    t.index ["lobby_id"], name: "index_games_on_lobby_id"
    t.index ["status"], name: "index_games_on_status"
    t.index ["turn"], name: "index_games_on_turn"
    t.index ["user_id"], name: "index_games_on_user_id"
    t.index ["white_player_id"], name: "index_games_on_white_player_id"
  end

  create_table "lobbies", force: :cascade do |t|
    t.bigint "host_id", null: false
    t.bigint "guest_id"
    t.string "status", default: "waiting", null: false
    t.string "time_control", default: "10+0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["guest_id"], name: "index_lobbies_on_guest_id"
    t.index ["host_id"], name: "index_lobbies_on_host_id"
    t.index ["status"], name: "index_lobbies_on_status"
  end

  create_table "users", force: :cascade do |t|
    t.string "username", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((email)::text)", name: "index_users_on_lower_email", unique: true
    t.index "lower((username)::text)", name: "index_users_on_lower_username", unique: true
  end

  add_foreign_key "games", "lobbies"
  add_foreign_key "games", "users"
  add_foreign_key "games", "users", column: "black_player_id"
  add_foreign_key "games", "users", column: "white_player_id"
  add_foreign_key "lobbies", "users", column: "guest_id"
  add_foreign_key "lobbies", "users", column: "host_id"
end
