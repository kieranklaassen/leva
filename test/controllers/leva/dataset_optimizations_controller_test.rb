# frozen_string_literal: true

require "test_helper"

module Leva
  class DatasetOptimizationsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @routes = Engine.routes
      @dataset = Dataset.create!(name: "Test Dataset", description: "A test dataset")

      # Create enough records for optimization
      15.times do |i|
        text_content = TextContent.create!(
          text: "Test text #{i}",
          expected_label: %w[positive negative neutral][i % 3]
        )
        @dataset.add_record(text_content)
      end
    end

    # New action tests
    test "should get new optimization page" do
      get leva.new_dataset_optimization_path(@dataset)
      assert_response :success
      assert_match(/Optimize Prompt/, response.body)
    end

    test "new page shows dataset stats" do
      get leva.new_dataset_optimization_path(@dataset)
      assert_response :success
      assert_match(/Records/, response.body)
      assert_match(/15/, response.body)  # 15 records
    end

    test "new page shows ready status when enough records" do
      get leva.new_dataset_optimization_path(@dataset)
      assert_response :success
      assert_match(/Ready/, response.body)
    end

    test "new page shows warning when not enough records" do
      small_dataset = Dataset.create!(name: "Small Dataset")
      3.times do |i|
        text_content = TextContent.create!(
          text: "Small text #{i}",
          expected_label: "positive"
        )
        small_dataset.add_record(text_content)
      end

      get leva.new_dataset_optimization_path(small_dataset)
      assert_response :success
      assert_match(/Not Enough Data/, response.body)
      assert_match(/7 more/, response.body)  # Need 7 more records
    end

    test "new page shows mode selection" do
      get leva.new_dataset_optimization_path(@dataset)
      assert_response :success
      assert_match(/Light/, response.body)
      assert_match(/Medium/, response.body)
      assert_match(/Heavy/, response.body)
    end

    # Create action tests
    test "should enqueue optimization job" do
      assert_enqueued_with(job: PromptOptimizationJob) do
        post leva.dataset_optimization_path(@dataset), params: {
          prompt_name: "My Optimized Prompt",
          mode: "light"
        }
      end
    end

    test "should create optimization run and redirect to it" do
      assert_difference "OptimizationRun.count", 1 do
        post leva.dataset_optimization_path(@dataset), params: {
          prompt_name: "My Optimized Prompt",
          mode: "light"
        }
      end

      optimization_run = OptimizationRun.last
      assert_redirected_to leva.optimization_run_path(optimization_run)
      assert_equal "My Optimized Prompt", optimization_run.prompt_name
      assert_equal "light", optimization_run.mode
    end

    test "should use default prompt name if not provided" do
      post leva.dataset_optimization_path(@dataset), params: { mode: "light" }

      optimization_run = OptimizationRun.last
      assert_equal "Optimized: #{@dataset.name}", optimization_run.prompt_name
    end

    test "should pass mode parameter to optimization run" do
      post leva.dataset_optimization_path(@dataset), params: {
        prompt_name: "Test",
        mode: "medium"
      }

      optimization_run = OptimizationRun.last
      assert_equal "medium", optimization_run.mode
    end

    test "should pass model parameter to optimization run" do
      post leva.dataset_optimization_path(@dataset), params: {
        prompt_name: "Test",
        mode: "light",
        model: "gpt-5-mini"
      }

      optimization_run = OptimizationRun.last
      assert_equal "gpt-5-mini", optimization_run.model
    end

    test "should use default model if not provided" do
      post leva.dataset_optimization_path(@dataset), params: {
        prompt_name: "Test",
        mode: "light"
      }

      optimization_run = OptimizationRun.last
      assert_equal PromptOptimizer::DEFAULT_MODEL, optimization_run.model
    end
  end
end
