# frozen_string_literal: true

# Experiments already allow no prompt; runner results now do too, so a runner
# that owns its prompt (an application's production prompt) can store results.
class AllowLevaRunnerResultsWithoutPrompt < ActiveRecord::Migration[7.2]
  def change
    change_column_null :leva_runner_results, :prompt_id, true
  end
end
