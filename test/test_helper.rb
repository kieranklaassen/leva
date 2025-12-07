# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require_relative "../test/dummy/config/environment"
require "vcr"

# Configure RubyLLM with test keys for VCR playback
RubyLLM.configure do |config|
  config.gemini_api_key = ENV.fetch("GEMINI_API_KEY", "test-gemini-key")
  config.openai_api_key = ENV.fetch("OPENAI_API_KEY", "test-openai-key")
  config.anthropic_api_key = ENV.fetch("ANTHROPIC_API_KEY", "test-anthropic-key")
end

VCR.configure do |config|
  config.cassette_library_dir = "test/vcr_cassettes"
  config.hook_into :faraday
  config.default_cassette_options = { record: :new_episodes }
  config.allow_http_connections_when_no_cassette = true
  # Filter sensitive API keys
  config.filter_sensitive_data("<OPENAI_API_KEY>") { ENV["OPENAI_API_KEY"] }
  config.filter_sensitive_data("<ANTHROPIC_API_KEY>") { ENV["ANTHROPIC_API_KEY"] }
  config.filter_sensitive_data("<GEMINI_API_KEY>") { ENV["GEMINI_API_KEY"] }
end

# Auto-wrap tests with VCR cassettes using Minitest's `name` method
# Include this module in test classes that make HTTP requests
module VcrTestHelper
  def setup
    super
    # Create cassette name from class and method: Leva::FooTest#test_bar -> leva/foo_test/test_bar
    cassette_name = self.class.name.underscore.tr("::", "/") + "/" + name
    VCR.insert_cassette(cassette_name)
  end

  def teardown
    VCR.eject_cassette
    super
  end
end

ActiveRecord::Migrator.migrations_paths = [ File.expand_path("../test/dummy/db/migrate", __dir__) ]
ActiveRecord::Migrator.migrations_paths << File.expand_path("../db/migrate", __dir__)
require "rails/test_help"

# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_paths=)
  ActiveSupport::TestCase.fixture_paths = [ File.expand_path("fixtures", __dir__) ]
  ActionDispatch::IntegrationTest.fixture_paths = ActiveSupport::TestCase.fixture_paths
  ActiveSupport::TestCase.file_fixture_path = File.expand_path("fixtures", __dir__) + "/files"
  ActiveSupport::TestCase.fixtures :all
end
