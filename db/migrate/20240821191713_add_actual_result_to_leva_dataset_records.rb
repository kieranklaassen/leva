class AddActualResultToLevaDatasetRecords < ActiveRecord::Migration[7.2]
  def change
    add_column :leva_runner_results, :actual_result, :text
  end
end
