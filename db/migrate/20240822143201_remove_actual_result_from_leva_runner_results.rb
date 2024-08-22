class RemoveActualResultFromLevaRunnerResults < ActiveRecord::Migration[7.2]
  def change
    remove_column :leva_runner_results, :actual_result, :text
  end
end
