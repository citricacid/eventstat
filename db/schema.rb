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
    t.integer "has_district_category", default: 0
  end

  create_table "categories", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.string "name", null: false
    t.integer "event_maintype_id"
    t.integer "event_subtype_id"
  end

  create_table "district_categories", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.integer "branch_id", null: false
    t.string "name", null: false
    t.boolean "treat_as_category", default: false, null: false
    t.index ["branch_id"], name: "branch_id"
  end

  create_table "district_links", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.integer "subcategory_id", null: false
    t.integer "district_category_id", null: false
    t.index ["district_category_id"], name: "district_category_id"
    t.index ["subcategory_id", "district_category_id"], name: "subcategory_id", unique: true
  end

  create_table "event_maintypes", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.string "name", limit: 50, null: false
    t.string "label", limit: 100
    t.integer "view_priority"
  end

  create_table "event_subtypes", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.string "name", limit: 100, null: false
    t.string "label", limit: 50
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
    t.integer "district_category_id"
    t.index ["branch_id"], name: "branch_id"
    t.index ["subcategory_id"], name: "genre_id"
  end

  create_table "extra_categories", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.string "name", null: false
    t.integer "extra_type_id", null: false
    t.index ["extra_type_id"], name: "extra_type_id"
  end

  create_table "extra_links", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.integer "branch_id", null: false
    t.integer "extra_category_id", null: false
    t.integer "extra_subcategory_id", null: false
    t.integer "category_id", null: false
    t.index ["branch_id"], name: "branch_id"
    t.index ["category_id"], name: "category_id"
  end

  create_table "extra_subcategories", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.string "name", null: false
  end

  create_table "extra_types", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.string "name", null: false
    t.integer "branch_id", null: false
    t.index ["branch_id"], name: "branch_id"
  end

  create_table "queries", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.string "name", null: false
  end

  create_table "query_parameters", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.integer "query_id", null: false
    t.string "element_name", null: false
    t.string "element_value", null: false
    t.index ["query_id"], name: "query_id"
  end

  create_table "special_types", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.string "name", null: false
    t.integer "branch_id", null: false
    t.index ["branch_id"], name: "branch_id"
  end

  create_table "subcategories", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.string "name"
    t.string "definition", limit: 1000
    t.boolean "has_comment", default: false
    t.boolean "is_countable", default: true
    t.integer "view_priority"
    t.string "type", limit: 100, default: "InternalSubcategory"
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
    t.integer "extra_category_id"
    t.string "registration_type", limit: 20, default: "library_only"
  end

  add_foreign_key "district_links", "district_categories", name: "district_links_ibfk_1", on_delete: :cascade
  add_foreign_key "district_links", "subcategories", name: "district_links_ibfk_2", on_delete: :cascade
  add_foreign_key "events", "branches", name: "events_ibfk_2"
  add_foreign_key "extra_categories", "extra_types", name: "extra_categories_ibfk_1"
  add_foreign_key "extra_links", "branches", name: "extra_links_ibfk_1", on_delete: :cascade
  add_foreign_key "extra_links", "categories", name: "extra_links_ibfk_2", on_delete: :cascade
  add_foreign_key "extra_types", "branches", name: "extra_types_ibfk_1"
  add_foreign_key "query_parameters", "queries", name: "query_parameters_ibfk_1"
  add_foreign_key "special_types", "branches", name: "special_types_ibfk_1"
end
