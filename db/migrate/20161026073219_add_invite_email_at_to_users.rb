class AddInviteEmailAtToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :invite_email_at, :datetime
  end
end
