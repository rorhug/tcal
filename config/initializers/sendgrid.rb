ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.smtp_settings = {
  user_name: Rails.application.secrets.sparkpost_smtp_username,
  password: Rails.application.secrets.sparkpost_smtp_password,
  domain: "tcal.me",
  address: "smtp.sparkpostmail.com",
  port: 587,
  authentication: :plain,
  enable_starttls_auto: true
}
