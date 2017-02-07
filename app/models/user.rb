class User < ApplicationRecord
  # user https://github.com/attr-encrypted/attr_encrypted for tcd details

  MY_TCD_LOGIN_COLUMNS = %w(
    my_tcd_username
    my_tcd_password
  ).freeze
  MAX_INVITES = 3.freeze
  SAMPLE_EMAILS = ["trumpd4@tcd.ie", "clintonh@tcd.ie"].freeze
  AUTO_SYNC_IN_WORDS = "#{ AUTO_SYNC_SETTINGS[:user_interval] / 1.hour } hours".freeze

  attr_encrypted :my_tcd_password, key: Rails.application.secrets.encrypted_my_tcd_password_key

  before_save :tcd_login_details_changed!

  has_many :sync_attempts
  has_many :invitees, class_name: "User", foreign_key: :invited_by_user_id
  belongs_to :invited_by, class_name: "User", foreign_key: :invited_by_user_id

  validates :email, format: /@/

  def tcd_login_details_changed!
    if (changed & MY_TCD_LOGIN_COLUMNS).any?
      # if login details change, invalidate the success check
      self.my_tcd_login_success = nil

      # strip the username and remove
      if my_tcd_username.is_a?(String)
        self.my_tcd_username = my_tcd_username.strip.gsub(/@tcd\.ie\z/, "")
      end
    end
  end

  def set_joined_at_if_invited!
    enable_account.save! if !joined_at? && invited_by_user_id && invited_by
  end

  def tcd_email?
    email =~ /\A[^@]+@tcd\.ie\z/ && (auth_hash['extra'] ? auth_hash['extra']['raw_info']['hd'] : true)
  end

  def my_tcd_username_estimate
    email.split("@").first
  end

  def image_url
    if auth_hash.any?
      auth_hash["info"]["image"]
    else
      "https://lh3.googleusercontent.com/-XdUIqdMkCWA/AAAAAAAAAAI/AAAAAAAAAAA/4252rscbv5M/photo.jpg"
    end
  end

  def google_name
    auth_hash["info"]["name"] if auth_hash.any?
  end

  def name_backwards
    "#{auth_hash["info"]["last_name"]} #{auth_hash["info"]["first_name"]}" if auth_hash.any?
  end

  def you_were_invited_message
    return @you_were_invited_message if defined?(@you_were_invited_message)
    if invited_by && !invited_by.is_admin?
      "#{invited_by.display_name} invited you to Tcal"
    else
      "You've been invited to Tcal"
    end
  end

  def display_name
    if google_name.is_a?(String) && google_name.size > 3
      google_name
    else
      my_tcd_username_estimate
    end
  end

  def should_show_invite_prompt?
    last_sync_success = sync_attempts.last && !sync_attempts.last.error_message?
    joined_at? && my_tcd_login_success? && (invites_left == User::MAX_INVITES) && last_sync_success
  end

  def google_calendar_url
    "https://calendar.google.com/calendar?authuser=#{email}"
  end

  def admin_panel_url
    "https://www.tcal.me/admin/users/#{id}"
  end

  def for_raven
    slice(*%w(id email google_name my_tcd_username my_tcd_login_success admin_panel_url))
  end

  def intercom_attributes(for_js: false)
    attrs = {
      email: email,
      user_id: id,
      name: google_name,
      created_at: created_at && created_at.to_i
    }

    attrs[for_js ? :custom_data : :custom_attributes] = {
      my_tcd_username: my_tcd_username,
      my_tcd_login_success: my_tcd_login_success,
      joined_at: joined_at && joined_at.to_i,
      google_uid: google_uid,
      invited_by_user_id: invited_by_user_id,
      auto_sync_enabled: auto_sync_enabled,
      is_admin: is_admin,
      invite_email_at: invite_email_at && invite_email_at.to_i,
      admin_panel_url: admin_panel_url
    }

    attrs
  end

  def intercom_settings
    intercom_attributes(for_js: true).merge({
      app_id: Rails.application.secrets.intercom_app_id,
      custom_launcher_selector: "#intercom_help"
    })
  end

  def for_front_end
    slice(*%w(id email google_name image_url)).merge({
      admin_path: "/admin/users/#{id}"
    })
  end

  def gcs
    return @gcs if defined?(@gcs)
    @gcs = GoogleCalendarSync.new(self)
  end

  def ts
    return @ts if defined?(@ts)
    @ts = MyTcd::TimetableScraper.new(self)
  end

  def self.from_omniauth(auth_hash)
    # fail SecurityError unless EMAIL_DOMAINS.include?(auth_hash['extra']['raw_info']['hd'])

    # already has account
    user = where(google_uid: auth_hash['uid']).first
    # redeeming a pending invite
    user ||= where(google_uid: nil, email: auth_hash["info"]["email"]).where.not(invited_by_user_id: nil).first

    # create them new, uninvited. Won't be able to use as joined_at isn't set
    # filters above will pass on return visit as 1. needs joined_at, 2. needs an invited_by_user_id
    user ||= new

    # add the google uid if not there (new account/invite redeem)
    user.google_uid ||= auth_hash['uid']
    # assign email
    user.email = auth_hash["info"]["email"]

    # add joined_at timestamp added if user is invited
    if user.invited_by_user_id? && !user.joined_at?
      user.enable_account
    end

    # oauth tokens
    refresh_token = auth_hash["credentials"]["refresh_token"]
    if refresh_token.is_a?(String) && refresh_token.length > 10
      user.oauth_refresh_token = auth_hash["credentials"]["refresh_token"]
    end

    new_access_token, expires_at = auth_hash["credentials"]["token"], auth_hash["credentials"]["expires_at"]
    if new_access_token.is_a?(String) && new_access_token.length > 10 && expires_at
      user.oauth_access_token = new_access_token
      user.oauth_access_token_expires_at = Time.at(expires_at)
    end
    user.auth_hash = auth_hash

    user.save!
    user
  end

  def enqueue_sync(triggered_manually: true, force: false)
    raise "Sync job already queued for user" if !force && ongoing_sync_job
    ActiveRecord::Base.transaction do
      SyncTimetable.enqueue(id, triggered_manually)
    end
  end

  def self.ready_for_sync
    where(
      auto_sync_enabled: true,
      my_tcd_login_success: true,
    ).where.not(
      joined_at: nil
    )
  end

  def self.enqueue_auto_syncs(users_relation=nil) # TODO take a relation of users
    # (3*60*60)/(5*60)
    user_interval = AUTO_SYNC_SETTINGS[:user_interval]
    cron_interval = AUTO_SYNC_SETTINGS[:cron_interval]
    denominator = user_interval / cron_interval
    numerator = (Time.now.to_i % user_interval) / cron_interval

    users_relation ||= ready_for_sync.where("MOD(id, ?) = ?", denominator, numerator)
    users = users_relation.to_a

    return if users.empty?

    # AnD there isn't a current sync job running...
    current_jobs = QueJob.for_job("SyncTimetable").for_users(users).to_a

    count_queued = 0
    users.each do |user|
      unless current_jobs.find { |job| job.args[0] == user.id }
        user.enqueue_sync(
          triggered_manually: false,
          force: true # i.e. don't bother checking if a job isn't running (we check using current_jobs)
        )
        count_queued += 1
      end
    end

    count_queued
  end

  def do_the_feckin_thing!(triggered_manually: true, force_dev: false)
    started_at = Time.now
    counts = {}
    sync_exception = nil
    begin
      scrape_result = if Rails.env.production? || force_dev
        scraper = MyTcd::TimetableScraper.new(self, silence_my_tcd_fail_email: triggered_manually)
        scraper.fetch_events
      else
        { events: [], status: :success }
      end

      counts = if scrape_result[:status] == :success && scrape_result[:events].any?
        gcs.sync_events!(scrape_result[:events])
      else
        { events_created: 0, events_deleted: 0 }
      end
    rescue Exception => sync_exception
      unless sync_exception.is_a?(MyTcd::MyTcdError) # already captured to sentry by my_tcd.rb
        Raven.capture_exception(sync_exception, user: for_raven)
      end
    ensure
      sync_attempts.create!({
        started_at: started_at,
        finished_at: Time.now,
        error_message: sync_exception && (sync_exception.message || "Error syncing calendar"),
        triggered_manually: triggered_manually
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
    # return @ongoing_sync_job if defined?(@ongoing_sync_job) needs to be up to date
    QueJob.for_job("SyncTimetable").for_user(self).first
  end

  def sync_blocked_reason
    if ongoing_sync_job
      "There is already a sync in progress!"
    elsif !my_tcd_login_success? # Never reaches here, controller blocks with user_setup_complete?
      "Your MyTCD settings need to be updated."
    elsif Rails.env.development?
      nil
    elsif synced_lots_recently?
      "You may not sync more than #{GoogleCalendarSync::MAX_SYNCS_PER_HOUR} times per hour."
    end
  end

  def refresh_access_token!
    oauth_client = OAuth2::Client.new(
      Rails.application.secrets.google_client_id,
      Rails.application.secrets.google_client_secret,
      site: Rails.env.production? ? "https://www.tcal.me" : "http://tcal.dev",
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

  def invites_left
    if is_admin?
      1
    else
      left = User::MAX_INVITES - invitees.count
      left > 0 ? left : 0
    end
  end

  def has_spare_invites?
    invites_left != 0
  end

  def enable_account
    self.joined_at ||= Time.now
    self
  end

  def enqueue_invite_email(force_dev: false)
    if Rails.env.production? || force_dev
      ActiveRecord::Base.transaction do
        UserInviteEmailJob.enqueue(id)
      end
    end
  end

  def que_mail(mailer_class, options={})
    if Rails.env.production? || options[:force_dev]
      ActiveRecord::Base.transaction do
        EmailUserJob.enqueue(id, mailer_class.to_s, options)
      end
    end
  end

  def self.uninvited
    where(invited_by_user_id: nil, joined_at: nil).where.not(google_uid: nil)
  end
end
