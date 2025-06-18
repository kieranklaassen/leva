require "test_helper"

module Leva
  class AssetsTest < ActionDispatch::IntegrationTest
    test "workbench loads without CDN dependencies" do
      get leva.workbench_index_path
      assert_response :success
      
      # Should not contain CDN references
      assert_no_match(/cdn\.tailwindcss\.com/, response.body)
      assert_no_match(/cdn\.jsdelivr\.net/, response.body)
    end
  end
end