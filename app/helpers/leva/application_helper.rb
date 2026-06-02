module Leva
  module ApplicationHelper
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

    # Returns available chat models from RubyLLM.
    #
    # @return [Array<RubyLLM::Model>] All available chat models
    def available_models
      @available_models ||= Rails.cache.fetch("leva/available_models", expires_in: 5.minutes) do
        RubyLLM.models.chat_models
      end
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
