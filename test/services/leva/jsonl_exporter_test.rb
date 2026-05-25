# frozen_string_literal: true

require "test_helper"

module Leva
  class JsonlExporterTest < ActiveSupport::TestCase
    setup do
      @dataset = Leva::Dataset.create!(name: "Sentiment")
      10.times do |i|
        @dataset.add_record(
          TextContent.create!(text: "Text #{i}", expected_label: %w[positive negative neutral][i % 3])
        )
      end
    end

    test "produces a user + assistant turn when no system prompt is given" do
      example = JsonlExporter.new(@dataset, seed: 1).examples.first
      assert_equal %w[user assistant], example[:messages].map { |m| m[:role] }
    end

    test "prepends a system turn when a system prompt is given" do
      example = JsonlExporter.new(@dataset, system_prompt: "Classify sentiment.", seed: 1).examples.first
      assert_equal %w[system user assistant], example[:messages].map { |m| m[:role] }
      assert_equal "Classify sentiment.", example[:messages].first[:content]
    end

    test "places ground_truth in the assistant turn" do
      example = JsonlExporter.new(@dataset, seed: 1).examples.first
      assistant = example[:messages].find { |m| m[:role] == "assistant" }
      assert_includes %w[positive negative neutral], assistant[:content]
    end

    test "renders the user turn through a Liquid template when provided" do
      example = JsonlExporter.new(@dataset, user_template: "Text: {{ text }}", seed: 1).examples.first
      user = example[:messages].find { |m| m[:role] == "user" }
      assert_match(/\AText: Text \d+\z/, user[:content])
    end

    test "renders nil context values as empty strings" do
      dataset = Leva::Dataset.create!(name: "Nulls")
      5.times { dataset.add_record(TextContent.create!(text: nil, expected_label: nil)) }
      example = JsonlExporter.new(dataset, seed: 1).examples.first
      user = example[:messages].find { |m| m[:role] == "user" }
      assistant = example[:messages].find { |m| m[:role] == "assistant" }
      assert_match(/text: (\n|\z)/, user[:content])
      assert_equal "", assistant[:content]
    end

    test "train slice honors DatasetConverter#split ratio with a fixed seed" do
      # 10 records, default train_ratio 0.6 -> 6 train examples (deterministic size)
      assert_equal 6, JsonlExporter.new(@dataset, seed: 1).examples.size
    end

    test "to_jsonl emits valid newline-delimited JSON" do
      lines = JsonlExporter.new(@dataset, seed: 1).to_jsonl.split("\n")
      assert_equal 6, lines.size
      parsed = JSON.parse(lines.first)
      assert parsed["messages"].is_a?(Array)
    end
  end
end
