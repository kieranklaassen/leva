require "application_system_test_case"

module Leva
  class WorkbenchTest < ApplicationSystemTestCase
    test "workbench index loads without errors" do
      visit leva.workbench_index_path
      assert_selector "h1", text: "Workbench"
    end
  end
end
