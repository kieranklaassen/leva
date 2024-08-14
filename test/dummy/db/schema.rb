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

ActiveRecord::Schema[7.2].define(version: 2024_08_13_174509) do
  create_table "leva_dataset_records", force: :cascade do |t|
    t.integer "dataset_id", null: false
    t.string "recordable_type", null: false
    t.integer "recordable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dataset_id"], name: "index_leva_dataset_records_on_dataset_id"
    t.index ["recordable_type", "recordable_id"], name: "index_leva_dataset_records_on_recordable"
  end

  create_table "leva_datasets", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "leva_evaluation_results", force: :cascade do |t|
    t.integer "experiment_id", null: false
    t.integer "dataset_record_id", null: false
    t.string "prediction"
    t.float "score"
    t.string "label"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dataset_record_id"], name: "index_leva_evaluation_results_on_dataset_record_id"
    t.index ["experiment_id"], name: "index_leva_evaluation_results_on_experiment_id"
  end

  create_table "leva_experiments", force: :cascade do |t|
    t.string "name"
    t.integer "dataset_id", null: false
    t.integer "prompt_id"
    t.integer "status"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dataset_id"], name: "index_leva_experiments_on_dataset_id"
    t.index ["prompt_id"], name: "index_leva_experiments_on_prompt_id"
  end

  create_table "leva_prompts", force: :cascade do |t|
    t.string "name"
    t.integer "version"
    t.text "system_prompt"
    t.text "user_prompt"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "text_contents", force: :cascade do |t|
    t.text "text"
    t.string "expected_label"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "leva_dataset_records", "datasets"
  add_foreign_key "leva_evaluation_results", "dataset_records"
  add_foreign_key "leva_evaluation_results", "experiments"
  add_foreign_key "leva_experiments", "datasets"
  add_foreign_key "leva_experiments", "prompts"
end
