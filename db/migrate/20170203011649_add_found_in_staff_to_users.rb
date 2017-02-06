class AddFoundInStaffToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :matching_staff_member_count, :integer
  end
end
