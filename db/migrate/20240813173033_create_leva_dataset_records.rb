class CreateLevaDatasetRecords < ActiveRecord::Migration[7.2]
  def change
    create_table :leva_dataset_records do |t|
      t.references :leva_dataset, null: false, foreign_key: true
      t.references :recordable, polymorphic: true, null: false

      t.timestamps
    end
  end
end
