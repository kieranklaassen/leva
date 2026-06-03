# frozen_string_literal: true

require "test_helper"

module Leva
  module FineTuners
    class TogetherTest < ActiveSupport::TestCase
      setup do
        @dataset = Leva::Dataset.create!(name: "Sentiment")
        10.times { |i| @dataset.add_record(TextContent.create!(text: "Text #{i}", expected_label: "positive")) }
        @run = Leva::FineTuneRun.create!(dataset: @dataset, base_model: Leva::FineTuneRun::DEFAULT_BASE_MODEL)
      end

      test "uploads (presigned flow), creates, polls to completion and returns the serving binding" do
        steps = []
        together = build_together(progress: ->(step:, progress:) { steps << step }) do |stub|
          add_upload_stubs(stub)
          stub.post(url("fine-tunes")) { ok(id: "ft-1", status: "pending") }
          stub.get(url("fine-tunes/ft-1")) { ok(id: "ft-1", status: "completed", output_name: "kieran/Qwen2.5-7B-Instruct-ft-1") }
        end

        result = together.run(@run)

        assert_equal "kieran/Qwen2.5-7B-Instruct-ft-1", result[:model_id]
        assert_equal Together::API_BASE, result[:serving_base_url]
        assert_equal "TOGETHER_API_KEY", result[:api_key_env]
        assert result[:serverless]
        assert_includes steps, "uploading"
        assert_includes steps, "completed"
      end

      test "persists the training file id and provider job id on the run" do
        build_together do |stub|
          add_upload_stubs(stub)
          stub.post(url("fine-tunes")) { ok(id: "ft-1", status: "pending") }
          stub.get(url("fine-tunes/ft-1")) { ok(id: "ft-1", status: "completed", output_name: "m") }
        end.run(@run)

        @run.reload
        assert_equal "file-1", @run.training_file_id
        assert_equal "ft-1", @run.provider_job_id
      end

      test "raises a FineTuneError when the job fails, surfacing a nested error message" do
        together = build_together do |stub|
          add_upload_stubs(stub)
          stub.post(url("fine-tunes")) { ok(id: "ft-1", status: "pending") }
          stub.get(url("fine-tunes/ft-1")) { ok(id: "ft-1", status: "error", error: { message: "bad training data" }) }
        end

        error = assert_raises(Leva::FineTuneError) { together.run(@run) }
        assert_match(/bad training data/, error.message)
      end

      test "raises before creating a job when the upload init returns non-302" do
        together = build_together do |stub|
          stub.post(url("files")) { [ 400, json_headers, { message: "bad file" }.to_json ] }
        end

        assert_raises(Leva::FineTuneError) { together.run(@run) }
      end

      test "raises when the job completes without a model name" do
        together = build_together do |stub|
          add_upload_stubs(stub)
          stub.post(url("fine-tunes")) { ok(id: "ft-1", status: "pending") }
          stub.get(url("fine-tunes/ft-1")) { ok(id: "ft-1", status: "completed") }
        end

        error = assert_raises(Leva::FineTuneError) { together.run(@run) }
        assert_match(/without a model name/, error.message)
      end

      test "raises after exhausting the poll budget when the job never finishes" do
        together = build_together do |stub|
          add_upload_stubs(stub)
          stub.post(url("fine-tunes")) { ok(id: "ft-1", status: "pending") }
          stub.get(url("fine-tunes/ft-1")) { ok(id: "ft-1", status: "running") }
        end

        error = assert_raises(Leva::FineTuneError) { together.run(@run) }
        assert_match(/did not complete/, error.message)
      end

      test "raises when the dataset produces no training examples" do
        empty = Leva::Dataset.create!(name: "Tiny")
        empty.add_record(TextContent.create!(text: "only one", expected_label: "positive"))
        run = Leva::FineTuneRun.create!(dataset: empty, base_model: Leva::FineTuneRun::DEFAULT_BASE_MODEL)

        error = assert_raises(Leva::FineTuneError) { build_together { |_stub| }.run(run) }
        assert_match(/no training examples/, error.message)
      end

      test "raises when the API key is missing" do
        together = Together.new(api_key: "", poll_interval: 0)
        assert_raises(Leva::FineTuneError) { together.run(@run) }
      end

      private

      def build_together(progress: nil, &stub_block)
        stubs = Faraday::Adapter::Test::Stubs.new(&stub_block)
        conn = Faraday.new do |f|
          f.request :multipart
          f.response :json, content_type: /\bjson$/
          f.adapter :test, stubs
        end
        # Inject the same test connection for both API calls and the S3 PUT.
        Together.new(api_key: "sk-test", poll_interval: 0, connection: conn, upload_connection: conn, progress: progress)
      end

      # Stubs Together's presigned upload flow: POST /files -> 302 (Location +
      # X-Together-File-Id) -> PUT bytes to the presigned URL -> POST /preprocess.
      def add_upload_stubs(stub)
        stub.post(url("files")) { [ 302, { "Location" => "https://s3.test/upload", "X-Together-File-Id" => "file-1" }, "" ] }
        stub.put("https://s3.test/upload") { [ 200, {}, "" ] }
        stub.post(url("files/file-1/preprocess")) { ok(id: "file-1") }
      end

      def url(path)
        "#{Together::API_BASE}/#{path}"
      end

      def ok(payload)
        [ 200, json_headers, payload.to_json ]
      end

      def json_headers
        { "Content-Type" => "application/json" }
      end
    end
  end
end
