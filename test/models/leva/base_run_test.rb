# frozen_string_literal: true

require "test_helper"

module Leva
  class BaseRunTest < ActiveSupport::TestCase
    class TestRun < Leva::BaseRun
      def execute(record)
        "test result"
      end
    end

    class TestRunWithContext < Leva::BaseRun
      def execute(record)
        "test result"
      end

      def to_llm_context(record)
        {
          similar_texts_count: record.class.where("text LIKE ?", "%#{record.text.split.first}%").count
        }
      end
    end

    setup do
      @text_content = TextContent.create!(text: "Hello world", expected_label: "positive")
      @dataset = Leva::Dataset.create!(name: "Test Dataset")
      @dataset_record = @dataset.dataset_records.create!(recordable: @text_content)
      @prompt = Leva::Prompt.create!(
        name: "Test Prompt",
        system_prompt: "You are a helpful assistant",
        user_prompt: "Analyze this text: {{ text }}. Similar texts count: {{ similar_texts_count }}"
      )
    end

    test "base run has default empty to_llm_context" do
      run = TestRun.new
      assert_equal({}, run.to_llm_context(@text_content))
    end

    test "subclass can override to_llm_context" do
      run = TestRunWithContext.new
      context = run.to_llm_context(@text_content)

      assert context.key?(:similar_texts_count)
      assert_kind_of Integer, context[:similar_texts_count]
    end

    test "execute_and_store merges record and runner contexts" do
      run = TestRunWithContext.new

      # Create another text to ensure similar_texts_count > 0
      TextContent.create!(text: "Hello there", expected_label: "neutral")

      runner_result = run.execute_and_store(nil, @dataset_record, @prompt)

      assert runner_result.persisted?
      assert_equal "test result", runner_result.prediction
      assert_equal TestRunWithContext.name, runner_result.runner_class
    end

    test "merged context is available during execution" do
      # This test verifies the context is properly merged by checking
      # that the prompt would render with both contexts
      run = TestRunWithContext.new

      record_context = @text_content.to_llm_context
      runner_context = run.to_llm_context(@text_content)
      merged_context = record_context.merge(runner_context)

      # Verify both contexts are present
      assert merged_context.key?(:text)
      assert merged_context.key?(:expected_label)
      assert merged_context.key?(:similar_texts_count)

      # Verify the prompt can be rendered with merged context
      rendered = Liquid::Template.parse(@prompt.user_prompt).render(merged_context.stringify_keys)
      assert_match(/Hello world/, rendered)
      assert_match(/Similar texts count: \d+/, rendered)
    end

    test "merged_llm_context provides combined record and runner context" do
      captured_context = nil

      # Use a named test run class
      test_run = TestRunWithContext.new

      # Monkey patch to capture context
      test_run.define_singleton_method(:execute) do |record|
        captured_context = merged_llm_context
        "test result"
      end

      test_run.define_singleton_method(:to_llm_context) do |record|
        { custom_field: "runner_value", similar_texts_count: 5 }
      end

      test_run.execute_and_store(nil, @dataset_record, @prompt)

      # Verify the context was properly merged
      assert_not_nil captured_context
      assert_equal "Hello world", captured_context[:text]
      assert_equal "positive", captured_context[:expected_label]
      assert_equal "runner_value", captured_context[:custom_field]
      assert_equal 5, captured_context[:similar_texts_count]
    end
  end
end
