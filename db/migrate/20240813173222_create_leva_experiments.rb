class CreateLevaExperiments < ActiveRecord::Migration[7.2]
  def change
    create_table :leva_experiments do |t|
      t.string :name
      t.references :dataset, null: false, foreign_key: true
      t.references :prompt, null: true, foreign_key: true
      t.integer :status
      t.text :metadata

      t.timestamps
    end
  end
end
