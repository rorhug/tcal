class CreateUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :users do |t|
      t.text :google_uid, unique: true, null: false
      t.jsonb :auth_hash, null: false, default: {}

      t.text :oauth_refresh_token
      t.text :oauth_access_token
      t.datetime :oauth_access_token_expires_at

      t.text :my_tcd_username
      t.text :my_tcd_password
      t.datetime :my_tcd_last_attempt_at
      t.boolean :my_tcd_login_success, default: nil

      t.timestamps
    end
  end
end
