# frozen_string_literal: true

require "test_helper"

module Leva
  class PromptOptimizerTest < ActiveSupport::TestCase
    setup do
      @dataset = Leva::Dataset.create!(name: "Test Dataset")

      # Create enough records for optimization
      15.times do |i|
        text_content = TextContent.create!(
          text: "Test text #{i}",
          expected_label: %w[positive negative neutral][i % 3]
        )
        @dataset.add_record(text_content)
      end

      @optimizer = PromptOptimizer.new(dataset: @dataset)
    end

    test "MINIMUM_EXAMPLES is defined" do
      assert_equal 10, PromptOptimizer::MINIMUM_EXAMPLES
    end

    test "MODES defines optimization modes" do
      assert PromptOptimizer::MODES.key?(:light)
      assert PromptOptimizer::MODES.key?(:medium)
      assert PromptOptimizer::MODES.key?(:heavy)
    end

    test "can_optimize? returns true with enough records" do
      assert @optimizer.can_optimize?
    end

    test "can_optimize? returns false with too few records" do
      small_dataset = Leva::Dataset.create!(name: "Small Dataset")
      5.times do |i|
        text_content = TextContent.create!(
          text: "Small text #{i}",
          expected_label: "positive"
        )
        small_dataset.add_record(text_content)
      end

      optimizer = PromptOptimizer.new(dataset: small_dataset)
      assert_not optimizer.can_optimize?
    end

    test "records_needed returns correct count" do
      assert_equal 0, @optimizer.records_needed

      small_dataset = Leva::Dataset.create!(name: "Small Dataset")
      3.times do |i|
        text_content = TextContent.create!(
          text: "Small text #{i}",
          expected_label: "positive"
        )
        small_dataset.add_record(text_content)
      end

      optimizer = PromptOptimizer.new(dataset: small_dataset)
      assert_equal 7, optimizer.records_needed
    end

    test "optimize raises InsufficientDataError with too few records" do
      small_dataset = Leva::Dataset.create!(name: "Small Dataset")
      3.times do |i|
        text_content = TextContent.create!(
          text: "Small text #{i}",
          expected_label: "positive"
        )
        small_dataset.add_record(text_content)
      end

      optimizer = PromptOptimizer.new(dataset: small_dataset)

      assert_raises(Leva::InsufficientDataError) do
        optimizer.optimize
      end
    end

    test "optimize returns result with expected structure" do
      result = @optimizer.optimize

      assert result.key?(:system_prompt)
      assert result.key?(:user_prompt)
      assert result.key?(:metadata)
    end

    test "optimize result metadata contains optimization info" do
      result = @optimizer.optimize

      metadata = result[:metadata]
      assert metadata.key?(:optimization)
      assert metadata[:optimization].key?(:score)
      assert metadata[:optimization].key?(:mode)
      assert metadata[:optimization].key?(:few_shot_examples)
      assert metadata[:optimization].key?(:optimized_at)
    end

    test "optimize with different modes" do
      %i[light medium heavy].each do |mode|
        optimizer = PromptOptimizer.new(dataset: @dataset, mode: mode)
        result = optimizer.optimize

        assert_equal mode.to_s, result[:metadata][:optimization][:mode]
      end
    end

    test "optimize includes few-shot examples" do
      result = @optimizer.optimize

      examples = result[:metadata][:optimization][:few_shot_examples]
      assert_kind_of Array, examples
      assert examples.any?
    end

    test "user_prompt contains template variables" do
      result = @optimizer.optimize

      assert_match(/\{\{/, result[:user_prompt])
    end

    test "custom metric can be provided" do
      custom_metric = ->(example, prediction) { 0.5 }
      optimizer = PromptOptimizer.new(
        dataset: @dataset,
        metric: custom_metric
      )

      result = optimizer.optimize
      assert result.key?(:system_prompt)
    end
  end
end
