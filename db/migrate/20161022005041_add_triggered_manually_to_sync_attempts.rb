class AddTriggeredManuallyToSyncAttempts < ActiveRecord::Migration[5.0]
  def change
    add_column :sync_attempts, :triggered_manually, :boolean, null: false, default: true
  end
end
