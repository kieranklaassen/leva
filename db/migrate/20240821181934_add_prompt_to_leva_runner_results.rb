class AddPromptToLevaRunnerResults < ActiveRecord::Migration[7.2]
  def change
    add_reference :leva_runner_results, :prompt, null: false, foreign_key: { to_table: :leva_prompts }
  end
end
