# frozen_string_literal: true

module Leva
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
    before_action :authenticate_user!

    private

    # @return [void]
    def authenticate_user!
      # Implement your authentication logic here
      # For example, using Devise:
      # redirect_to main_app.new_user_session_path unless current_user
    end
  end
end