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

  create_table "age_attributes", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.integer "age_group_id", null: false
    t.integer "event_type_id", null: false
  end

  create_table "age_categories", id: :integer, unsigned: true, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.string "name", limit: 100
  end

  create_table "age_groups", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.string "name"
    t.integer "age_category", default: 0
    t.integer "view_priority"
    t.string "definition", limit: 1000
  end

  create_table "branches", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.string "name"
    t.date "locked_until", default: "2016-12-31"
  end

  create_table "categories", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.string "name", null: false
    t.integer "event_maintype_id"
    t.integer "event_subtype_id"
  end

  create_table "event_maintypes", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.string "name", limit: 50, null: false
    t.string "label", limit: 100
    t.integer "view_priority"
  end

  create_table "event_subtypes", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.string "name", limit: 100, null: false
    t.string "label", limit: 100
  end

  create_table "event_types", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.integer "event_maintype_id", null: false
    t.integer "event_subtype_id"
    t.string "name"
    t.string "definition", limit: 1000
    t.integer "view_priority"
  end

  create_table "events", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.date "date", null: false
    t.integer "subcategory_id"
    t.integer "branch_id"
    t.string "name"
    t.integer "event_type_id", null: false
    t.integer "attendants", default: 0
    t.integer "age_group_id"
    t.string "comment"
    t.integer "category_id", null: false
    t.integer "is_locked", limit: 1, default: 0
    t.integer "marked_for_deletion", limit: 1, default: 0
    t.boolean "added_after_lock", default: false
    t.index ["branch_id"], name: "branch_id"
    t.index ["subcategory_id"], name: "genre_id"
  end

  create_table "subcategories", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.string "name"
    t.string "definition", limit: 1000
    t.boolean "has_comment", default: false
    t.boolean "is_countable", default: true
    t.integer "view_priority"
  end

  create_table "subcategory_links", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.integer "subcategory_id", null: false
    t.integer "category_id", null: false
  end

  create_table "templates", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.string "name", null: false
    t.integer "branch_id", null: false
    t.integer "event_type_id"
    t.integer "category_id"
    t.integer "subcategory_id"
    t.integer "age_group_id"
  end

  add_foreign_key "events", "branches", name: "events_ibfk_2"
end
