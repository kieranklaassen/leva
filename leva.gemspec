require_relative "lib/leva/version"

Gem::Specification.new do |spec|
  spec.name        = "leva"
  spec.version     = Leva::VERSION
  spec.authors     = [ "Kieran Klaassen" ]
  spec.email       = [ "kieranklaassen@gmail.com" ]
  spec.homepage    = "https://github.com/kieranklaassen/leva"
  spec.summary     = "Flexible Evaluation Framework for Language Models in Rails"
  spec.description = "Leva is a Ruby on Rails framework for evaluating Language Models (LLMs) using ActiveRecord datasets. It provides a flexible structure for creating experiments, managing datasets, and implementing various evaluation logic."
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/kieranklaassen/leva"
  spec.metadata["changelog_uri"] = "https://github.com/kieranklaassen/leva/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.2.0"
end
