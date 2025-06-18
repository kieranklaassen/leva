namespace :leva do
  desc "Build Tailwind CSS for Leva engine"
  task :build_css do
    require 'fileutils'
    
    # Use engine root instead of Rails.root to work from engine directory
    engine_root = Leva::Engine.root
    builds_dir = engine_root.join("app", "assets", "builds", "leva")
    FileUtils.mkdir_p(builds_dir)
    
    # Build the CSS
    input_file = engine_root.join("app/assets/stylesheets/leva/application.tailwind.css")
    output_file = builds_dir.join("application.tailwind.css")
    config_file = engine_root.join("config/tailwind.config.js")
    
    system("tailwindcss -i #{input_file} -o #{output_file} --config #{config_file}")
  end
  
  desc "Watch and rebuild Tailwind CSS for Leva engine"
  task :watch_css do
    require 'fileutils'
    
    # Use engine root instead of Rails.root to work from engine directory
    engine_root = Leva::Engine.root
    builds_dir = engine_root.join("app", "assets", "builds", "leva")
    FileUtils.mkdir_p(builds_dir)
    
    # Watch and build the CSS
    input_file = engine_root.join("app/assets/stylesheets/leva/application.tailwind.css")
    output_file = builds_dir.join("application.tailwind.css")
    config_file = engine_root.join("config/tailwind.config.js")
    
    system("tailwindcss -i #{input_file} -o #{output_file} --config #{config_file} --watch")
  end
end

# Hook into Rails asset pipeline tasks for automatic building
%w[assets:precompile assets:clean].each do |task_name|
  if Rake::Task.task_defined?(task_name)
    Rake::Task[task_name].enhance(["leva:build_css"])
  end
end

# Also hook into test preparation
if Rake::Task.task_defined?("test:prepare")
  Rake::Task["test:prepare"].enhance(["leva:build_css"])
end
