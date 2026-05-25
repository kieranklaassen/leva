# frozen_string_literal: true

require "test_helper"
require "tempfile"

module Leva
  class ModelRegistrarTest < ActiveSupport::TestCase
    setup do
      @models_snapshot = RubyLLM.models.all.dup
      @overlay = Tempfile.new([ "leva_fine_tuned_models", ".json" ])
      @overlay.close
      File.delete(@overlay.path) # start absent
      Leva.config.fine_tuned_models_path = @overlay.path
    end

    teardown do
      RubyLLM.models.all.replace(@models_snapshot)
      File.delete(@overlay.path) if File.exist?(@overlay.path)
      Leva.config.fine_tuned_models_path = nil
    end

    test "register makes the model visible to chat_models and find" do
      assert ModelRegistrar.register(model_data)
      assert_includes RubyLLM.models.chat_models.map(&:id), model_data[:id]
      assert RubyLLM.models.find(model_data[:id])
    end

    test "registered model resolves under the together provider, not openai" do
      ModelRegistrar.register(model_data)
      info = RubyLLM.models.find(model_data[:id])
      assert_equal "together", info.provider
      assert_equal Leva::Providers::Together, info.provider_class
    end

    test "registered model computes as a chat model via modalities" do
      ModelRegistrar.register(model_data)
      assert_equal "chat", RubyLLM.models.find(model_data[:id]).type
    end

    test "registration is idempotent in memory and overlay" do
      assert ModelRegistrar.register(model_data)
      assert_not ModelRegistrar.register(model_data)
      assert_equal 1, RubyLLM.models.all.map(&:id).count(model_data[:id])
      entries = JSON.parse(File.read(@overlay.path), symbolize_names: true)
      assert_equal 1, entries.map { |e| e[:id] }.count(model_data[:id])
    end

    test "registration persists to the overlay file" do
      ModelRegistrar.register(model_data)
      entries = JSON.parse(File.read(@overlay.path), symbolize_names: true)
      assert_includes entries.map { |e| e[:id] }, model_data[:id]
    end

    test "sync! rehydrates the registry from the overlay (cross-process visibility)" do
      ModelRegistrar.register(model_data)
      # Simulate a fresh process whose in-memory registry lacks the entry.
      RubyLLM.models.all.replace(@models_snapshot.dup)
      assert_not_includes RubyLLM.models.all.map(&:id), model_data[:id]

      ModelRegistrar.sync!
      assert_includes RubyLLM.models.all.map(&:id), model_data[:id]
    end

    test "register requires a model id" do
      assert_raises(ArgumentError) { ModelRegistrar.register(model_data.merge(id: "")) }
    end

    test "available_models includes a freshly registered fine-tuned model" do
      Rails.cache.delete("leva/available_models")
      ModelRegistrar.register(model_data)
      assert_includes Leva::PromptOptimizer.available_models.map(&:id), model_data[:id]
    end

    test "call builds and registers the model from a completed run" do
      dataset = Leva::Dataset.create!(name: "Sentiment")
      run = Leva::FineTuneRun.create!(
        dataset: dataset,
        base_model: Leva::FineTuneRun::DEFAULT_BASE_MODEL,
        status: :completed,
        fine_tuned_model_id: "kieran/Qwen3-8B-ft-call",
        serving_base_url: Leva::Providers::Together::DEFAULT_API_BASE
      )

      assert ModelRegistrar.call(run)
      info = RubyLLM.models.find(run.fine_tuned_model_id)
      assert_equal "together", info.provider
      assert_equal "chat", info.type
      assert_equal Leva::FineTuneRun::DEFAULT_BASE_MODEL, info.metadata[:base_model]
    end

    private

    def model_data(id = "ft:qwen3-8b:sentiment-1")
      {
        id: id,
        name: "Sentiment fine-tune #1",
        provider: "together",
        family: "qwen3-finetune",
        context_window: 32_768,
        modalities: { input: [ "text" ], output: [ "text" ] }
      }
    end
  end
end
