# frozen_string_literal: true

require "test_helper"

module Leva
  module Optimizers
    class BaseTest < ActiveSupport::TestCase
      # Concrete test implementation of abstract Base class
      class TestOptimizer < Base
        def step_name
          "testing"
        end

        def optimizer_name
          "Test"
        end

        def optimizer_type
          :test
        end

        protected

        def compile(_predictor, _train_examples, _val_examples, _signature)
          { optimized: nil, few_shot_examples: [] }
        end
      end

      setup do
        @metric = ->(example, prediction) { 1.0 }
        @optimizer = TestOptimizer.new(
          model: "ruby_llm/claude-sonnet-4-20250514",
          metric: @metric,
          mode: :light
        )
      end

      test "initializes with required attributes" do
        assert_equal "ruby_llm/claude-sonnet-4-20250514", @optimizer.model
        assert_equal @metric, @optimizer.metric
        assert_equal :light, @optimizer.mode
        assert_nil @optimizer.progress_callback
      end

      test "initializes with optional progress_callback" do
        callback = ->(args) { args }
        optimizer = TestOptimizer.new(
          model: "ruby_llm/claude-sonnet-4-20250514",
          metric: @metric,
          mode: :light,
          progress_callback: callback
        )
        assert_equal callback, optimizer.progress_callback
      end

      test "report_progress calls callback with correct arguments" do
        progress_updates = []
        optimizer = TestOptimizer.new(
          model: "ruby_llm/claude-sonnet-4-20250514",
          metric: @metric,
          mode: :light,
          progress_callback: ->(args) { progress_updates << args }
        )

        optimizer.send(:report_progress, step: "test_step", progress: 50)

        assert_equal 1, progress_updates.size
        assert_equal "test_step", progress_updates.first[:step]
        assert_equal 50, progress_updates.first[:progress]
      end

      test "report_progress includes optional examples_processed and total" do
        progress_updates = []
        optimizer = TestOptimizer.new(
          model: "ruby_llm/claude-sonnet-4-20250514",
          metric: @metric,
          mode: :light,
          progress_callback: ->(args) { progress_updates << args }
        )

        optimizer.send(:report_progress, step: "processing", progress: 60, examples_processed: 5, total: 10)

        assert_equal 5, progress_updates.first[:examples_processed]
        assert_equal 10, progress_updates.first[:total]
      end

      test "report_progress throttles updates less than 5% change" do
        progress_updates = []
        optimizer = TestOptimizer.new(
          model: "ruby_llm/claude-sonnet-4-20250514",
          metric: @metric,
          mode: :light,
          progress_callback: ->(args) { progress_updates << args }
        )

        optimizer.send(:report_progress, step: "step1", progress: 50)
        optimizer.send(:report_progress, step: "step2", progress: 52)  # Should be throttled
        optimizer.send(:report_progress, step: "step3", progress: 56)  # Should go through

        assert_equal 2, progress_updates.size
        assert_equal "step1", progress_updates[0][:step]
        assert_equal "step3", progress_updates[1][:step]
      end

      test "report_progress does nothing without callback" do
        # Should not raise - no callback configured
        assert_nil @optimizer.send(:report_progress, step: "test", progress: 50)
      end

      test "extract_instruction returns signature description when no optimized predictor" do
        signature = Class.new do
          def self.description
            "Test signature description"
          end
        end

        result = @optimizer.send(:extract_instruction, nil, signature)
        assert_equal "Test signature description", result
      end

      test "extract_instruction uses optimized instruction if available" do
        optimized = Object.new
        def optimized.instruction
          "Optimized instruction"
        end

        signature = Class.new do
          def self.description
            "Fallback description"
          end
        end

        result = @optimizer.send(:extract_instruction, optimized, signature)
        assert_equal "Optimized instruction", result
      end

      test "evaluate returns 0.0 for empty validation examples" do
        predictor = Object.new
        result = @optimizer.send(:evaluate, predictor, [])
        assert_equal 0.0, result
      end

      test "evaluate calculates correct score" do
        skip "ANTHROPIC_API_KEY not set" unless ENV["ANTHROPIC_API_KEY"]

        # Create a mock predictor that returns expected outputs
        predictor = Object.new
        def predictor.call(**inputs)
          Struct.new(:output).new(inputs[:expected])
        end

        examples = [
          { input: { expected: "yes" }, expected: { output: "yes" } },
          { input: { expected: "no" }, expected: { output: "no" } },
          { input: { expected: "maybe" }, expected: { output: "different" } }
        ]

        result = @optimizer.send(:evaluate, predictor, examples)
        assert_in_delta 0.666, result, 0.01  # 2/3 correct
      end

      test "create_lm creates DSPy LM with correct model" do
        skip "ANTHROPIC_API_KEY not set" unless ENV["ANTHROPIC_API_KEY"]

        lm = @optimizer.send(:create_lm)
        assert_instance_of DSPy::LM, lm
      end

      test "step_name raises NotImplementedError on base class" do
        base = Base.allocate
        assert_raises(NotImplementedError) { base.step_name }
      end

      test "optimizer_name raises NotImplementedError on base class" do
        base = Base.allocate
        assert_raises(NotImplementedError) { base.optimizer_name }
      end

      test "optimizer_type raises NotImplementedError on base class" do
        base = Base.allocate
        assert_raises(NotImplementedError) { base.optimizer_type }
      end

      test "compile raises NotImplementedError on base class" do
        base = Base.allocate
        assert_raises(NotImplementedError) do
          base.send(:compile, nil, [], [], nil)
        end
      end
    end
  end
end
