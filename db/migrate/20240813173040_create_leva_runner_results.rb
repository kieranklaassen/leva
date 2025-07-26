class CreateLevaRunnerResults < ActiveRecord::Migration[7.2]
  def change
    create_table :leva_runner_results do |t|
      t.references :experiment, null: true, foreign_key: { to_table: :leva_experiments }
      t.references :dataset_record, null: false, foreign_key: { to_table: :leva_dataset_records }
      t.references :prompt, null: false, foreign_key: { to_table: :leva_prompts }
      t.integer :prompt_version
      t.text :prediction
      t.string :runner_class

      t.timestamps
    end
  end
end
