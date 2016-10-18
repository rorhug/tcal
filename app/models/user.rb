class User < ApplicationRecord
  # user https://github.com/attr-encrypted/attr_encrypted for tcd details

  EMAIL_DOMAINS = ENV['GOOGLE_EMAIL_DOMAIN_CSV'].split(',')
  MY_TCD_LOGIN_COLUMNS = %w(
    my_tcd_username
    my_tcd_password
  )

  before_save :ensure_no_my_tcd_changes!

  def ensure_no_my_tcd_changes!
    # if login details change, invalidate the success check
    self.my_tcd_login_success = nil if (changed & MY_TCD_LOGIN_COLUMNS).any?
  end

  def email
    auth_hash["info"]["email"]
  end

  def image_url
    auth_hash["info"]["image"]
  end

  def name
    auth_hash["info"]["name"]
  end

  def self.from_omniauth(auth_hash)
    fail SecurityError unless EMAIL_DOMAINS.include?(auth_hash['extra']['raw_info']['hd'])
    user = find_or_initialize_by(google_uid: auth_hash['uid'])

    user.auth_hash = auth_hash
    user.oauth_refresh_token = auth_hash["credentials"]["refresh_token"] if auth_hash["credentials"]["refresh_token"].present?
    user.oauth_access_token = auth_hash["credentials"]["token"] if auth_hash["credentials"]["token"].present?
    user.oauth_access_token_expires_at = Time.at(auth_hash["credentials"]["expires_at"])

    user.save!
    user
  end

  def refresh_access_token!
    oauth_client = OAuth2::Client.new(
      ENV["GOOGLE_CLIENT_ID"],
      ENV["GOOGLE_CLIENT_SECRET"],
      site: "https://tcal.dev",
      token_url: "https://accounts.google.com/o/oauth2/token",
      authorize_url: "https://accounts.google.com/o/oauth2/auth"
    )
    access_token = OAuth2::AccessToken.from_hash(
      oauth_client,
      refresh_token: oauth_refresh_token
    )

    access_token = access_token.refresh!
    self.oauth_access_token = access_token.token
    self.oauth_access_token_expires_at = Time.at(access_token.expires_at).utc

    save!
  end

  def ensure_valid_access_token!
    if oauth_access_token_expires_at.utc < (Time.now + 1.minute).utc
      refresh_access_token!
    else
      true
    end
  end
end
