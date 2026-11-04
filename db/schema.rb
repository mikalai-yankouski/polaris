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

ActiveRecord::Schema[8.1].define(version: 2026_11_02_140000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "btree_gist"
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "amenities", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_amenities_on_name", unique: true
  end

  create_table "buildings", force: :cascade do |t|
    t.string "name", null: false
    t.string "address"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "reservation_id", null: false
    t.string "tracking_id", null: false
    t.integer "status", default: 0, null: false
    t.integer "method", default: 0, null: false
    t.integer "amount_cents", null: false
    t.string "currency", default: "BYN", null: false
    t.string "bepaid_uid"
    t.boolean "test", default: true, null: false
    t.jsonb "raw_response", default: {}, null: false
    t.datetime "paid_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["reservation_id"], name: "index_payments_on_reservation_id"
    t.index ["status"], name: "index_payments_on_status"
    t.index ["tracking_id"], name: "index_payments_on_tracking_id", unique: true
  end

  create_table "price_rules", force: :cascade do |t|
    t.bigint "zone_id", null: false
    t.integer "day_kind", default: 0, null: false
    t.time "starts_at_time", null: false
    t.time "ends_at_time", null: false
    t.integer "hourly_rate_cents", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["zone_id", "day_kind"], name: "index_price_rules_on_zone_id_and_day_kind"
    t.index ["zone_id"], name: "index_price_rules_on_zone_id"
  end

  create_table "reservations", force: :cascade do |t|
    t.bigint "zone_id", null: false
    t.bigint "user_id"
    t.datetime "starts_at"
    t.datetime "ends_at"
    t.integer "guests_count", default: 1, null: false
    t.text "purpose"
    t.integer "status", default: 0, null: false
    t.integer "total_price_cents", default: 0, null: false
    t.text "review_note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "reminder_sent_at"
    t.boolean "children_party", default: false, null: false
    t.integer "cleaning_minutes", default: 15, null: false
    t.string "guest_name"
    t.string "guest_phone"
    t.date "requested_date"
    t.index ["guest_phone"], name: "index_reservations_on_guest_phone"
    t.index ["status"], name: "index_reservations_on_status"
    t.index ["user_id", "created_at"], name: "index_reservations_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_reservations_on_user_id"
    t.index ["zone_id", "starts_at"], name: "index_reservations_on_zone_id_and_starts_at"
    t.index ["zone_id"], name: "index_reservations_on_zone_id"
    t.exclusion_constraint "zone_id WITH =, tsrange(starts_at, (ends_at + make_interval(mins => cleaning_minutes)), '[)'::text) WITH &&", where: "(status = ANY (ARRAY[0, 1])) AND (starts_at IS NOT NULL) AND (ends_at IS NOT NULL)", using: :gist, name: "reservations_no_overlaps"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name", default: "", null: false
    t.string "phone"
    t.integer "role", default: 0, null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "zone_adjacencies", force: :cascade do |t|
    t.bigint "zone_id", null: false
    t.bigint "adjacent_zone_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["adjacent_zone_id"], name: "index_zone_adjacencies_on_adjacent_zone_id"
    t.index ["zone_id", "adjacent_zone_id"], name: "index_zone_adjacencies_on_zone_id_and_adjacent_zone_id", unique: true
    t.index ["zone_id"], name: "index_zone_adjacencies_on_zone_id"
  end

  create_table "zone_amenities", force: :cascade do |t|
    t.bigint "zone_id", null: false
    t.bigint "amenity_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["amenity_id"], name: "index_zone_amenities_on_amenity_id"
    t.index ["zone_id", "amenity_id"], name: "index_zone_amenities_on_zone_id_and_amenity_id", unique: true
    t.index ["zone_id"], name: "index_zone_amenities_on_zone_id"
  end

  create_table "zones", force: :cascade do |t|
    t.bigint "building_id", null: false
    t.string "name", null: false
    t.text "description"
    t.integer "capacity", default: 1, null: false
    t.integer "floor", default: 1, null: false
    t.integer "hourly_rate_cents", default: 0, null: false
    t.integer "min_duration_minutes", default: 60, null: false
    t.integer "max_duration_minutes", default: 480, null: false
    t.boolean "requires_approval", default: true, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "room_type", default: 0, null: false
    t.string "building_code"
    t.integer "cleaning_buffer_minutes", default: 15, null: false
    t.bigint "cover_attachment_id"
    t.index ["building_id"], name: "index_zones_on_building_id"
    t.index ["cover_attachment_id"], name: "index_zones_on_cover_attachment_id"
    t.index ["name"], name: "index_zones_on_name", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "payments", "reservations"
  add_foreign_key "price_rules", "zones"
  add_foreign_key "reservations", "users"
  add_foreign_key "reservations", "zones"
  add_foreign_key "sessions", "users"
  add_foreign_key "zone_adjacencies", "zones"
  add_foreign_key "zone_adjacencies", "zones", column: "adjacent_zone_id"
  add_foreign_key "zone_amenities", "amenities"
  add_foreign_key "zone_amenities", "zones"
  add_foreign_key "zones", "buildings"
end
