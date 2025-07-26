class CreateLevaEvaluationResults < ActiveRecord::Migration[7.2]
  def change
    create_table :leva_evaluation_results do |t|
      t.references :experiment, null: true, foreign_key: { to_table: :leva_experiments }
      t.references :dataset_record, null: false, foreign_key: { to_table: :leva_dataset_records }
      t.references :runner_result, null: false, foreign_key: { to_table: :leva_runner_results }
      t.string :evaluator_class, null: false
      t.float :score

      t.timestamps
    end
  end
end
