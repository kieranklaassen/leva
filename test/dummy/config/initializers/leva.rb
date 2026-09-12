# The dummy app inherits Leva's controllers from its own ApplicationController,
# the way a host puts its authentication in front of the engine.
Leva.configure do |config|
  config.parent_controller = "ApplicationController"
end
