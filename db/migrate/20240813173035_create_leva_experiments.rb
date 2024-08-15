class CreateLevaExperiments < ActiveRecord::Migration[7.2]
  def change
    create_table :leva_experiments do |t|
      t.string :name
      t.text :description
      t.references :dataset, null: false, foreign_key: { to_table: :leva_datasets }
      t.references :prompt, null: true, foreign_key: { to_table: :leva_prompts }
      t.integer :status
      t.text :metadata

      t.timestamps
    end
  end
end
