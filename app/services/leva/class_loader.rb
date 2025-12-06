# frozen_string_literal: true

module Leva
  # Service for loading evaluator and runner classes from the application.
  #
  # This service dynamically loads classes from the app/evals and app/runners
  # directories that inherit from their respective base classes.
  class ClassLoader
    # Loads all evaluator classes that inherit from Leva::BaseEval
    #
    # @return [Array<Class>] An array of evaluator classes
    def self.evaluators
      load_classes_from_directory("app/evals", Leva::BaseEval)
    end

    # Loads all runner classes that inherit from Leva::BaseRun
    #
    # @return [Array<Class>] An array of runner classes
    def self.runners
      load_classes_from_directory("app/runners", Leva::BaseRun)
    end

    # Loads classes from a specified directory that inherit from a given base class
    #
    # @param directory [String] The directory path to load classes from
    # @param base_class [Class] The base class that loaded classes should inherit from
    # @return [Array<Class>] An array of loaded classes
    def self.load_classes_from_directory(directory, base_class)
      classes = Dir[Rails.root.join(directory, "*.rb")].map do |file|
        File.basename(file, ".rb").camelize.constantize
      end.select { |klass| klass < base_class }
      classes.empty? ? [] : classes
    end

    private_class_method :load_classes_from_directory
  end
end
