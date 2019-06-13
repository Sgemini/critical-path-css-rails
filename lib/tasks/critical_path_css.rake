require 'critical-path-css-rails'
require 'npm_commands'

namespace :critical_path_css do
  desc 'Run npm install for critical path css rails'
  task npm_install: :environment do
    NpmCommands.install
    NpmCommands.run_npm_install
  end

  desc 'Generate critical CSS for the routes defined'
  task generate: :npm_install do
    CriticalPathCss.generate_all
  end

  desc 'Clear all critical CSS from the cache'
  task clear_all: :npm_install do
    # Use the following for Redis cache implmentations
    CriticalPathCss.clear_matched('*')
    # Some other cache implementations may require the following syntax instead
    # CriticalPathCss.clear_matched(/.*/)
  end
end

# Rake::Task['assets:precompile'].enhance { Rake::Task['critical_path_css:generate'].invoke }
