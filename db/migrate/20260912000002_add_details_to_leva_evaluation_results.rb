# frozen_string_literal: true

# The evaluator's reasoning next to its score: a judge's explanation, the
# failed assertion, the rubric verdict.
class AddDetailsToLevaEvaluationResults < ActiveRecord::Migration[7.2]
  def change
    add_column :leva_evaluation_results, :details, :text
  end
end
