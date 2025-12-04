# frozen_string_literal: true

class AddOptimizerToOptimizationRuns < ActiveRecord::Migration[7.2]
  def change
    add_column :leva_optimization_runs, :optimizer, :string, default: "bootstrap", null: false
  end
end
