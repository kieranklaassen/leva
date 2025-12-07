# frozen_string_literal: true

module Leva
  module Optimizers
    # Base class for optimization strategies.
    #
    # Each optimizer implements a different approach to finding optimal
    # prompt instructions and few-shot examples.
    #
    # @abstract Subclass and override {#compile} to implement a strategy
    class Base
      # @return [String] The model identifier
      attr_reader :model

      # @return [Proc] The evaluation metric
      attr_reader :metric

      # @return [Proc, nil] Progress callback
      attr_reader :progress_callback

      # @return [Symbol] The optimization mode
      attr_reader :mode

      # @param model [String] The model to use for optimization
      # @param metric [Proc] The evaluation metric
      # @param mode [Symbol] Optimization intensity (:light, :medium, :heavy)
      # @param progress_callback [Proc, nil] Callback for progress updates
      def initialize(model:, metric:, mode:, progress_callback: nil)
        @model = model
        @metric = metric
        @mode = mode
        @progress_callback = progress_callback
        @last_progress = nil
      end

      # Runs the optimization and returns results.
      #
      # @param splits [Hash] The train/val/test splits
      # @param signature [Class] The generated DSPy signature class
      # @return [Hash] Hash with :instruction, :few_shot_examples, :score
      # @raise [Leva::OptimizationError] If optimization fails
      def optimize(splits, signature)
        train_examples = splits[:train]
        val_examples = splits[:val]

        report_progress(step: step_name, progress: 30, examples_processed: 0, total: train_examples.size)

        predictor = DSPy::Predict.new(signature)
        predictor.config.lm = create_lm

        result = compile(predictor, train_examples, val_examples, signature)

        report_progress(step: "evaluating", progress: 85)

        instruction = result[:instruction_override] || extract_instruction(result[:optimized], signature)
        score = evaluate(result[:optimized] || predictor, val_examples)

        report_progress(step: "building_result", progress: 95)

        {
          instruction: instruction,
          few_shot_examples: result[:few_shot_examples] || [],
          score: score
        }
      rescue StandardError => e
        Rails.logger.error "[Leva::Optimizers::#{self.class.name.demodulize}] Optimization failed: #{e.message}"
        Rails.logger.error e.backtrace.first(5).join("\n")
        raise Leva::OptimizationError, "#{optimizer_name} optimization failed: #{e.message}"
      end

      # The name used in progress reporting.
      # @return [String]
      def step_name
        raise NotImplementedError, "Subclasses must implement #step_name"
      end

      # Human-readable optimizer name.
      # @return [String]
      def optimizer_name
        raise NotImplementedError, "Subclasses must implement #optimizer_name"
      end

      # @return [Symbol] The optimizer type symbol
      def optimizer_type
        raise NotImplementedError, "Subclasses must implement #optimizer_type"
      end

      protected

      # Performs the actual optimization logic.
      #
      # @param predictor [DSPy::Predict] The base predictor
      # @param train_examples [Array<Hash>] Training examples
      # @param val_examples [Array<Hash>] Validation examples
      # @param signature [Class] The signature class
      # @return [Hash] Hash with :optimized (predictor), :few_shot_examples, :instruction_override (optional)
      def compile(predictor, train_examples, val_examples, signature)
        raise NotImplementedError, "Subclasses must implement #compile"
      end

      # Converts examples to DSPy::Example format.
      #
      # @param examples [Array<Hash>] Examples with :input and :expected keys
      # @param signature [Class] The DSPy signature class
      # @return [Array<DSPy::Example>]
      def to_dspy_examples(examples, signature)
        examples.map do |ex|
          DSPy::Example.new(
            signature_class: signature,
            input: ex[:input],
            expected: ex[:expected]
          )
        end
      end

      # Creates an LM instance for this optimizer.
      # Prepends ruby_llm/ prefix for DSPy adapter.
      # RubyLLM handles API keys from its configuration.
      #
      # @return [DSPy::LM]
      def create_lm
        DSPy::LM.new("ruby_llm/#{model}")
      end

      # Reports progress to the callback if provided.
      # Throttles updates to only report when progress changes by 5% or more.
      def report_progress(step:, progress:, examples_processed: nil, total: nil)
        return unless progress_callback

        # Skip if progress hasn't changed by at least 5%
        return if @last_progress && (progress - @last_progress).abs < 5

        @last_progress = progress
        progress_callback.call(
          step: step,
          progress: progress,
          examples_processed: examples_processed,
          total: total
        )
      end

      private

      # Extracts instruction from an optimized predictor.
      def extract_instruction(optimized, signature)
        return signature.description unless optimized

        if optimized.respond_to?(:instruction)
          optimized.instruction
        elsif optimized.respond_to?(:signature) && optimized.signature.respond_to?(:instructions)
          optimized.signature.instructions
        else
          signature.description
        end
      end

      # Evaluates predictor on validation examples.
      # Handles both Hash examples and DSPy::Example objects.
      def evaluate(predictor, val_examples)
        return 0.0 if val_examples.empty?

        correct = val_examples.count do |example|
          # Handle both Hash and DSPy::Example
          if example.is_a?(Hash)
            input = example[:input]
            expected_output = example.dig(:expected, :output)
          else
            # DSPy::Example has input_values/expected_values methods
            input = example.input_values
            expected_output = example.expected_values[:output]
          end

          prediction = predictor.call(**input)
          actual = prediction.output.to_s.strip.downcase
          expected = expected_output.to_s.strip.downcase
          actual == expected
        end

        correct.to_f / val_examples.size
      end
    end
  end
end
