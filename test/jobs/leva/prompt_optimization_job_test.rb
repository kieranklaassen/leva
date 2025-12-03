# frozen_string_literal: true

require "test_helper"

module Leva
  class PromptOptimizationJobTest < ActiveJob::TestCase
    setup do
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
      assert_difference "Prompt.count", 1 do
        PromptOptimizationJob.perform_now(
          dataset_id: @dataset.id,
          prompt_name: "Test Prompt",
          mode: :light
        )
      end

      prompt = Prompt.last
      assert_equal "Test Prompt", prompt.name
      assert prompt.system_prompt.present?
      assert prompt.user_prompt.present?
      assert prompt.metadata.present?
    end

    test "job stores optimization metadata" do
      PromptOptimizationJob.perform_now(
        dataset_id: @dataset.id,
        prompt_name: "Metadata Test",
        mode: :medium
      )

      prompt = Prompt.last
      metadata = prompt.metadata

      assert metadata["optimization"].present?
      assert_equal "medium", metadata["optimization"]["mode"]
      assert metadata["optimization"]["score"].present?
      assert metadata["optimization"]["few_shot_examples"].present?
      assert metadata["optimization"]["optimized_at"].present?
    end

    test "job uses default prompt name format" do
      PromptOptimizationJob.perform_now(
        dataset_id: @dataset.id,
        prompt_name: "Custom Name",
        mode: :light
      )

      prompt = Prompt.last
      assert_equal "Custom Name", prompt.name
    end

    test "job respects mode parameter" do
      %i[light medium heavy].each do |mode|
        PromptOptimizationJob.perform_now(
          dataset_id: @dataset.id,
          prompt_name: "Mode #{mode} Test",
          mode: mode
        )

        prompt = Prompt.order(created_at: :desc).first
        assert_equal mode.to_s, prompt.metadata["optimization"]["mode"]
      end
    end

    test "job raises error for nonexistent dataset" do
      assert_raises ActiveRecord::RecordNotFound do
        PromptOptimizationJob.perform_now(
          dataset_id: 999999,
          prompt_name: "Test",
          mode: :light
        )
      end
    end

    test "job raises InsufficientDataError for small dataset" do
      small_dataset = Dataset.create!(name: "Small Dataset")
      3.times do |i|
        text_content = TextContent.create!(
          text: "Small text #{i}",
          expected_label: "positive"
        )
        small_dataset.add_record(text_content)
      end

      assert_raises Leva::InsufficientDataError do
        PromptOptimizationJob.perform_now(
          dataset_id: small_dataset.id,
          prompt_name: "Test",
          mode: :light
        )
      end
    end

    test "job can be enqueued" do
      assert_enqueued_with(job: PromptOptimizationJob) do
        PromptOptimizationJob.perform_later(
          dataset_id: @dataset.id,
          prompt_name: "Async Test",
          mode: :light
        )
      end
    end

    test "job enqueues to default queue" do
      assert_equal "default", PromptOptimizationJob.new.queue_name
    end
  end
end
