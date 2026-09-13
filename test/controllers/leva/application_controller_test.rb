# frozen_string_literal: true

require "test_helper"

module Leva
  class ApplicationControllerTest < ActiveSupport::TestCase
    test "Leva's controllers inherit from the host controller named by Leva.config.parent_controller" do
      assert_equal "ApplicationController", Leva.config.parent_controller
      assert_equal ::ApplicationController, Leva::ApplicationController.superclass
      assert_includes Leva::DatasetsController.ancestors, ::ApplicationController
    end

    test "the parent controller defaults to ActionController::Base" do
      assert_equal "ActionController::Base", Leva::Configuration.new.parent_controller
    end
  end
end
