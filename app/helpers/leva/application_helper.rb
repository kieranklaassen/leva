module Leva
  module ApplicationHelper
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

    # Returns CSS classes for navigation links with active state
    #
    # @param path [String] The path to check against the current request path
    # @return [String] CSS classes for the navigation link
    def nav_link_class(path)
      base = "px-3 py-2 text-sm font-medium transition-colors duration-150"
      active = "bg-amber-600 text-neutral-950 rounded-md"
      inactive = "text-neutral-300 hover:bg-neutral-800 hover:text-white rounded-md"

      request.path.start_with?(path) ? "#{base} #{active}" : "#{base} #{inactive}"
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
