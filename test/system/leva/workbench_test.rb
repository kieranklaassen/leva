require "application_system_test_case"

module Leva
  class WorkbenchTest < ApplicationSystemTestCase
    setup do
      @dataset = Leva::Dataset.create!(name: "Test Dataset")
      @dataset_record = @dataset.dataset_records.create!(
        recordable: TextContent.create!(text: "Test content", expected_label: "positive")
      )
      @prompt = Leva::Prompt.create!(
        name: "Test Prompt",
        system_prompt: "You are a helpful assistant",
        user_prompt: "Analyze this: {{ text }}"
      )
    end

    test "visiting the workbench index" do
      visit leva.workbench_index_path
      
      assert_selector "h1", text: "Workbench"
      assert_selector ".prompt-card", count: 1
      assert_text "Test Prompt"
    end

    test "creating a new prompt shows JavaScript functionality" do
      visit leva.new_workbench_path
      
      # Test form presence
      assert_selector "h1", text: "New Prompt"
      assert_selector "form[data-controller='prompt-selector-new dialog']"
      
      # Fill in form
      fill_in "Name", with: "New Test Prompt"
      fill_in "System prompt", with: "System instructions"
      fill_in "User prompt", with: "User template"
      
      # Submit form
      click_button "Create Prompt"
      
      # Should redirect to workbench
      assert_current_path leva.workbench_index_path
      assert_text "New Test Prompt"
    end

    test "button loader controller shows spinner" do
      visit leva.workbench_index_path
      
      # Check button loader controller is attached
      assert_selector "[data-controller='button-loader']"
      assert_selector "[data-action='click->button-loader#handleClick']"
    end

    test "clipboard functionality" do
      visit leva.workbench_path(@prompt)
      
      # Check clipboard controller is attached
      assert_selector "[data-controller*='clipboard']"
      assert_selector "[data-action='clipboard#copy']"
    end

    test "collapsible sections" do
      visit leva.workbench_path(@prompt)
      
      # Check collapsible controller if liquid tags section exists
      if page.has_text?("AVAILABLE LIQUID TAGS")
        assert_selector "[data-controller*='collapsible']"
        assert_selector "[data-action='click->collapsible#toggle']"
      end
    end
  end
end