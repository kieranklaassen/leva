module Leva
  module ApplicationHelper
    # Loads all evaluator classes that inherit from Leva::BaseEval
    #
    # @return [Array<Class>] An array of evaluator classes
    def load_evaluators
      load_classes_from_directory('app/evals', Leva::BaseEval) || []
    end

    # Loads all runner classes that inherit from Leva::BaseRun
    #
    # @return [Array<Class>] An array of runner classes
    def load_runners
      load_classes_from_directory('app/runners', Leva::BaseRun) || []
    end

    # Loads predefined prompts from markdown files
    #
    # @return [Array<Array<String, String>>] An array of prompt name and content pairs
    def load_predefined_prompts
      prompts = Dir.glob(Rails.root.join('app', 'prompts', '*.md')).map do |file|
        name = File.basename(file, '.md').titleize
        content = File.read(file)
        [name, content]
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
      classes = Dir[Rails.root.join(directory, '*.rb')].map do |file|
        File.basename(file, '.rb').camelize.constantize
      end.select { |klass| klass < base_class }
      classes.empty? ? [] : classes
    end
  end
end
