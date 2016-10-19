Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
    Rails.application.secrets.google_client_id,
    Rails.application.secrets.google_client_secret,
    hd: "tcd.ie",
    access_type: "offline",
    scope: "profile,email,calendar,calendar.readonly"
end
