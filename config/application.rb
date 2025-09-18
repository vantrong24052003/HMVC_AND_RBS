# frozen_string_literal: true

require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Elearning
  class Application < Rails::Application
    config.load_defaults 8.0
    config.autoload_lib(ignore: %w[assets tasks])
    config.generators do |g|
      g.orm :active_record, primary_key_type: :uuid
    end

    config.active_job.queue_adapter = :sidekiq

    config.active_record.primary_key = :uuid
    #
    config.time_zone = "Asia/Ho_Chi_Minh"
    config.active_record.default_timezone = :utc
    config.active_record.time_zone_aware_attributes = true
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
