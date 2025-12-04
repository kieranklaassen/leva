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
  end
end
