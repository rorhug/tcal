class UserEmailNullFalse < ActiveRecord::Migration[5.0]
  def change
    reversible do |dir|
      dir.up do
        change_column :users, :email, :text, null: false
      end
      dir.down do
        change_column :users, :email, :text, null: true
      end
    end
  end
end
