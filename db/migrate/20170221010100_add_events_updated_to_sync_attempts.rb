class AddEventsUpdatedToSyncAttempts < ActiveRecord::Migration[5.0]
  def change
    add_column :sync_attempts, :events_updated, :integer, default: 0, null: false
  end
end
