# frozen_string_literal: true

require "test_helper"
require "ostruct"

module Leva
  module FineTuners
    class TogetherTest < ActiveSupport::TestCase
      setup do
        @dataset = Leva::Dataset.create!(name: "Sentiment")
        10.times { |i| @dataset.add_record(TextContent.create!(text: "Text #{i}", expected_label: "positive")) }
        @run = OpenStruct.new(dataset: @dataset, base_model: "Qwen/Qwen3-8B", hyperparameters: nil)
      end

      test "uploads, creates, polls to completion and returns the serving binding" do
        steps = []
        together = build_together(
          progress: ->(step:, progress:) { steps << step },
          &method(:happy_path_stubs)
        )

        result = together.run(@run)

        assert_equal "kieran/Qwen3-8B-ft-1", result[:model_id]
        assert_equal Together::API_BASE, result[:serving_base_url]
        assert_equal "TOGETHER_API_KEY", result[:api_key_env]
        assert result[:serverless]
        assert_includes steps, "uploading"
        assert_includes steps, "completed"
      end

      test "raises a FineTuneError when the job fails" do
        together = build_together do |stub|
          stub.post(url("files")) { ok(id: "file-1") }
          stub.post(url("fine-tunes")) { ok(id: "ft-1", status: "pending") }
          stub.get(url("fine-tunes/ft-1")) { ok(id: "ft-1", status: "error", error: "bad training data") }
        end

        error = assert_raises(Leva::FineTuneError) { together.run(@run) }
        assert_match(/error/, error.message)
      end

      test "raises before creating a job when the upload returns non-2xx" do
        together = build_together do |stub|
          stub.post(url("files")) { [ 400, json_headers, { error: "bad file" }.to_json ] }
          # No /fine-tunes stub: if create_job were called, the test adapter would raise a
          # different (not-stubbed) error, so a FineTuneError proves we stopped at upload.
        end

        assert_raises(Leva::FineTuneError) { together.run(@run) }
      end

      test "raises when the API key is missing" do
        together = Together.new(api_key: "", poll_interval: 0)
        assert_raises(Leva::FineTuneError) { together.run(@run) }
      end

      private

      def build_together(progress: nil, &stub_block)
        stubs = Faraday::Adapter::Test::Stubs.new(&stub_block)
        connection = Faraday.new do |f|
          f.request :multipart
          f.response :json, content_type: /\bjson$/
          f.adapter :test, stubs
        end
        Together.new(api_key: "sk-test", poll_interval: 0, connection: connection, progress: progress)
      end

      def happy_path_stubs(stub)
        stub.post(url("files")) { ok(id: "file-1") }
        stub.post(url("fine-tunes")) { ok(id: "ft-1", status: "pending") }
        stub.get(url("fine-tunes/ft-1")) { ok(id: "ft-1", status: "completed", output_name: "kieran/Qwen3-8B-ft-1") }
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
