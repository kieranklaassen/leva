module Leva
  module ApplicationHelper
    # Returns the status of an optimization step.
    #
    # @param optimization_run [Leva::OptimizationRun] The optimization run
    # @param step_key [String] The step key to check
    # @return [String] 'completed', 'active', or 'pending'
    def optimization_step_status(optimization_run, step_key)
      steps = Leva::OptimizationRun::STEPS.keys
      current_index = steps.index(optimization_run.current_step) || -1
      step_index = steps.index(step_key)

      return "pending" if step_index.nil?

      if optimization_run.completed? || step_index < current_index
        "completed"
      elsif step_index == current_index
        "active"
      else
        "pending"
      end
    end

    # Loads all evaluator classes that inherit from Leva::BaseEval
    #
    # @return [Array<Class>] An array of evaluator classes
    def load_evaluators
      load_classes_from_directory("app/evals", Leva::BaseEval) || []
    end

    # Loads all runner classes that inherit from Leva::BaseRun
    #
    # @return [Array<Class>] An array of runner classes
    def load_runners
      load_classes_from_directory("app/runners", Leva::BaseRun) || []
    end

    # Returns the CSS class for a score value.
    #
    # @param score [Float, nil] The score value (0.0 - 1.0)
    # @return [String] The CSS class for the score
    def score_class(score)
      return "" if score.nil?

      case score
      when 0.9..1.0 then "score-excellent"
      when 0.7...0.9 then "score-good"
      when 0.5...0.7 then "score-fair"
      when 0.3...0.5 then "score-poor"
      else "score-bad"
      end
    end

    # Returns the display name for a model.
    #
    # Uses RubyLLM to find the model and get its display name,
    # falling back to extracting the name from the model ID.
    #
    # @param model_id [String] The model ID
    # @return [String] The display name for the model
    def model_display_name(model_id)
      return "—" if model_id.blank?

      model = Leva::PromptOptimizer.find_model(model_id)
      model&.name || model_id.split("/").last
    end

    # Loads predefined prompts from markdown files
    #
    # @return [Array<Array<String, String>>] An array of prompt name and content pairs
    def load_predefined_prompts
      prompts = Dir.glob(Rails.root.join("app", "prompts", "*.md")).map do |file|
        name = File.basename(file, ".md").titleize
        content = File.read(file)
        [ name, content ]
      end
      prompts
    end

    private

    # Loads classes from a specified directory that inherit from a given base class
    #
    # @param directory [String] The directory path to load classes from
    # @param base_class [Class] The base class that loaded classes should inherit from
    # @return [Array<Class>] An array of loaded classes
    def load_classes_from_directory(directory, base_class)
      classes = Dir[Rails.root.join(directory, "*.rb")].map do |file|
        File.basename(file, ".rb").camelize.constantize
      end.select { |klass| klass < base_class }
      classes.empty? ? [] : classes
    end
  end
end
