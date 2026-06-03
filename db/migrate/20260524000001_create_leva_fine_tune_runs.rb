# frozen_string_literal: true

class CreateLevaFineTuneRuns < ActiveRecord::Migration[7.2]
  def change
    create_table :leva_fine_tune_runs do |t|
      t.references :dataset, null: false, foreign_key: { to_table: :leva_datasets }
      t.string :provider, default: "together", null: false
      t.string :base_model, null: false
      t.string :fine_tuned_model_id
      t.string :provider_job_id
      t.string :training_file_id
      t.string :serving_base_url
      t.string :serving_endpoint_id
      t.string :status, default: "pending", null: false
      t.integer :progress, default: 0, null: false
      t.string :current_step
      t.json :hyperparameters
      t.text :error_message

      t.timestamps
    end

    add_index :leva_fine_tune_runs, :status
  end
end
