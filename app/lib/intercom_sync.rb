class IntercomSync
  def initialize
    @client = Intercom::Client.new(token: Rails.application.secrets.intercom_pat)
  end

  def sync_users(user_q)
    count_synced = 0
    user_q.in_groups_of(100, false) do |user_batch_q|
      user_array = user_batch_q.to_a
      @client.users.submit_bulk_job(create_items: user_array.map(&:intercom_attributes))
      count_synced += user_array.size
    end
    Rails.logger.info("intercom_sync_log users_sycned=#{count_synced}")
    count_synced
  end

  def sync_recently_changed_users
    sync_users(
      User.where(updated_at: (INTERCOM_SYNC_INTERVAL + 1.minute).ago..1.minute.from_now)
    )
  end

  def sync_all_users
    count_synced = 0
    User.all.find_in_batches(batch_size: 80) do |users|
      @client.users.submit_bulk_job(create_items: users.map(&:intercom_attributes))
      count_synced += users.size
      puts "users_sycned: #{count_synced}"
      sleep 10
    end
    Rails.logger.info("intercom_sync_log users_sycned=#{count_synced}")
    count_synced
  end

end
