# frozen_string_literal: true

module Leva
  # Configuration class for DSPy.rb integration.
  #
  # @example Configure DSPy for Leva
  #   Leva::DspyConfig.configure do |config|
  #     config.default_lm = DSPy::LM.new('openai/gpt-4o-mini', api_key: ENV['OPENAI_API_KEY'])
  #   end
  class DspyConfig
    class << self
      # @return [DSPy::LM, nil] The default language model for task execution
      attr_accessor :default_lm

      # @return [DSPy::LM, nil] The language model for optimization (defaults to default_lm)
      attr_accessor :optimization_lm

      # Configures DSPy settings for Leva.
      #
      # @yield [Leva::DspyConfig] The configuration object
      # @return [void]
      def configure
        yield self
      end

      # Returns the language model to use for optimization.
      # Falls back to default_lm if optimization_lm is not set.
      #
      # @return [DSPy::LM, nil] The language model for optimization
      def lm_for_optimization
        optimization_lm || default_lm
      end
    end
  end
end
