class ChangeUserIsStaffTracking < ActiveRecord::Migration[5.0]
  def change
    remove_column :users, :matching_staff_member_count, :integer
    add_column :users, :blocked_as_staff_member, :boolean
  end
end
