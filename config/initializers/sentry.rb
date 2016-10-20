Raven.configure do |config|
  config.sanitize_fields = Rails.application.config.filter_parameters.map(&:to_s)
end

Raven.configure do |config|
  config.dsn = Rails.application.secrets.sentry_dns_app_prod if Rails.env.production?
  config.environments = ['production']
end
