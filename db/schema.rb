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

ActiveRecord::Schema.define(version: 0) do

  create_table "age_attributes", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.integer "age_group_id",  null: false
    t.integer "event_type_id", null: false
  end

  create_table "age_categories", unsigned: true, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.string "name", limit: 100
  end

  create_table "age_groups", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.string  "name"
    t.integer "age_category",               default: 0
    t.integer "view_priority"
    t.string  "definition",    limit: 1000
  end

  create_table "branches", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.string "name"
    t.date   "locked_until", default: '2016-12-31'
  end

  create_table "categories", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.string  "name",              null: false
    t.integer "event_maintype_id"
    t.integer "event_subtype_id"
  end

  create_table "counts", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.integer "event_id"
    t.integer "age_group_id"
    t.integer "attendants"
    t.integer "units"
    t.index ["age_group_id"], name: "category_id", using: :btree
    t.index ["event_id"], name: "event_id", using: :btree
  end

  create_table "event_maintypes", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.string  "name",          limit: 50,  null: false
    t.string  "label",         limit: 100
    t.integer "view_priority"
  end

  create_table "event_subtypes", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.string "name", limit: 100, null: false
  end

  create_table "event_types", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.integer "event_maintype_id",              null: false
    t.integer "event_subtype_id"
    t.string  "name"
    t.string  "definition",        limit: 1000
    t.integer "view_priority"
  end

  create_table "events", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.date    "date",                                      null: false
    t.integer "subcategory_id"
    t.integer "branch_id"
    t.string  "name"
    t.integer "event_type_id",                             null: false
    t.integer "attendants",                    default: 0
    t.integer "age_group_id"
    t.string  "comment"
    t.integer "category_id",                               null: false
    t.integer "is_locked",           limit: 1, default: 0
    t.integer "marked_for_deletion", limit: 1, default: 0
    t.index ["branch_id"], name: "branch_id", using: :btree
    t.index ["name"], name: "name", type: :fulltext
    t.index ["subcategory_id"], name: "genre_id", using: :btree
  end

  create_table "genres", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.string "description"
  end

  create_table "subcategories", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.string  "name"
    t.string  "definition",    limit: 1000
    t.boolean "has_comment",                default: false
    t.boolean "is_countable",               default: true
    t.integer "view_priority"
  end

  create_table "subcategory_groups", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.string  "name"
    t.integer "category_id",              null: false
    t.string  "definition",  limit: 1000
  end

  create_table "subcategory_links", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.integer "subcategory_id", null: false
    t.integer "category_id",    null: false
  end

  create_table "translations", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.string   "locale"
    t.string   "key"
    t.text     "value",          limit: 65535
    t.text     "interpolations", limit: 65535
    t.boolean  "is_proc",                      default: false
    t.datetime "created_at",                                   null: false
    t.datetime "updated_at",                                   null: false
  end

  add_foreign_key "counts", "age_groups", name: "counts_ibfk_2"
  add_foreign_key "counts", "events", name: "counts_ibfk_1"
  add_foreign_key "events", "branches", name: "events_ibfk_2"
end
