class AddInvitesToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :invited_by_user_id, :integer, index: true
    add_column :users, :joined_at, :datetime
    add_column :users, :email, :text
    add_column :users, :auto_sync_enabled, :boolean, null: false, default: true
    add_column :users, :is_admin, :boolean, null: false, default: false

    add_index :users, :google_uid, unique: true
    add_index :users, :email, unique: true

    reversible do |dir|
      dir.up do
        change_column :users, :google_uid, :text, null: true
      end
      dir.down do
        change_column :users, :google_uid, :text, null: false
      end
    end
  end
end
