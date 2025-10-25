# frozen_string_literal: true

# Custom tasks for Vite assets (Rails 8 + Vite)
# Disable Sprockets tasks that are not needed with Vite

namespace :deploy do
  namespace :assets do
    # Disable Sprockets manifest backup/restore for Vite
    Rake::Task["deploy:assets:backup_manifest"].clear_actions
    Rake::Task["deploy:assets:restore_manifest"].clear_actions

    desc "Vite assets are handled by yarn build during precompile"
    task :backup_manifest do
      puts "Skipping Sprockets manifest backup (using Vite)"
    end

    task :restore_manifest do
      puts "Skipping Sprockets manifest restore (using Vite)"
    end
  end
end
