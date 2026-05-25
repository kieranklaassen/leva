# frozen_string_literal: true

require "faraday"
require "faraday/multipart"
require "tempfile"

module Leva
  module FineTuners
    # Fine-tunes a model on Together AI via its REST API and returns the serving
    # binding for the resulting LoRA (served serverless at Together's base URL).
    #
    # Flow: export dataset -> upload JSONL file -> create LoRA fine-tune job ->
    # poll until terminal -> return the fine-tuned model id.
    #
    # @see Leva::FineTuners::Base
    class Together < Base
      # Together's OpenAI-compatible API base.
      API_BASE = "https://api.together.xyz/v1"

      # ENV var the API key is read from (also the binding's +api_key_env+).
      API_KEY_ENV = "TOGETHER_API_KEY"

      # Terminal job status indicating success.
      SUCCESS_STATUS = "completed"

      # Terminal job statuses indicating failure.
      FAILURE_STATUSES = %w[error failed cancelled].freeze

      # Response keys (in priority order) that carry the resulting model id.
      OUTPUT_NAME_KEYS = %w[output_name model_output_name fine_tuned_model].freeze

      # Default seconds between status polls.
      DEFAULT_POLL_INTERVAL = 10

      # Safety cap on poll attempts.
      MAX_POLLS = 720

      # @param progress [#call, nil] progress callback
      # @param api_key [String, nil] overrides ENV[API_KEY_ENV]
      # @param api_base [String, nil] overrides the API base
      # @param poll_interval [Numeric] seconds between polls (0 in tests)
      # @param connection [Faraday::Connection, nil] injectable connection (tests)
      def initialize(progress: nil, api_key: nil, api_base: nil, poll_interval: DEFAULT_POLL_INTERVAL, connection: nil)
        super(progress: progress)
        @api_key = api_key || ENV[API_KEY_ENV]
        @api_base = api_base || ENV.fetch("TOGETHER_API_BASE", API_BASE)
        @poll_interval = poll_interval
        @connection = connection
      end

      # @param fine_tune_run [Leva::FineTuneRun]
      # @return [Hash] serving binding for the fine-tuned model
      # @raise [Leva::FineTuneError] on missing key, empty data, or a failed job
      def run(fine_tune_run)
        raise Leva::FineTuneError, "#{API_KEY_ENV} is not set" if @api_key.nil? || @api_key.empty?

        report(step: "exporting", progress: 5)
        jsonl = JsonlExporter.new(fine_tune_run.dataset).to_jsonl
        raise Leva::FineTuneError, "dataset produced no training examples" if jsonl.strip.empty?

        report(step: "uploading", progress: 15)
        file_id = upload_file(jsonl)
        fine_tune_run.try(:update, training_file_id: file_id)

        report(step: "creating_job", progress: 30)
        job_id = create_job(file_id, fine_tune_run.base_model, fine_tune_run.try(:hyperparameters))
        fine_tune_run.try(:update, provider_job_id: job_id)

        model_id = poll_until_terminal(job_id)
        report(step: "completed", progress: 100)

        { model_id: model_id, serving_base_url: @api_base, api_key_env: API_KEY_ENV, serverless: true }
      end

      private

      # @return [String] the uploaded file id
      def upload_file(jsonl)
        Tempfile.create([ "leva_training", ".jsonl" ]) do |file|
          file.write(jsonl)
          file.flush
          response = connection.post(endpoint("files")) do |req|
            req.body = {
              purpose: "fine-tune",
              file: Faraday::Multipart::FilePart.new(file.path, "application/jsonl", "training.jsonl")
            }
          end
          ensure_success!(response, "file upload")
          fetch(response.body, "id")
        end
      end

      # @return [String] the created job id
      def create_job(file_id, base_model, hyperparameters)
        body = { training_file: file_id, model: base_model, lora: true }
        body.merge!(hyperparameters.symbolize_keys) if hyperparameters.is_a?(Hash)

        response = connection.post(endpoint("fine-tunes")) do |req|
          req.headers["Content-Type"] = "application/json"
          req.body = JSON.generate(body)
        end
        ensure_success!(response, "fine-tune create")
        fetch(response.body, "id")
      end

      # Polls the job until it reaches a terminal status.
      #
      # @return [String] the resulting fine-tuned model id
      # @raise [Leva::FineTuneError] if the job fails
      def poll_until_terminal(job_id)
        MAX_POLLS.times do
          response = connection.get(endpoint("fine-tunes/#{job_id}"))
          ensure_success!(response, "fine-tune status")
          body = response.body
          status = body["status"].to_s

          report(step: "training", progress: training_progress(body))

          return output_name(body) if status == SUCCESS_STATUS
          raise Leva::FineTuneError, "Together fine-tune #{status}: #{job_error(body)}" if FAILURE_STATUSES.include?(status)

          sleep(@poll_interval) if @poll_interval.to_f.positive?
        end

        raise Leva::FineTuneError, "Together fine-tune did not complete after #{MAX_POLLS} polls"
      end

      # @return [Integer] a bounded progress estimate while training (30..95)
      def training_progress(body)
        pct = body["progress"] || body.dig("events", "progress")
        return 60 unless pct.is_a?(Numeric)

        [ [ 30 + (pct * 0.65).to_i, 30 ].max, 95 ].min
      end

      # @return [String] the resulting model id from a completed job
      def output_name(body)
        key = OUTPUT_NAME_KEYS.find { |candidate| body[candidate].present? }
        raise Leva::FineTuneError, "Together job completed without a model name" unless key

        body[key]
      end

      def job_error(body)
        body["error"] || body.dig("error", "message") || "no error detail"
      end

      # @return [String] absolute URL for an API path (avoids Faraday base-join pitfalls)
      def endpoint(path)
        "#{@api_base}/#{path}"
      end

      def connection
        @connection ||= Faraday.new do |f|
          f.request :multipart
          f.response :json, content_type: /\bjson$/
          f.headers["Authorization"] = "Bearer #{@api_key}"
          f.adapter Faraday.default_adapter
        end
      end

      def ensure_success!(response, action)
        return if response.success?

        detail = response.body.is_a?(Hash) ? (response.body["error"] || response.body["message"]) : nil
        raise Leva::FineTuneError, "Together #{action} failed (HTTP #{response.status})#{": #{detail}" if detail}"
      end

      def fetch(body, key)
        value = body.is_a?(Hash) ? body[key] : nil
        raise Leva::FineTuneError, "Together response missing '#{key}'" if value.nil?

        value
      end
    end
  end
end
