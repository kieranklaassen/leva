# frozen_string_literal: true

module Leva
  # Optimizes prompts using DSPy.rb optimizers.
  #
  # This service takes a dataset and uses optimization to find
  # optimal prompt instructions and few-shot examples.
  #
  # @example Optimize a prompt for a dataset
  #   optimizer = Leva::PromptOptimizer.new(dataset: dataset, mode: :medium)
  #   result = optimizer.optimize
  #   # => { system_prompt: "...", user_prompt: "...", metadata: {...} }
  #
  # @example With GEPA optimizer
  #   optimizer = Leva::PromptOptimizer.new(dataset: dataset, optimizer: :gepa, mode: :medium)
  #   result = optimizer.optimize
  class PromptOptimizer
    # Minimum number of examples required for optimization
    MINIMUM_EXAMPLES = 10

    # Available optimizers
    OPTIMIZERS = {
      bootstrap: {
        name: "Bootstrap",
        description: "Simple few-shot bootstrapping (fast, no extra dependencies)",
        gem: nil
      },
      gepa: {
        name: "GEPA",
        description: "Genetic-Pareto reflective prompt evolution (best quality)",
        gem: "dspy-gepa"
      },
      miprov2: {
        name: "MIPROv2",
        description: "Bayesian optimization with Gaussian Processes",
        gem: "dspy-miprov2"
      }
    }.freeze

    # Default optimizer
    DEFAULT_OPTIMIZER = :bootstrap

    # Optimization modes with their approximate durations
    MODES = {
      light: { description: "Fast optimization (~5 min)", trials: 5 },
      medium: { description: "Balanced optimization (~15 min)", trials: 15 },
      heavy: { description: "Thorough optimization (~30 min)", trials: 30 }
    }.freeze

    # Available models for optimization
    MODELS = {
      "anthropic/claude-sonnet-4-20250514" => { name: "Claude Sonnet 4", provider: "Anthropic" },
      "anthropic/claude-haiku-4-20250514" => { name: "Claude Haiku 4", provider: "Anthropic" },
      "openai/gpt-4o" => { name: "GPT-4o", provider: "OpenAI" },
      "openai/gpt-4o-mini" => { name: "GPT-4o Mini", provider: "OpenAI" },
      "gemini/gemini-2.0-flash" => { name: "Gemini 2.0 Flash", provider: "Google" }
    }.freeze

    # Default model if none specified
    DEFAULT_MODEL = "anthropic/claude-sonnet-4-20250514"

    # @return [Leva::Dataset] The dataset being optimized
    attr_reader :dataset

    # @return [Symbol] The optimization mode (:light, :medium, :heavy)
    attr_reader :mode

    # @return [String] The model to use for optimization
    attr_reader :model

    # @return [Symbol] The optimizer to use (:bootstrap, :gepa, :miprov2)
    attr_reader :optimizer

    # @param dataset [Leva::Dataset] The dataset to optimize for
    # @param metric [Proc, nil] Custom evaluation metric (default: exact string match)
    # @param mode [Symbol] Optimization intensity (:light, :medium, :heavy)
    # @param model [String, nil] The model to use (default: DEFAULT_MODEL)
    # @param optimizer [Symbol, String] The optimizer to use (default: :bootstrap)
    # @param progress_callback [Proc, nil] Callback for progress updates
    def initialize(dataset:, metric: nil, mode: :light, model: nil, optimizer: nil, progress_callback: nil)
      @dataset = dataset
      @metric = metric || default_metric
      @mode = mode.to_sym
      @model = model.presence || DEFAULT_MODEL
      @optimizer = (optimizer.presence || DEFAULT_OPTIMIZER).to_sym
      @progress_callback = progress_callback
      @last_progress = nil
    end

    # Runs the optimization process.
    #
    # @return [Hash] Hash containing :system_prompt, :user_prompt, and :metadata
    # @raise [Leva::InsufficientDataError] If dataset has too few records
    # @raise [Leva::DspyConfigurationError] If DSPy is not configured
    def optimize
      report_progress(step: "validating", progress: 0)
      validate_dataset!
      validate_dspy_configuration!
      validate_optimizer!

      report_progress(step: "splitting_data", progress: 10)
      splits = DatasetConverter.new(@dataset).split

      report_progress(step: "generating_signature", progress: 20)
      signature = SignatureGenerator.new(@dataset).generate

      case @optimizer
      when :gepa
        run_gepa_optimization(splits, signature)
      when :miprov2
        run_miprov2_optimization(splits, signature)
      else
        run_bootstrap_optimization(splits, signature)
      end
    end

    # Checks if the dataset is ready for optimization.
    #
    # @return [Boolean] True if the dataset can be optimized
    def can_optimize?
      @dataset.dataset_records.count >= MINIMUM_EXAMPLES
    end

    # Returns the number of additional records needed for optimization.
    #
    # @return [Integer] Number of records still needed (0 if ready)
    def records_needed
      [ MINIMUM_EXAMPLES - @dataset.dataset_records.count, 0 ].max
    end

    # Checks if a specific optimizer is available.
    #
    # @param optimizer_type [Symbol] The optimizer to check
    # @return [Boolean] True if the optimizer is available
    def self.optimizer_available?(optimizer_type)
      optimizer_type = optimizer_type.to_sym
      return true if optimizer_type == :bootstrap

      case optimizer_type
      when :gepa
        defined?(DSPy::Teleprompt::GEPA)
      when :miprov2
        defined?(DSPy::Teleprompt::MIPROv2)
      else
        false
      end
    end

    private

    # Reports progress to the callback if provided.
    # Throttles updates to only report when progress changes by 5% or more.
    #
    # @param step [String] Current step name
    # @param progress [Integer] Progress percentage (0-100)
    # @param examples_processed [Integer, nil] Number of examples processed
    # @param total [Integer, nil] Total examples to process
    # @return [void]
    def report_progress(step:, progress:, examples_processed: nil, total: nil)
      return unless @progress_callback

      # Skip if progress hasn't changed by at least 5%
      return if @last_progress && (progress - @last_progress).abs < 5

      @last_progress = progress
      @progress_callback.call(
        step: step,
        progress: progress,
        examples_processed: examples_processed,
        total: total
      )
    end

    # Validates that the selected optimizer is available.
    #
    # @raise [Leva::DspyConfigurationError] If optimizer is not available
    def validate_optimizer!
      return if @optimizer == :bootstrap
      return if self.class.optimizer_available?(@optimizer)

      gem_name = OPTIMIZERS.dig(@optimizer, :gem)
      raise DspyConfigurationError, <<~MSG.strip
        #{@optimizer.to_s.upcase} optimizer is not available. Install it:

          gem 'dspy'
          gem '#{gem_name}'

        Or set DSPY_WITH_#{@optimizer.to_s.upcase}=1 before requiring dspy.
      MSG
    end

    # Validates that DSPy is properly configured.
    #
    # @raise [Leva::DspyConfigurationError] If DSPy is not configured
    def validate_dspy_configuration!
      unless defined?(DSPy) && defined?(DSPy::Predict)
        raise DspyConfigurationError, "DSPy is not installed. Add 'dspy' gem to your Gemfile."
      end

      api_key = Leva.api_key_for_model(@model)
      unless api_key.present?
        provider = @model.to_s.split("/").first
        raise DspyConfigurationError, <<~MSG.strip
          API key not configured for #{provider}. Configure it:

            Leva.#{provider}_api_key = "your-api-key"

          Or set the environment variable: #{provider.upcase}_API_KEY
        MSG
      end
    end

    # Creates a local LM instance for the selected model.
    # This avoids global state pollution and makes the optimizer thread-safe.
    #
    # @return [DSPy::LM] A new LM instance
    def create_lm_instance
      api_key = Leva.api_key_for_model(@model)
      DSPy::LM.new(@model, api_key: api_key)
    end

    # Runs GEPA-based optimization.
    #
    # @param splits [Hash] The train/val/test splits
    # @param signature [Class] The generated signature class
    # @return [Hash] The optimization result
    def run_gepa_optimization(splits, signature)
      train_examples = splits[:train]
      val_examples = splits[:val]

      report_progress(step: "gepa_optimizing", progress: 30, examples_processed: 0, total: train_examples.size)

      # Create the base predictor with local LM instance
      lm = create_lm_instance
      predictor = DSPy::Predict.new(signature)
      predictor.config.lm = lm

      # Configure GEPA optimizer with the same LM instance
      gepa = DSPy::Teleprompt::GEPA.new(
        metric: @metric,
        reflection_lm: lm,
        auto: @mode.to_s
      )

      # Convert examples to DSPy format
      trainset = train_examples.map { |ex| DSPy::Example.new(**ex[:input].merge(output: ex.dig(:expected, :output))) }
      valset = val_examples.map { |ex| DSPy::Example.new(**ex[:input].merge(output: ex.dig(:expected, :output))) }

      report_progress(step: "gepa_compiling", progress: 50)

      # Run optimization
      optimized = gepa.compile(student: predictor, trainset: trainset, valset: valset)

      report_progress(step: "evaluating", progress: 85)

      # Extract optimized instruction
      optimized_instruction = extract_optimized_instruction(optimized, signature)
      score = evaluate_optimized_predictor(optimized, val_examples)

      report_progress(step: "building_result", progress: 95)

      build_optimizer_result(optimized_instruction, [], score, splits, :gepa)
    rescue StandardError => e
      Rails.logger.error "[Leva::PromptOptimizer] GEPA optimization failed: #{e.message}"
      Rails.logger.error e.backtrace.first(5).join("\n")
      raise OptimizationError, "GEPA optimization failed: #{e.message}"
    end

    # Runs MIPROv2-based optimization.
    #
    # @param splits [Hash] The train/val/test splits
    # @param signature [Class] The generated signature class
    # @return [Hash] The optimization result
    def run_miprov2_optimization(splits, signature)
      train_examples = splits[:train]
      val_examples = splits[:val]

      report_progress(step: "miprov2_optimizing", progress: 30, examples_processed: 0, total: train_examples.size)

      # Create the base predictor with local LM instance
      predictor = DSPy::Predict.new(signature)
      predictor.config.lm = create_lm_instance

      # Configure MIPROv2 optimizer
      mipro = DSPy::Teleprompt::MIPROv2.new(
        metric: @metric,
        auto: @mode.to_s
      )

      # Convert examples to DSPy format
      trainset = train_examples.map { |ex| DSPy::Example.new(**ex[:input].merge(output: ex.dig(:expected, :output))) }
      valset = val_examples.map { |ex| DSPy::Example.new(**ex[:input].merge(output: ex.dig(:expected, :output))) }

      report_progress(step: "miprov2_compiling", progress: 50)

      # Run optimization
      optimized = mipro.compile(student: predictor, trainset: trainset, valset: valset)

      report_progress(step: "evaluating", progress: 85)

      # Extract optimized instruction
      optimized_instruction = extract_optimized_instruction(optimized, signature)
      score = evaluate_optimized_predictor(optimized, val_examples)

      report_progress(step: "building_result", progress: 95)

      build_optimizer_result(optimized_instruction, [], score, splits, :miprov2)
    rescue StandardError => e
      Rails.logger.error "[Leva::PromptOptimizer] MIPROv2 optimization failed: #{e.message}"
      Rails.logger.error e.backtrace.first(5).join("\n")
      raise OptimizationError, "MIPROv2 optimization failed: #{e.message}"
    end

    # Runs simple bootstrap-based optimization (original implementation).
    #
    # @param splits [Hash] The train/val/test splits
    # @param signature [Class] The generated signature class
    # @return [Hash] The optimization result
    def run_bootstrap_optimization(splits, signature)
      train_examples = splits[:train]
      val_examples = splits[:val]

      report_progress(step: "bootstrapping", progress: 30, examples_processed: 0, total: train_examples.size)

      # Create predictor with the signature and local LM instance
      predictor = DSPy::Predict.new(signature)
      predictor.config.lm = create_lm_instance

      # Bootstrap: run predictions to find best few-shot examples
      best_examples = bootstrap_few_shot_examples(predictor, train_examples)

      report_progress(step: "evaluating", progress: 85)

      # Evaluate on validation set
      score = evaluate_with_few_shot(predictor, val_examples, best_examples)

      report_progress(step: "building_result", progress: 95)

      # Generate optimized instruction based on best examples
      optimized_instruction = generate_optimized_instruction(best_examples, signature)

      build_optimizer_result(optimized_instruction, best_examples, score, splits, :bootstrap)
    rescue StandardError => e
      Rails.logger.error "[Leva::PromptOptimizer] Bootstrap optimization failed: #{e.message}"
      Rails.logger.error e.backtrace.first(5).join("\n")
      raise OptimizationError, "Bootstrap optimization failed: #{e.message}"
    end

    # Extracts the optimized instruction from an optimized predictor.
    #
    # @param optimized [Object] The optimized predictor
    # @param signature [Class] The signature class
    # @return [String] The optimized instruction
    def extract_optimized_instruction(optimized, signature)
      # Try to get instruction from optimized predictor
      if optimized.respond_to?(:instruction)
        optimized.instruction
      elsif optimized.respond_to?(:signature) && optimized.signature.respond_to?(:instructions)
        optimized.signature.instructions
      else
        signature.description
      end
    end

    # Evaluates an optimized predictor on validation examples.
    #
    # @param optimized [Object] The optimized predictor
    # @param val_examples [Array<Hash>] Validation examples
    # @return [Float] Accuracy score
    def evaluate_optimized_predictor(optimized, val_examples)
      return 0.0 if val_examples.empty?

      correct = val_examples.count do |example|
        prediction = optimized.call(**example[:input])
        actual = prediction.output.to_s.strip.downcase
        expected = example.dig(:expected, :output).to_s.strip.downcase
        actual == expected
      end

      correct.to_f / val_examples.size
    end

    # Bootstraps few-shot examples by evaluating which examples help the model most.
    #
    # @param predictor [DSPy::Predict] The predictor to use
    # @param examples [Array<Hash>] Training examples
    # @return [Array<Hash>] Best few-shot examples
    def bootstrap_few_shot_examples(predictor, examples)
      max_examples = MODES[@mode][:trials].clamp(3, 8)

      # Score each example by running prediction and checking accuracy
      scored_examples = examples.each_with_index.map do |example, index|
        prediction = predictor.call(**example[:input])
        actual_output = prediction.output.to_s.strip.downcase
        expected_output = example.dig(:expected, :output).to_s.strip.downcase

        score = actual_output == expected_output ? 1.0 : 0.0

        # Report progress: 30% + (index / total * 50%)
        progress = 30 + ((index + 1).to_f / examples.size * 50).to_i
        report_progress(
          step: "bootstrapping",
          progress: progress,
          examples_processed: index + 1,
          total: examples.size
        )

        { example: example, score: score, prediction: prediction.output }
      end

      # Select diverse, high-quality examples
      scored_examples.sort_by { |e| -e[:score] }.take(max_examples).map { |e| e[:example] }
    end

    # Evaluates predictor with few-shot examples on validation set.
    #
    # @param predictor [DSPy::Predict] The predictor
    # @param val_examples [Array<Hash>] Validation examples
    # @param few_shot_examples [Array<Hash>] Few-shot examples to use
    # @return [Float] Accuracy score
    def evaluate_with_few_shot(predictor, val_examples, few_shot_examples)
      return 0.0 if val_examples.empty?

      correct = val_examples.count do |example|
        prediction = predictor.call(**example[:input])
        actual = prediction.output.to_s.strip.downcase
        expected = example.dig(:expected, :output).to_s.strip.downcase
        actual == expected
      end

      correct.to_f / val_examples.size
    end

    # Generates an optimized instruction based on the task pattern.
    #
    # @param examples [Array<Hash>] The best few-shot examples
    # @param signature [Class] The signature class
    # @return [String] Optimized instruction
    def generate_optimized_instruction(examples, signature)
      return signature.description if examples.empty?

      # Analyze the output patterns
      outputs = examples.map { |e| e.dig(:expected, :output) }.compact.uniq

      if outputs.size <= 5
        # Classification task - list the categories
        "#{signature.description} Respond with one of: #{outputs.join(', ')}."
      else
        # Generation task - keep original description
        signature.description
      end
    end

    # Builds the result hash from optimization.
    #
    # @param instruction [String] The optimized instruction
    # @param few_shot_examples [Array<Hash>] The selected few-shot examples
    # @param score [Float] The validation score
    # @param splits [Hash] The data splits
    # @param optimizer_used [Symbol] The optimizer that was used
    # @return [Hash] The formatted result
    def build_optimizer_result(instruction, few_shot_examples, score, splits, optimizer_used)
      sample_record = @dataset.dataset_records.first&.recordable
      input_fields = sample_record&.to_llm_context&.keys || []

      formatted_examples = few_shot_examples.map do |ex|
        { input: ex[:input], output: ex.dig(:expected, :output) }
      end

      {
        system_prompt: instruction,
        user_prompt: build_user_prompt_template(input_fields),
        metadata: {
          optimization: {
            score: score,
            mode: @mode.to_s,
            optimizer: optimizer_used.to_s,
            model: @model,
            few_shot_examples: formatted_examples,
            optimized_at: Time.current.iso8601,
            dataset_size: @dataset.dataset_records.count,
            train_size: splits[:train].size,
            val_size: splits[:val].size,
            test_size: splits[:test].size
          }
        }
      }
    end

    # Validates that the dataset has enough records.
    #
    # @raise [Leva::InsufficientDataError] If dataset has too few records
    def validate_dataset!
      count = @dataset.dataset_records.count
      return if count >= MINIMUM_EXAMPLES

      raise InsufficientDataError,
        "Dataset needs at least #{MINIMUM_EXAMPLES} records for optimization, has #{count}"
    end

    # Returns the default evaluation metric (case-insensitive exact match).
    #
    # @return [Proc] The default metric function
    def default_metric
      lambda do |example, prediction|
        expected = example.dig(:expected, :output).to_s.strip.downcase
        actual = prediction.to_s.strip.downcase
        expected == actual ? 1.0 : 0.0
      end
    end

    # Builds the user prompt template with Liquid placeholders.
    #
    # @param input_fields [Array<Symbol>] The input field names
    # @return [String] The user prompt template
    def build_user_prompt_template(input_fields)
      input_fields.map { |field| "{{ #{field} }}" }.join("\n\n")
    end
  end
end
