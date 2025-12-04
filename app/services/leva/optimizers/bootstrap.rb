# frozen_string_literal: true

module Leva
  module Optimizers
    # Bootstrap optimization strategy.
    #
    # Uses simple few-shot bootstrapping to find the best examples
    # that improve model performance. Fast and has no extra dependencies.
    #
    # @example
    #   optimizer = Leva::Optimizers::Bootstrap.new(
    #     model: "anthropic/claude-sonnet-4-20250514",
    #     metric: my_metric,
    #     mode: :medium
    #   )
    #   result = optimizer.optimize(splits, signature)
    class Bootstrap < Base
      MODES = {
        light: { trials: 5 },
        medium: { trials: 15 },
        heavy: { trials: 30 }
      }.freeze

      def step_name
        "bootstrapping"
      end

      def optimizer_name
        "Bootstrap"
      end

      def optimizer_type
        :bootstrap
      end

      protected

      def compile(predictor, train_examples, _val_examples, signature)
        best_examples = bootstrap_few_shot_examples(predictor, train_examples)
        instruction = generate_optimized_instruction(best_examples, signature)

        {
          optimized: nil,
          few_shot_examples: best_examples,
          instruction_override: instruction
        }
      end

      private

      # Bootstraps few-shot examples by evaluating which examples help the model most.
      def bootstrap_few_shot_examples(predictor, examples)
        max_examples = MODES[mode][:trials].clamp(3, 8)

        scored_examples = examples.each_with_index.map do |example, index|
          prediction = predictor.call(**example[:input])
          actual_output = prediction.output.to_s.strip.downcase
          expected_output = example.dig(:expected, :output).to_s.strip.downcase

          score = actual_output == expected_output ? 1.0 : 0.0

          # Progress: 30% + (index / total * 50%)
          progress = 30 + ((index + 1).to_f / examples.size * 50).to_i
          report_progress(
            step: step_name,
            progress: progress,
            examples_processed: index + 1,
            total: examples.size
          )

          { example: example, score: score }
        end

        scored_examples.sort_by { |e| -e[:score] }.take(max_examples).map { |e| e[:example] }
      end

      # Generates instruction based on output patterns.
      def generate_optimized_instruction(examples, signature)
        return signature.description if examples.empty?

        outputs = examples.map { |e| e.dig(:expected, :output) }.compact.uniq

        if outputs.size <= 5
          # Classification task
          "#{signature.description} Respond with one of: #{outputs.join(', ')}."
        else
          signature.description
        end
      end
    end
  end
end
