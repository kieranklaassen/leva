# frozen_string_literal: true

require "test_helper"

module Leva
  # Proves the routing seam the whole fine-tuning feature rests on: a model
  # registered under the +together+ provider resolves to Leva's Together provider
  # (Together's base URL), while genuine OpenAI models are untouched.
  class TogetherProviderTest < ActiveSupport::TestCase
    test "together provider is registered with RubyLLM at boot" do
      assert_equal Leva::Providers::Together, RubyLLM::Provider.providers[:together]
    end

    test "together provider slug resolves to 'together'" do
      assert_equal "together", Leva::Providers::Together.slug
    end

    test "a model with provider 'together' resolves to the Together provider class" do
      info = RubyLLM::Model::Info.new(
        id: "ft-resolution-check",
        provider: "together",
        modalities: { input: [ "text" ], output: [ "text" ] }
      )
      assert_equal Leva::Providers::Together, info.provider_class
    end

    test "together api_base points at Together, not OpenAI" do
      provider = Leva::Providers::Together.new(RubyLLM.config)
      assert_equal "https://api.together.xyz/v1", provider.api_base
    end

    test "together api_base honors a TOGETHER_API_BASE override" do
      provider = Leva::Providers::Together.new(RubyLLM.config)
      with_env("TOGETHER_API_BASE", "https://example.test/v1") do
        assert_equal "https://example.test/v1", provider.api_base
      end
    end

    test "together headers carry the bearer token when the key is set" do
      provider = Leva::Providers::Together.new(RubyLLM.config)
      with_env("TOGETHER_API_KEY", "sk-together-123") do
        assert_equal({ "Authorization" => "Bearer sk-together-123" }, provider.headers)
      end
    end

    test "together headers are empty when the key is unset (no silent OpenAI fallback)" do
      provider = Leva::Providers::Together.new(RubyLLM.config)
      with_env("TOGETHER_API_KEY", nil) do
        assert_empty provider.headers
      end
    end

    test "genuine OpenAI models still resolve to the real OpenAI endpoint" do
      provider = RubyLLM::Providers::OpenAI.new(RubyLLM.config)
      assert_equal "https://api.openai.com/v1", provider.api_base
    end

    test "together is a local provider so refresh! will not remote-list it" do
      assert Leva::Providers::Together.local?
    end

    private

    def with_env(key, value)
      original = ENV[key]
      value.nil? ? ENV.delete(key) : ENV[key] = value
      yield
    ensure
      original.nil? ? ENV.delete(key) : ENV[key] = original
    end
  end
end
