# frozen_string_literal: true

class CreateLevaOptimizationRuns < ActiveRecord::Migration[7.2]
  def change
    create_table :leva_optimization_runs do |t|
      t.references :dataset, null: false, foreign_key: { to_table: :leva_datasets }
      t.references :prompt, foreign_key: { to_table: :leva_prompts }
      t.string :status, default: "pending", null: false
      t.string :current_step
      t.integer :progress, default: 0, null: false
      t.integer :examples_processed, default: 0
      t.integer :total_examples
      t.string :prompt_name, null: false
      t.string :mode, default: "light", null: false
      t.text :error_message
      t.json :metadata

      t.timestamps
    end

    add_index :leva_optimization_runs, :status
  end
end
