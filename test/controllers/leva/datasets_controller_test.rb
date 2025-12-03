# frozen_string_literal: true

require "test_helper"

module Leva
  class DatasetsControllerTest < ActionDispatch::IntegrationTest
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

    # Standard CRUD tests
    test "should get index" do
      get leva.datasets_path
      assert_response :success
    end

    test "should get show" do
      get leva.dataset_path(@dataset)
      assert_response :success
      assert_match @dataset.name, response.body
    end

    test "should show optimize button on dataset page" do
      get leva.dataset_path(@dataset)
      assert_response :success
      assert_match(/Optimize Prompt/, response.body)
    end

    # Optimize action tests
    test "should get optimize page" do
      get leva.optimize_dataset_path(@dataset)
      assert_response :success
      assert_match(/Optimize Prompt/, response.body)
    end

    test "optimize page shows dataset stats" do
      get leva.optimize_dataset_path(@dataset)
      assert_response :success
      assert_match(/Records/, response.body)
      assert_match(/15/, response.body)  # 15 records
    end

    test "optimize page shows ready status when enough records" do
      get leva.optimize_dataset_path(@dataset)
      assert_response :success
      assert_match(/Ready/, response.body)
    end

    test "optimize page shows warning when not enough records" do
      small_dataset = Dataset.create!(name: "Small Dataset")
      3.times do |i|
        text_content = TextContent.create!(
          text: "Small text #{i}",
          expected_label: "positive"
        )
        small_dataset.add_record(text_content)
      end

      get leva.optimize_dataset_path(small_dataset)
      assert_response :success
      assert_match(/Not Enough Data/, response.body)
      assert_match(/7 more/, response.body)  # Need 7 more records
    end

    test "optimize page shows mode selection" do
      get leva.optimize_dataset_path(@dataset)
      assert_response :success
      assert_match(/Light/, response.body)
      assert_match(/Medium/, response.body)
      assert_match(/Heavy/, response.body)
    end

    # Run optimization tests
    test "should enqueue optimization job" do
      assert_enqueued_with(job: PromptOptimizationJob) do
        post leva.run_optimization_dataset_path(@dataset), params: {
          prompt_name: "My Optimized Prompt",
          mode: "light"
        }
      end
    end

    test "should redirect after starting optimization" do
      post leva.run_optimization_dataset_path(@dataset), params: {
        prompt_name: "My Optimized Prompt",
        mode: "light"
      }

      assert_redirected_to leva.dataset_path(@dataset)
      assert_match(/Prompt optimization started/, flash[:notice])
    end

    test "should use default prompt name if not provided" do
      assert_enqueued_with(
        job: PromptOptimizationJob,
        args: [ {
          dataset_id: @dataset.id,
          prompt_name: "Optimized: #{@dataset.name}",
          mode: :light
        } ]
      ) do
        post leva.run_optimization_dataset_path(@dataset), params: { mode: "light" }
      end
    end

    test "should pass mode parameter to job" do
      assert_enqueued_with(
        job: PromptOptimizationJob,
        args: [ { dataset_id: @dataset.id, prompt_name: "Test", mode: :medium } ]
      ) do
        post leva.run_optimization_dataset_path(@dataset), params: {
          prompt_name: "Test",
          mode: "medium"
        }
      end
    end
  end
end
