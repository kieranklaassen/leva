# frozen_string_literal: true

require "test_helper"

module Leva
  class DatasetConverterTest < ActiveSupport::TestCase
    setup do
      @dataset = Leva::Dataset.create!(name: "Test Dataset")

      # Create multiple text contents for testing
      10.times do |i|
        text_content = TextContent.create!(
          text: "Test text #{i}",
          expected_label: %w[positive negative neutral][i % 3]
        )
        @dataset.add_record(text_content)
      end

      @converter = DatasetConverter.new(@dataset)
    end

    test "to_dspy_examples converts all records" do
      examples = @converter.to_dspy_examples

      assert_equal 10, examples.size
    end

    test "to_dspy_examples returns correct structure" do
      examples = @converter.to_dspy_examples

      example = examples.first
      assert example.key?(:input)
      assert example.key?(:expected)
      assert example[:expected].key?(:output)
    end

    test "to_dspy_examples includes recordable context as input" do
      examples = @converter.to_dspy_examples

      example = examples.first
      assert example[:input].key?(:text)
    end

    test "to_dspy_examples includes ground_truth as expected output" do
      examples = @converter.to_dspy_examples

      example = examples.first
      assert_includes %w[positive negative neutral], example[:expected][:output]
    end

    test "split returns train, val, and test sets" do
      splits = @converter.split

      assert splits.key?(:train)
      assert splits.key?(:val)
      assert splits.key?(:test)
    end

    test "split uses correct ratios by default" do
      splits = @converter.split

      # With 10 examples and 60/20/20 split
      assert_equal 6, splits[:train].size
      assert_equal 2, splits[:val].size
      assert_equal 2, splits[:test].size
    end

    test "split with custom ratios" do
      splits = @converter.split(train_ratio: 0.5, val_ratio: 0.3)

      assert_equal 5, splits[:train].size
      assert_equal 3, splits[:val].size
      assert_equal 2, splits[:test].size
    end

    test "split with seed is reproducible" do
      splits1 = @converter.split(seed: 42)
      splits2 = @converter.split(seed: 42)

      assert_equal splits1[:train], splits2[:train]
      assert_equal splits1[:val], splits2[:val]
      assert_equal splits1[:test], splits2[:test]
    end

    test "valid_record_count returns count of valid records" do
      count = @converter.valid_record_count

      assert_equal 10, count
    end

    test "handles empty dataset" do
      empty_dataset = Leva::Dataset.create!(name: "Empty Dataset")
      converter = DatasetConverter.new(empty_dataset)

      assert_equal [], converter.to_dspy_examples
      assert_equal 0, converter.valid_record_count
    end
  end
end
