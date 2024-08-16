class UpdateLevaEvaluationResults < ActiveRecord::Migration[7.2]
  def change
    add_reference :leva_evaluation_results, :runner_result, null: false, foreign_key: { to_table: :leva_runner_results }
    add_column :leva_evaluation_results, :evaluator_class, :string, null: false
    remove_column :leva_evaluation_results, :prediction, :string
    remove_column :leva_evaluation_results, :label, :string
  end
end
