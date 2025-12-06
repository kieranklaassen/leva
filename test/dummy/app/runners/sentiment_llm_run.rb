# frozen_string_literal: true

# Runner that uses RubyLLM to perform actual LLM-based sentiment analysis.
#
# This runner:
# - Uses the optimized prompt from the experiment (system_prompt + few_shot_examples)
# - Calls RubyLLM to get a real LLM response
# - Returns the full response for parsing by extract_regex_pattern
#
# @example Usage in experiment
#   experiment = Leva::Experiment.new(
#     dataset: dataset,
#     prompt: optimized_prompt,
#     runner_class: "SentimentLlmRun"
#   )
class SentimentLlmRun < Leva::DspyRunner
  # The model to use for LLM calls.
  # Can be overridden by setting @model before execution.
  DEFAULT_MODEL = "gemini-2.5-flash"

  # Executes sentiment analysis using RubyLLM.
  #
  # @param record [TextContent] The text content to analyze
  # @return [String] The LLM response containing sentiment in XML tags
  def execute(record)
    context = merged_llm_context

    # Build the messages for the chat
    messages = build_messages(context)

    # Get the model (from experiment metadata or default)
    model_id = experiment_model || DEFAULT_MODEL

    # Call RubyLLM
    chat = RubyLLM.chat(model: model_id)
    messages.each { |msg| chat.add_message(role: msg[:role], content: msg[:content]) }

    response = chat.complete
    response.content
  end

  private

  # Builds the messages array for the chat.
  #
  # @param context [Hash] The merged LLM context
  # @return [Array<Hash>] Array of message hashes with :role and :content
  def build_messages(context)
    messages = []

    # System message with instruction
    system_content = build_system_message
    messages << { role: :system, content: system_content } if system_content.present?

    # Add few-shot examples as user/assistant pairs
    few_shot_examples.each do |example|
      messages << { role: :user, content: format_example_input(example["input"]) }
      messages << { role: :assistant, content: format_example_output(example["output"]) }
    end

    # User message with the actual input
    user_content = render_user_prompt(context)
    messages << { role: :user, content: user_content }

    messages
  end

  # Builds the system message from the prompt.
  #
  # @return [String] The system instruction
  def build_system_message
    return "" unless @prompt

    instruction = @prompt.system_prompt || ""

    # Add output format hint
    instruction + "\n\nRespond with your sentiment analysis wrapped in XML tags like: <sentiment>positive</sentiment>"
  end

  # Gets few-shot examples from the prompt metadata.
  #
  # @return [Array<Hash>] The few-shot examples
  def few_shot_examples
    @prompt&.metadata&.dig("optimization", "few_shot_examples") || []
  end

  # Formats the input for a few-shot example.
  #
  # @param input [Hash, String] The example input
  # @return [String] Formatted input string
  def format_example_input(input)
    if input.is_a?(Hash)
      input["text"] || input.to_json
    else
      input.to_s
    end
  end

  # Formats the output for a few-shot example.
  #
  # @param output [String] The example output
  # @return [String] Formatted output with XML tags
  def format_example_output(output)
    "<sentiment>#{output}</sentiment>"
  end

  # Gets the model from experiment metadata if available.
  #
  # @return [String, nil] The model ID or nil
  def experiment_model
    @experiment&.metadata&.dig("model")
  end
end
