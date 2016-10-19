class User < ApplicationRecord
  # user https://github.com/attr-encrypted/attr_encrypted for tcd details

  EMAIL_DOMAINS = ENV['GOOGLE_EMAIL_DOMAIN_CSV'].split(',')
  MY_TCD_LOGIN_COLUMNS = %w(
    my_tcd_username
    my_tcd_password
  )

  before_save :ensure_no_my_tcd_changes!
  has_many :sync_attempts

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

  def enqueue_sync
    # raise if job currently in queue
    ActiveRecord::Base.transaction do
      SyncTimetable.enqueue(id)
    end
  end

  def do_the_feckin_thing!
    started_at = Time.now
    counts = {}
    sync_exception = nil
    begin
      ensure_valid_access_token!

      scraper = MyTcd::TimetableScraper.new(self)
      events_from_tcd = scraper.fetch_events

      gcal = GoogleCalendarSync.new(self)
      counts = gcal.sync_events!(events_from_tcd)
    rescue Exception => e
      sync_exception = e
      # sentry e
    ensure
      sync_attempts.create!({
        started_at: started_at,
        finished_at: Time.now,
        error_message: sync_exception && "Error syncing calendar"
      }.merge(counts))
    end
  end

  def synced_lots_recently?
    return @synced_lots_recently if defined?(@synced_lots_recently)
    @synced_lots_recently = sync_attempts.where(
      created_at: 1.hour.ago..1.minute.since
    ).count >= GoogleCalendarSync::MAX_SYNCS_PER_HOUR
  end

  def ongoing_sync_job
    return @ongoing_sync_job if defined?(@ongoing_sync_job)
    @ongoing_sync_job = QueJob.where(job_class: "SyncTimetable").where("args->>0 = ?", id.to_s).last
  end

  def sync_blocked_reason
    if ongoing_sync_job
      "There is already a sync in progress!"
    elsif Rails.env.development?
      nil
    elsif synced_lots_recently?
      "You may not sync more than #{GoogleCalendarSync::MAX_SYNCS_PER_HOUR} times per hour."
    end
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
    # true
  end
end
