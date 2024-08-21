class MakeExperimentOptionalForRunnerResults < ActiveRecord::Migration[7.2]
  def change
    change_column_null :leva_runner_results, :experiment_id, true
    change_column_null :leva_evaluation_results, :experiment_id, true
  end
end
