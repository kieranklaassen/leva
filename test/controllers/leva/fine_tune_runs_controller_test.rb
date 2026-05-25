# frozen_string_literal: true

require "test_helper"

module Leva
  class FineTuneRunsControllerTest < ActionDispatch::IntegrationTest
    include ActiveJob::TestHelper

    setup do
      @routes = Engine.routes
      @dataset = Dataset.create!(name: "Sentiment")
      3.times { |i| @dataset.add_record(TextContent.create!(text: "Text #{i}", expected_label: "positive")) }
    end

    teardown do
      Leva.config.authorize_fine_tune = nil
    end

    test "create enqueues a fine-tune job and redirects to the run" do
      assert_enqueued_with(job: Leva::FineTuneJob) do
        post leva.dataset_fine_tune_runs_path(@dataset), params: { base_model: Leva::FineTuneRun::DEFAULT_BASE_MODEL }
      end

      run = Leva::FineTuneRun.last
      assert_equal @dataset, run.dataset
      assert_equal Leva::FineTuneRun::DEFAULT_BASE_MODEL, run.base_model
      assert_redirected_to leva.fine_tune_run_path(run)
    end

    test "create defaults the base model when none is given" do
      assert_difference -> { Leva::FineTuneRun.count }, 1 do
        post leva.dataset_fine_tune_runs_path(@dataset)
      end
      assert_equal Leva::FineTuneRun::DEFAULT_BASE_MODEL, Leva::FineTuneRun.last.base_model
    end

    test "create rejects an unsupported base model without enqueuing" do
      assert_no_enqueued_jobs do
        assert_no_difference -> { Leva::FineTuneRun.count } do
          post leva.dataset_fine_tune_runs_path(@dataset), params: { base_model: "made/up-model" }
        end
      end
      assert_redirected_to leva.dataset_path(@dataset)
    end

    test "create is blocked when the authorization gate denies" do
      Leva.config.authorize_fine_tune = ->(_controller) { false }

      assert_no_enqueued_jobs do
        assert_no_difference -> { Leva::FineTuneRun.count } do
          post leva.dataset_fine_tune_runs_path(@dataset), params: { base_model: Leva::FineTuneRun::DEFAULT_BASE_MODEL }
        end
      end
      assert_redirected_to leva.dataset_path(@dataset)
    end

    test "show renders progress for an in-flight run" do
      run = @dataset.fine_tune_runs.create!(base_model: Leva::FineTuneRun::DEFAULT_BASE_MODEL, status: :running, progress: 30)
      get leva.fine_tune_run_path(run)
      assert_response :success
      assert_match(/Fine-tuning Model/, response.body)
    end

    test "show returns run status as JSON for polling" do
      run = @dataset.fine_tune_runs.create!(base_model: Leva::FineTuneRun::DEFAULT_BASE_MODEL, status: :running, progress: 30)
      get leva.fine_tune_run_path(run, format: :json)
      assert_response :success
      body = JSON.parse(response.body)
      assert_equal "running", body["status"]
      assert_equal 30, body["progress"]
    end
  end
end
