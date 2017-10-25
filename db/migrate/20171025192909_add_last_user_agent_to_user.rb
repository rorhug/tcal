class AddLastUserAgentToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :last_user_agent, :text
    add_column :users, :last_login_at, :datetime
  end
end
