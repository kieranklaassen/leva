namespace :leva do
  desc "Build Tailwind CSS for Leva engine (via cssbundling)"
  task :build_css do
    require 'fileutils'

    engine_root = Leva::Engine.root
    builds_dir = engine_root.join("app", "assets", "builds", "leva")
    FileUtils.mkdir_p(builds_dir)

    # Prefer npm-based build (cssbundling), fallback to tailwindcss-rails binary if npm not available
    built = false
    Dir.chdir(engine_root) do
      if system("npm run --silent build:css")
        built = true
      end
    end

    unless built
      input_file = engine_root.join("app/assets/stylesheets/leva/application.tailwind.css")
      output_file = builds_dir.join("application.tailwind.css")
      config_file = engine_root.join("config/tailwind.config.js")
      system("tailwindcss -i #{input_file} -o #{output_file} --config #{config_file}")
    end
  end
  
  desc "Watch and rebuild Tailwind CSS for Leva engine"
  task :watch_css do
    require 'fileutils'
    
    # Use engine root instead of Rails.root to work from engine directory
    engine_root = Leva::Engine.root
    builds_dir = engine_root.join("app", "assets", "builds", "leva")
    FileUtils.mkdir_p(builds_dir)
    
    # Prefer npm-based watch (cssbundling), fallback to tailwindcss-rails binary if npm not available
    Dir.chdir(engine_root) do
      system("npm run watch:css") || begin
        input_file = engine_root.join("app/assets/stylesheets/leva/application.tailwind.css")
        output_file = builds_dir.join("application.tailwind.css")
        config_file = engine_root.join("config/tailwind.config.js")
        system("tailwindcss -i #{input_file} -o #{output_file} --config #{config_file} --watch")
      end
    end
  end

  desc "Build JavaScript for Leva engine (via jsbundling)"
  task :build_js do
    engine_root = Leva::Engine.root
    Dir.chdir(engine_root) do
      system("npm run --silent build:js")
    end
  end
end

# Hook into Rails asset pipeline tasks for automatic building
%w[assets:precompile assets:clean].each do |task_name|
  if Rake::Task.task_defined?(task_name)
    Rake::Task[task_name].enhance(["leva:build_css", "leva:build_js"])
  end
end

# Also hook into test preparation
if Rake::Task.task_defined?("test:prepare")
  Rake::Task["test:prepare"].enhance(["leva:build_css"])
end
