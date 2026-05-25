# frozen_string_literal: true

require "test_helper"
require "tempfile"
require "minitest/mock"

module Leva
  class FineTuneJobTest < ActiveSupport::TestCase
    # Minimal stand-in for a FineTuners adapter.
    class FakeAdapter
      def initialize(result: nil, error: nil)
        @result = result
        @error = error
      end

      def run(_fine_tune_run)
        raise @error if @error

        @result
      end
    end

    setup do
      @models_snapshot = RubyLLM.models.all.dup
      @overlay = Tempfile.new([ "leva_fine_tuned_models", ".json" ])
      @overlay.close
      File.delete(@overlay.path)
      Leva.config.fine_tuned_models_path = @overlay.path

      @dataset = Leva::Dataset.create!(name: "Sentiment")
      @run = Leva::FineTuneRun.create!(dataset: @dataset, base_model: Leva::FineTuneRun::DEFAULT_BASE_MODEL)
    end

    teardown do
      RubyLLM.models.all.replace(@models_snapshot)
      File.delete(@overlay.path) if File.exist?(@overlay.path)
      Leva.config.fine_tuned_models_path = nil
    end

    test "completes the run, stores the model id, and registers the model" do
      result = {
        model_id: "kieran/Qwen3-8B-ft-1",
        serving_base_url: Leva::Providers::Together::DEFAULT_API_BASE,
        api_key_env: "TOGETHER_API_KEY",
        serverless: true
      }

      Leva::FineTuners::Together.stub(:new, FakeAdapter.new(result: result)) do
        Leva::FineTuneJob.perform_now(fine_tune_run_id: @run.id)
      end

      @run.reload
      assert @run.completed?
      assert_equal "kieran/Qwen3-8B-ft-1", @run.fine_tuned_model_id
      assert RubyLLM.models.find("kieran/Qwen3-8B-ft-1")
    end

    test "marks the run failed with a message and registers nothing on adapter failure" do
      adapter = FakeAdapter.new(error: Leva::FineTuneError.new("Together fine-tune error: bad data"))

      assert_raises(Leva::FineTuneError) do
        Leva::FineTuners::Together.stub(:new, adapter) do
          Leva::FineTuneJob.perform_now(fine_tune_run_id: @run.id)
        end
      end

      @run.reload
      assert @run.failed?
      assert_equal "Together fine-tune error: bad data", @run.error_message
      assert_nil @run.fine_tuned_model_id
      assert_raises(RubyLLM::ModelNotFoundError) { RubyLLM.models.find("kieran/Qwen3-8B-ft-1") }
    end
  end
end
