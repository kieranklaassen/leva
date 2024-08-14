# frozen_string_literal: true

module Leva
  module Generators
    class RunnerGenerator < Rails::Generators::NamedBase
      source_root File.expand_path('templates', __dir__)

      def create_runner_file
        template 'runner.rb.erb', File.join('app/runners', class_path, "#{file_name}_run.rb")
      end

      private

      def file_name
        @_file_name ||= remove_possible_suffix(super)
      end

      def remove_possible_suffix(name)
        name.sub(/_?runner$/i, '')
      end
    end
  end
end