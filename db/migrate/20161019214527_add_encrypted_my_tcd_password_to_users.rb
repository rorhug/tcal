class AddEncryptedMyTcdPasswordToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :encrypted_my_tcd_password, :text
    add_column :users, :encrypted_my_tcd_password_iv, :text
    remove_column :users, :my_tcd_password
  end
end
