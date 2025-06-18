require "test_helper"

module Leva
  class AssetsTest < ActionDispatch::IntegrationTest
    test "workbench loads without Tailwind CDN dependency" do
      get leva.workbench_index_path
      assert_response :success

      # Should not contain Tailwind CDN reference (we build our own CSS)
      assert_no_match(/cdn\.tailwindcss\.com/, response.body)
      
      # Stimulus should be served locally, not from CDN
      assert_no_match(/unpkg\.com.*stimulus/, response.body)
      assert_no_match(/cdn\.skypack\.dev.*stimulus/, response.body)
    end
  end
end
