# frozen_string_literal: true

module Leva
  # Base error class for all Leva errors
  class Error < StandardError; end

  # Raised when a dataset has insufficient records for optimization
  class InsufficientDataError < Error; end

  # Raised when DSPy is not properly configured
  class DspyConfigurationError < Error; end

  # Raised when optimization fails
  class OptimizationError < Error; end

  # Raised when a runner encounters an error during execution
  class RunnerError < Error; end

  # Raised when Leva is misconfigured (e.g., an incompatible RubyLLM version)
  class ConfigurationError < Error; end

  # Raised when a fine-tune job fails
  class FineTuneError < Error; end
end
