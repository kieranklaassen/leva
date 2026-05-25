# frozen_string_literal: true

module Leva
  # Exports a Leva dataset to chat-format JSONL suitable for supervised
  # fine-tuning (one +{"messages":[...]}+ object per line).
  #
  # Reuses {Leva::DatasetConverter#split} for the train slice (so train/val/test
  # ratios and nil-sanitization match the optimizer), renders each record's
  # context into the user turn, and places +ground_truth+ in the assistant turn.
  #
  # @example
  #   Leva::JsonlExporter.new(dataset).to_jsonl
  #   # => '{"messages":[{"role":"user",...},{"role":"assistant",...}]}\n...'
  class JsonlExporter
    # @param dataset [Leva::Dataset] the dataset to export
    # @param system_prompt [String, nil] optional system turn prepended to each example
    # @param user_template [String, nil] optional Liquid template for the user turn;
    #   when nil the record's context is serialized as "key: value" lines
    # @param seed [Integer, nil] random seed forwarded to DatasetConverter#split
    def initialize(dataset, system_prompt: nil, user_template: nil, seed: nil)
      @dataset = dataset
      @system_prompt = system_prompt.presence
      @user_template = user_template.presence
      @seed = seed
    end

    # @return [Array<Hash>] chat-format examples for the train split
    def examples
      DatasetConverter.new(@dataset).split(seed: @seed)[:train].map { |example| build_messages(example) }
    end

    # @return [String] newline-delimited JSON, one example per line
    def to_jsonl
      examples.map { |example| JSON.generate(example) }.join("\n")
    end

    private

    # @param example [Hash] a {input:, expected: {output:}} example from DatasetConverter
    # @return [Hash] a chat-format example
    def build_messages(example)
      messages = []
      messages << { role: "system", content: @system_prompt } if @system_prompt
      messages << { role: "user", content: user_content(example[:input]) }
      messages << { role: "assistant", content: example.dig(:expected, :output).to_s }
      { messages: messages }
    end

    # @param context [Hash, nil] the (already sanitized) record context
    # @return [String] the user turn content
    def user_content(context)
      context ||= {}
      if @user_template
        Liquid::Template.parse(@user_template).render(context.stringify_keys)
      else
        context.map { |key, value| "#{key}: #{value}" }.join("\n")
      end
    end
  end
end
