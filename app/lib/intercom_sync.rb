require Rails.root.join("config/tcal_constants.rb")

class IntercomSync
  def initialize
    @client = Intercom::Client.new(token: Rails.application.secrets.intercom_pat)
  end

  def sync_users(user_q)
    user_q.in_groups_of(100, false) do |user_batch|
      @client.users.submit_bulk_job(create_items: user_batch.to_a.map(&:intercom_attributes))
    end
  end

  def sync_recently_changed_users
    sync_users(
      User.where(updated_at: (INTERCOM_SYNC_INTERVAL + 1.minute).ago..1.minute.from_now)
    )
  end
end
