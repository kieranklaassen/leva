# frozen_string_literal: true

module Leva
  # Every Leva controller inherits from the host controller named by
  # +Leva.config.parent_controller+ (default ActionController::Base), so a host
  # can put its authentication and authorization in front of the whole UI.
  class ApplicationController < Leva.config.parent_controller.constantize
    protect_from_forgery with: :exception
  end
end
