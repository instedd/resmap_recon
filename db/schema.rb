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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20140131141418) do

  create_table "mapping_entries", :force => true do |t|
    t.integer  "source_list_id"
    t.integer  "source_property"
    t.string   "source_value"
    t.string   "target_value"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  add_index "mapping_entries", ["source_list_id", "source_property", "source_value"], :name => "by_source_value", :unique => true
  add_index "mapping_entries", ["source_list_id", "source_property", "target_value"], :name => "by_target_value"

  create_table "projects", :force => true do |t|
    t.string   "name"
    t.text     "config"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.binary   "hierarchy"
  end

  create_table "source_lists", :force => true do |t|
    t.integer  "project_id"
    t.integer  "collection_id"
    t.text     "config"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "user_project_memberships", :force => true do |t|
    t.integer  "user_id"
    t.integer  "project_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "user_project_memberships", ["project_id"], :name => "index_user_project_memberships_on_project_id"
  add_index "user_project_memberships", ["user_id"], :name => "index_user_project_memberships_on_user_id"

  create_table "users", :force => true do |t|
    t.string   "email"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

end
