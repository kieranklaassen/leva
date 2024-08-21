class AddRunnerAndEvaluatorToLevaExperiments < ActiveRecord::Migration[7.2]
  def change
    add_column :leva_experiments, :runner_class, :string
    add_column :leva_experiments, :evaluator_classes, :text
  end
end
