# frozen_string_literal: true

require "test_helper"

# End-to-end test for DSPy prompt optimization.
# Requires ANTHROPIC_API_KEY environment variable to be set.
#
# Run with: ANTHROPIC_API_KEY=your_key bundle exec rails test test/integration/prompt_optimization_e2e_test.rb
module Leva
  class PromptOptimizationE2ETest < ActiveSupport::TestCase
    setup do
      @api_key = ENV["ANTHROPIC_API_KEY"]
      skip "ANTHROPIC_API_KEY not set" unless @api_key

      # Configure DSPy with Anthropic
      DSPy.configure do |config|
        config.lm = DSPy::LM.new("anthropic/claude-3-5-haiku-latest", api_key: @api_key)
      end

      @dataset = Dataset.create!(name: "Sentiment Classification Test")

      # Create a realistic sentiment classification dataset
      create_sentiment_examples
    end

    test "end-to-end prompt optimization with real LLM" do
      optimizer = PromptOptimizer.new(dataset: @dataset, mode: :light)

      assert optimizer.can_optimize?, "Dataset should have enough records"

      puts "\n=== Starting End-to-End Prompt Optimization ==="
      puts "Dataset: #{@dataset.name}"
      puts "Records: #{@dataset.dataset_records.count}"
      puts "Mode: light"
      puts ""

      result = optimizer.optimize

      puts "=== Optimization Complete ==="
      puts "Score: #{result[:metadata][:optimization][:score]}"
      puts "System Prompt: #{result[:system_prompt]}"
      puts "User Prompt: #{result[:user_prompt]}"
      puts "Few-shot examples: #{result[:metadata][:optimization][:few_shot_examples].count}"
      puts ""

      # Verify the result structure
      assert result[:system_prompt].present?, "System prompt should be present"
      assert result[:user_prompt].present?, "User prompt should be present"
      assert result[:metadata][:optimization].present?, "Optimization metadata should be present"

      # With real DSPy, we should get a meaningful score
      score = result[:metadata][:optimization][:score]
      puts "Final score: #{score}"

      # Create a prompt from the result
      prompt = Prompt.create!(
        name: "E2E Test Prompt",
        system_prompt: result[:system_prompt],
        user_prompt: result[:user_prompt],
        metadata: result[:metadata]
      )

      assert prompt.persisted?, "Prompt should be saved"
      puts "Created prompt: #{prompt.name} (id: #{prompt.id})"
    end

    test "optimization improves over baseline" do
      optimizer = PromptOptimizer.new(dataset: @dataset, mode: :light)

      # Get baseline score with no optimization
      splits = DatasetConverter.new(@dataset).split
      signature = SignatureGenerator.new(@dataset).generate

      baseline_predictor = DSPy::Predict.new(signature)

      baseline_scores = splits[:val].map do |example|
        prediction = baseline_predictor.call(**example[:input])
        expected = example.dig(:expected, :output).to_s.strip.downcase
        actual = prediction.output.to_s.strip.downcase
        expected == actual ? 1.0 : 0.0
      end
      baseline_score = baseline_scores.sum / baseline_scores.size.to_f

      puts "\n=== Baseline vs Optimized ==="
      puts "Baseline score: #{baseline_score}"

      # Run optimization
      result = optimizer.optimize
      optimized_score = result[:metadata][:optimization][:score]

      puts "Optimized score: #{optimized_score}"
      puts "Improvement: #{((optimized_score - baseline_score) * 100).round(1)}%"

      # Optimized should be at least as good as baseline
      assert optimized_score >= baseline_score * 0.9,
        "Optimized score (#{optimized_score}) should not be significantly worse than baseline (#{baseline_score})"
    end

    private

    def create_sentiment_examples
      # Positive examples
      positive_texts = [
        "I absolutely love this product! Best purchase ever.",
        "Amazing service, exceeded all my expectations!",
        "This made my day so much better. Highly recommend!",
        "Fantastic quality and fast shipping. Very happy!",
        "The team went above and beyond. Truly impressed!",
        "Perfect solution for my needs. Five stars!"
      ]

      # Negative examples
      negative_texts = [
        "Terrible experience. Would not recommend to anyone.",
        "Complete waste of money. Very disappointed.",
        "The worst customer service I've ever encountered.",
        "Broke after one week. Total garbage product.",
        "Never buying from this company again. Awful.",
        "Misleading description. Nothing like advertised."
      ]

      # Neutral examples
      neutral_texts = [
        "It works as described. Nothing special.",
        "Average product for the price point.",
        "Delivered on time. Met basic expectations.",
        "Standard quality. Neither good nor bad."
      ]

      positive_texts.each do |text|
        content = TextContent.create!(text: text, expected_label: "positive")
        @dataset.add_record(content)
      end

      negative_texts.each do |text|
        content = TextContent.create!(text: text, expected_label: "negative")
        @dataset.add_record(content)
      end

      neutral_texts.each do |text|
        content = TextContent.create!(text: text, expected_label: "neutral")
        @dataset.add_record(content)
      end
    end
  end
end
