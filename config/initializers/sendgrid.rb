ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.smtp_settings = {
  user_name: Rails.application.secrets.sendgrid_smtp_username,
  password: Rails.application.secrets.sendgrid_smtp_password,
  domain: "tcal.me",
  address: 'smtp.sendgrid.net',
  port: 587,
  authentication: :plain,
  enable_starttls_auto: true
}
