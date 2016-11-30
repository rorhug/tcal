Rails.application.config.before_configuration do
  Raven.configuration.silence_ready = true
end

Raven.configure do |config|
  config.sanitize_fields = Rails.application.config.filter_parameters.map(&:to_s)
  config.dsn = Rails.application.secrets.sentry_dns_app_prod if Rails.env.production?
  config.environments = ['production']
end
