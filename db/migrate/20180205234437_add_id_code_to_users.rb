class AddIdCodeToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :id_code, :text
    add_index :users, :id_code, unique: true
  end
end
