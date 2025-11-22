# frozen_string_literal: true

require "test_helper"

class Leva::TestRunnerWithContext < Leva::BaseRun
  def execute(record)
    "test prediction"
  end

  def to_llm_context(record)
    { runner_specific_field: "runner_value" }
  end
end

module Leva
  class WorkbenchControllerTest < ActionDispatch::IntegrationTest
    setup do
      @routes = Engine.routes
      @text_content = TextContent.create!(text: "Test text", expected_label: "positive")
      @dataset = Dataset.create!(name: "Test Dataset")
      @dataset_record = @dataset.dataset_records.create!(recordable: @text_content)
      @prompt = Prompt.create!(
        name: "Test Prompt",
        system_prompt: "You are a test assistant",
        user_prompt: "Text: {{ text }}, Runner field: {{ runner_specific_field }}"
      )
    end

    test "index shows merged context when runner is selected" do
      get leva.workbench_index_path(
        prompt_id: @prompt.id,
        dataset_record_id: @dataset_record.id,
        runner: Leva::TestRunnerWithContext.name
      )

      assert_response :success

      # Verify the page shows both contexts in the liquid tags section
      assert_match(/Available Variables/, response.body)
      assert_match(/From Record:/, response.body)
      assert_match(/From Runner:/, response.body)
      assert_match(/runner_specific_field/, response.body)
    end

    test "run action uses runner context" do
      post leva.run_workbench_index_path, params: {
        prompt_id: @prompt.id,
        dataset_record_id: @dataset_record.id,
        runner: Leva::TestRunnerWithContext.name
      }

      assert_redirected_to leva.workbench_index_path(
        prompt_id: @prompt.id,
        dataset_record_id: @dataset_record.id,
        runner: Leva::TestRunnerWithContext.name
      )

      # Verify runner result was created
      runner_result = RunnerResult.last
      assert_equal "test prediction", runner_result.prediction
      assert_equal TestRunnerWithContext.name, runner_result.runner_class
    end
  end
end
