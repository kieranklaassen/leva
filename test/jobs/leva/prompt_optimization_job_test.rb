# frozen_string_literal: true

require "test_helper"

module Leva
  class PromptOptimizationJobTest < ActiveJob::TestCase
    setup do
      # Configure DSPy with ruby_llm adapter
      DSPy.configure do |config|
        config.lm = DSPy::LM.new("ruby_llm/gemini-2.5-flash")
      end

      @dataset = Dataset.create!(name: "Test Dataset", description: "A test dataset")

      # Create enough records for optimization
      15.times do |i|
        text_content = TextContent.create!(
          text: "Test text #{i}",
          expected_label: %w[positive negative neutral][i % 3]
        )
        @dataset.add_record(text_content)
      end
    end

    test "job creates a prompt with optimization results" do
      optimization_run = @dataset.optimization_runs.create!(
        prompt_name: "Test Prompt",
        mode: :light,
        model: "gemini-2.5-flash",
        status: :pending
      )

      assert_difference "Prompt.count", 1 do
        PromptOptimizationJob.perform_now(optimization_run_id: optimization_run.id)
      end

      prompt = Prompt.last
      assert_equal "Test Prompt", prompt.name
      assert prompt.system_prompt.present?
      assert prompt.user_prompt.present?
      assert prompt.metadata.present?

      optimization_run.reload
      assert_equal "completed", optimization_run.status
      assert_equal prompt.id, optimization_run.prompt_id
    end

    test "job stores optimization metadata" do
      optimization_run = @dataset.optimization_runs.create!(
        prompt_name: "Metadata Test",
        mode: :medium,
        model: "gemini-2.5-flash",
        status: :pending
      )

      PromptOptimizationJob.perform_now(optimization_run_id: optimization_run.id)

      prompt = Prompt.last
      metadata = prompt.metadata

      assert metadata["optimization"].present?
      assert_equal "medium", metadata["optimization"]["mode"]
      assert metadata["optimization"]["score"].present?
      assert metadata["optimization"]["few_shot_examples"].present?
      assert metadata["optimization"]["optimized_at"].present?
    end

    test "job uses custom prompt name" do
      optimization_run = @dataset.optimization_runs.create!(
        prompt_name: "Custom Name",
        mode: :light,
        model: "gemini-2.5-flash",
        status: :pending
      )

      PromptOptimizationJob.perform_now(optimization_run_id: optimization_run.id)

      prompt = Prompt.last
      assert_equal "Custom Name", prompt.name
    end

    test "job respects mode parameter" do
      %i[light medium heavy].each do |mode|
        optimization_run = @dataset.optimization_runs.create!(
          prompt_name: "Mode #{mode} Test",
          mode: mode,
          model: "gemini-2.5-flash",
          status: :pending
        )

        PromptOptimizationJob.perform_now(optimization_run_id: optimization_run.id)

        prompt = Prompt.order(created_at: :desc).first
        assert_equal mode.to_s, prompt.metadata["optimization"]["mode"]
      end
    end

    test "job raises error for nonexistent optimization run" do
      assert_raises ActiveRecord::RecordNotFound do
        PromptOptimizationJob.perform_now(optimization_run_id: 999999)
      end
    end

    test "job fails optimization run for small dataset" do
      small_dataset = Dataset.create!(name: "Small Dataset")
      3.times do |i|
        text_content = TextContent.create!(
          text: "Small text #{i}",
          expected_label: "positive"
        )
        small_dataset.add_record(text_content)
      end

      optimization_run = small_dataset.optimization_runs.create!(
        prompt_name: "Test",
        mode: :light,
        model: "gemini-2.5-flash",
        status: :pending
      )

      assert_raises Leva::InsufficientDataError do
        PromptOptimizationJob.perform_now(optimization_run_id: optimization_run.id)
      end

      optimization_run.reload
      assert_equal "failed", optimization_run.status
      assert optimization_run.error_message.present?
    end

    test "job can be enqueued" do
      optimization_run = @dataset.optimization_runs.create!(
        prompt_name: "Async Test",
        mode: :light,
        model: "gemini-2.5-flash",
        status: :pending
      )

      assert_enqueued_with(job: PromptOptimizationJob) do
        PromptOptimizationJob.perform_later(optimization_run_id: optimization_run.id)
      end
    end

    test "job enqueues to default queue" do
      assert_equal "default", PromptOptimizationJob.new.queue_name
    end

    test "job updates progress during optimization" do
      optimization_run = @dataset.optimization_runs.create!(
        prompt_name: "Progress Test",
        mode: :light,
        model: "gemini-2.5-flash",
        status: :pending
      )

      PromptOptimizationJob.perform_now(optimization_run_id: optimization_run.id)

      optimization_run.reload
      assert_equal 100, optimization_run.progress
      assert_equal "completed", optimization_run.status
    end
  end
end
