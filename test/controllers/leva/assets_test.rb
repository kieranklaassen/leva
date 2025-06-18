require "test_helper"

module Leva
  class AssetsTest < ActionDispatch::IntegrationTest
    test "application CSS loads without CDN" do
      get leva.workbench_index_path
      
      # Should not contain CDN references
      assert_no_match(/cdn\.tailwindcss\.com/, response.body)
      assert_no_match(/cdn\.jsdelivr\.net.*stimulus/, response.body)
      
      # Should contain local asset references
      assert_match(/stylesheet_link_tag.*leva\/application/, response.body)
      assert_match(/javascript_include_tag.*application/, response.body)
    end

    test "importmap is configured" do
      get leva.workbench_index_path
      
      # Should have importmap tags
      assert_match(/importmap-shim/, response.body)
    end

    test "Stimulus controllers are properly named" do
      # Test new prompt page
      get leva.new_workbench_path
      assert_response :success
      
      # Check for renamed controllers
      assert_match(/data-controller=.*prompt-selector-new/, response.body)
      assert_match(/data-controller=.*dialog/, response.body)
      
      # Should not have inline script tags
      assert_no_match(/<script>\s*\(\(\)\s*=>\s*{/, response.body)
    end
  end
end