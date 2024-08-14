class CreateLevaExperiments < ActiveRecord::Migration[7.2]
  def change
    create_table :leva_experiments do |t|
      t.string :name
      t.references :leva_dataset, null: false, foreign_key: true
      t.references :leva_prompt, null: true, foreign_key: true
      t.integer :status
      t.text :metadata

      t.timestamps
    end
  end
end
