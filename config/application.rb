require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Tcal
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.active_record.schema_format = :sql

    $IS_QUE = $PROGRAM_NAME.include?("que")
    if $IS_QUE
      config.logger = Logger.new("#{Rails.root}/log/que.log")
    end
  end
end
