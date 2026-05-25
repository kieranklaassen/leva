# frozen_string_literal: true

require "test_helper"

module Leva
  class FineTuneRunTest < ActiveSupport::TestCase
    setup do
      @dataset = Leva::Dataset.create!(name: "Sentiment")
    end

    test "defaults to pending status and the together provider" do
      run = create_run
      assert run.pending?
      assert_equal "together", run.provider
    end

    test "requires a base_model in the supported allowlist" do
      assert build_run(base_model: nil).invalid?
      assert build_run(base_model: "made/up-model").invalid?
      assert build_run(base_model: FineTuneRun::DEFAULT_BASE_MODEL).valid?
    end

    test "requires a provider" do
      assert build_run(provider: nil).invalid?
    end

    test "progress must be within 0..100" do
      assert build_run(progress: -1).invalid?
      assert build_run(progress: 101).invalid?
      assert build_run(progress: 50).valid?
    end

    test "start! marks the run running at zero progress" do
      run = create_run
      run.start!
      assert run.running?
      assert_equal 0, run.progress
      assert_equal "exporting", run.current_step
    end

    test "update_progress records the step and percentage" do
      run = create_run
      run.update_progress(step: "training", progress: 60)
      assert_equal "training", run.current_step
      assert_equal 60, run.progress
    end

    test "complete! stores the model id, serving binding, and finishes at 100%" do
      run = create_run
      run.complete!(result: { model_id: "kieran/Qwen3-8B-ft-1", serving_base_url: "https://api.together.xyz/v1" })
      assert run.completed?
      assert_equal 100, run.progress
      assert_equal "kieran/Qwen3-8B-ft-1", run.fine_tuned_model_id
      assert_equal "https://api.together.xyz/v1", run.serving_base_url
    end

    test "fail! sanitizes a multi-line provider error to a single, payload-free line" do
      run = create_run
      run.fail!("Together error: bad row\n{\"raw\":\"...secret training payload...\"}")
      assert run.failed?
      assert_equal "Together error: bad row", run.error_message
      assert_not_includes run.error_message, "secret training payload"
    end

    private

    def build_run(**attrs)
      FineTuneRun.new({ dataset: @dataset, base_model: FineTuneRun::DEFAULT_BASE_MODEL }.merge(attrs))
    end

    def create_run(**attrs)
      build_run(**attrs).tap(&:save!)
    end
  end
end
