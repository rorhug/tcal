class AddDisappearedAtToStaffMembers < ActiveRecord::Migration[5.0]
  def change
    add_column :staff_members, :disappeared_at, :datetime
  end
end
