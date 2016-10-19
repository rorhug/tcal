class CreateSyncAttempts < ActiveRecord::Migration[5.0]
  def change
    create_table :sync_attempts do |t|
      t.integer :user_id, index: true
      t.text :error_message
      t.integer :events_created, default: 0, null: false
      t.integer :events_deleted, default: 0, null: false
      t.datetime :started_at, null: false
      t.datetime :finished_at, index: true, null: false

      t.timestamps
    end
  end
end
