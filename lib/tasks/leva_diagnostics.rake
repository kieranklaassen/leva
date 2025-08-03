namespace :leva do
  desc "Print diagnostics for Leva engine asset pipeline integration"
  task diagnostics: :environment do
    puts "Rails env: #{Rails.env}"
    puts "Sprockets present: #{defined?(::Sprockets).present?}"
    puts "Propshaft present: #{defined?(::Propshaft).present?}"
    puts "Assets compile? #{Rails.application.config.assets.compile.inspect}"
    puts
    puts "Asset load paths:"
    Array(Rails.application.config.assets.paths).each { |p| puts "  - #{p}" }
    puts
    puts "Precompile list includes:"
    Array(Rails.application.config.assets.precompile).each { |e| puts "  - #{e.inspect}" }
    puts
    logicals = %w[leva_manifest.js leva/application.tailwind.css leva/application.js]
    logicals.each do |logical|
      env_hit = begin
        !!Rails.application.assets&.find_asset(logical)
      rescue => e
        false
      end

      manifest = Rails.application.assets_manifest rescue nil
      manifest_keys = manifest&.assets&.keys || []
      files = manifest&.files || {}
      manifest_hit = manifest_keys.include?(logical) || files.values.any? { |v| v['logical_path'] == logical }

      puts "Asset: #{logical}"
      puts "  - in Sprockets env: #{env_hit}"
      puts "  - in manifest: #{manifest_hit}"
    end
  end
end

