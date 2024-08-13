# frozen_string_literal: true

module Leva
  module Generators
    class EvalGenerator < Rails::Generators::NamedBase
      source_root File.expand_path('templates', __dir__)

      def create_eval_file
        template 'eval.rb.erb', File.join('app/evals', class_path, "#{file_name}_eval.rb")
      end

      private

      def file_name
        @_file_name ||= remove_possible_suffix(super)
      end

      def remove_possible_suffix(name)
        name.sub(/_?eval$/i, '')
      end
    end
  end
end