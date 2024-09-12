class AddRunnerClassToLevaRunnerResults < ActiveRecord::Migration[7.2]
  def change
    add_column :leva_runner_results, :runner_class, :string
  end
end
