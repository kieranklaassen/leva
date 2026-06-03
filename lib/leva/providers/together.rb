# frozen_string_literal: true

require "ruby_llm"

module Leva
  module Providers
    # RubyLLM provider for Together AI — an OpenAI-compatible inference endpoint.
    #
    # Together serves fine-tuned LoRA models at its OpenAI-compatible API, so this
    # provider subclasses RubyLLM's OpenAI provider and overrides only the base URL
    # and auth header — mirroring +RubyLLM::Providers::GPUStack+. Once registered
    # (see {Leva::Engine}), any caller can run a Together-served model through the
    # normal path — +RubyLLM.chat(model: id)+, a host-authored {Leva::BaseRun},
    # or the prompt optimizer — without touching the genuine +openai+ provider.
    #
    # The API key is read from +ENV["TOGETHER_API_KEY"]+ and the base URL from
    # +ENV["TOGETHER_API_BASE"]+ (falling back to {DEFAULT_API_BASE}); RubyLLM's
    # fixed configuration accessors are not extended.
    #
    # @see Leva::ModelRegistrar
    class Together < RubyLLM::Providers::OpenAI
      # Together's default OpenAI-compatible API base URL.
      DEFAULT_API_BASE = "https://api.together.xyz/v1"

      # @return [String] the Together API base URL
      def api_base
        ENV.fetch("TOGETHER_API_BASE", DEFAULT_API_BASE)
      end

      # @return [Hash] the auth headers; empty when no key is configured (so a call
      #   fails as unauthorized against Together rather than silently hitting OpenAI)
      def headers
        key = ENV["TOGETHER_API_KEY"]
        return {} if key.nil? || key.empty?

        { "Authorization" => "Bearer #{key}" }
      end

      class << self
        # Together models are registered explicitly by Leva, so RubyLLM must not
        # try to remote-list them during +refresh!+ (mirrors GPUStack).
        #
        # @return [Boolean]
        def local?
          true
        end
      end
    end
  end
end
