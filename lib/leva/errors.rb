# frozen_string_literal: true

module Leva
  # Base error class for all Leva errors
  class Error < StandardError; end

  # Raised when a runner encounters an error during execution
  class RunnerError < Error; end
end
