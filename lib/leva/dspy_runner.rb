# frozen_string_literal: true

module Leva
  # Base class for runners that use DSPy.rb for LLM execution.
  #
  # DspyRunner extends BaseRun to provide integration with DSPy.rb,
  # automatically loading optimized instructions and few-shot examples
  # from the prompt's metadata.
  #
  # @example Create a custom DSPy runner
  #   class SentimentRunner < Leva::DspyRunner
  #     # DspyRunner handles the execution automatically
  #     # using the optimized prompt from the experiment
  #   end
  #
  # @example Override for custom behavior
  #   class CustomRunner < Leva::DspyRunner
  #     def execute(record)
  #       context = merged_llm_context
  #       # Custom execution logic here
  #     end
  #   end
  class DspyRunner < BaseRun
    # Executes the DSPy predictor on the given record.
    #
    # @param record [Object] The recordable object to process
    # @return [String] The model's prediction
    def execute(record)
      context = merged_llm_context

      if optimized_prompt?
        execute_with_optimization(context)
      else
        execute_simple(context)
      end
    end

    private

    # Checks if the prompt has optimization metadata.
    #
    # @return [Boolean] True if the prompt has optimization data
    def optimized_prompt?
      @prompt&.metadata&.dig("optimization", "few_shot_examples").present?
    end

    # Executes with optimized instruction and few-shot examples.
    #
    # @param context [Hash] The merged LLM context
    # @return [String] The prediction
    def execute_with_optimization(context)
      # In a full implementation, this would:
      # 1. Load the DSPy signature
      # 2. Create a predictor with the optimized instruction
      # 3. Add few-shot examples
      # 4. Execute and return the result

      # For now, we render the prompt template and return a placeholder
      # that indicates this needs actual DSPy integration
      instruction = @prompt.system_prompt
      user_prompt = render_user_prompt(context)
      few_shot_examples = @prompt.metadata.dig("optimization", "few_shot_examples") || []

      # Build a formatted prompt string for demonstration
      build_prompt_string(instruction, few_shot_examples, user_prompt)
    end

    # Executes a simple prediction without optimization.
    #
    # @param context [Hash] The merged LLM context
    # @return [String] The prediction
    def execute_simple(context)
      instruction = @prompt&.system_prompt || ""
      user_prompt = render_user_prompt(context)

      "#{instruction}\n\n#{user_prompt}"
    end

    # Renders the user prompt template with the given context.
    #
    # @param context [Hash] The context for template rendering
    # @return [String] The rendered prompt
    def render_user_prompt(context)
      return "" unless @prompt&.user_prompt

      template = Liquid::Template.parse(@prompt.user_prompt)
      template.render(context.stringify_keys)
    end

    # Builds a formatted prompt string including few-shot examples.
    #
    # @param instruction [String] The system instruction
    # @param examples [Array<Hash>] The few-shot examples
    # @param user_prompt [String] The user's input prompt
    # @return [String] The formatted prompt
    def build_prompt_string(instruction, examples, user_prompt)
      parts = []
      parts << instruction if instruction.present?

      if examples.any?
        parts << "\n--- Examples ---"
        examples.each_with_index do |example, index|
          parts << "\nExample #{index + 1}:"
          parts << "Input: #{example['input'].to_json}"
          parts << "Output: #{example['output']}"
        end
        parts << "\n--- Your Turn ---"
      end

      parts << user_prompt if user_prompt.present?

      parts.join("\n")
    end

    # Generates a signature class for the current dataset.
    #
    # @return [Class] The generated signature class
    def build_signature
      SignatureGenerator.new(@experiment.dataset).generate
    end
  end
end
