# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 13) do

  create_table "accounts", force: :cascade do |t|
    t.string   "name"
    t.string   "surname"
    t.string   "email"
    t.string   "crypted_password"
    t.string   "role"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "configuration_templates", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.text     "template",   limit: 4294967295
  end

  create_table "devices", force: :cascade do |t|
    t.string   "keytype"
    t.string   "key"
    t.integer  "configuration_template_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "image_id"
  end

  create_table "global_configurations", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.string   "value"
  end

  create_table "images", force: :cascade do |t|
    t.string   "model"
    t.string   "version"
    t.string   "file_name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "management_switches", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.string   "subscriber_id"
    t.string   "base_ip_address"
    t.string   "number_of_vc_member"
  end

end
