class ChangeStaffEmailToCitext < ActiveRecord::Migration[5.0]
  def up
    enable_extension :citext
    change_column :staff_members, :email, :citext
    add_index :staff_members, :email
  end

  def down
    disable_extension :citext
    change_column :staff_members, :email, :text
    drop_index :staff_members, :email
  end
end
