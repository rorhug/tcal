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

    config.time_zone = 'Dublin'

    $IS_QUE = $PROGRAM_NAME.include?("que")
    if $IS_QUE
      config.logger = Logger.new("#{Rails.root}/log/que.log")
    end

    $MAIN_SHLOGAN = "Your TCD Timetable in Google Calendar".freeze
    $MAIN_DESCRIPTION = "Tcal makes your timetable available in Google Calendar. Know what you have now and where, without even unlocking your Android or iPhone."
  end
end
