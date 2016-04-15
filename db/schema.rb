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

ActiveRecord::Schema.define(version: 20160415132529) do

  create_table "ingredients", force: true do |t|
    t.string   "ing_name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "recipe2_ingredients", force: true do |t|
    t.integer  "ing_id"
    t.integer  "recipe_id"
    t.integer  "quantity"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "recipes", force: true do |t|
    t.string   "recipe_name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "search_combinations", force: true do |t|
    t.string   "query_name"
    t.integer  "fitness"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
