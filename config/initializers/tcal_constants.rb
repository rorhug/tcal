AUTO_SYNC_SETTINGS = {
  user_interval: 23.hours,
  cron_interval: 1.minutes
}.freeze

INTERCOM_SYNC_INTERVAL = 5.minutes.freeze

BASE_INTERCOM_SETTINGS = {
  app_id: Rails.application.secrets.intercom_app_id,
  custom_launcher_selector: ".intercom_help"
}.freeze
