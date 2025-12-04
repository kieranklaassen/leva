# frozen_string_literal: true

class AddModelToOptimizationRuns < ActiveRecord::Migration[7.2]
  def change
    add_column :leva_optimization_runs, :model, :string
  end
end
