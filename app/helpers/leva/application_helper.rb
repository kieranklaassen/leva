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
      Leva::ClassLoader.evaluators
    end

    # Loads all runner classes that inherit from Leva::BaseRun
    #
    # @return [Array<Class>] An array of runner classes
    def load_runners
      Leva::ClassLoader.runners
    end

    # Returns the CSS class for a score value.
    #
    # @param score [Float, nil] The score value (0.0 - 1.0)
    # @return [String] The CSS class for the score
    def score_class(score)
      return "" if score.nil?

      case score
      when 0...0.2 then "score-bad"
      when 0.2...0.4 then "score-poor"
      when 0.4...0.6 then "score-fair"
      when 0.6...0.8 then "score-good"
      else "score-excellent"
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

      @models_cache ||= Leva::PromptOptimizer.available_models.index_by(&:id)
      @models_cache[model_id]&.name || model_id.split("/").last
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
  end
end
