class CreateStaffMembers < ActiveRecord::Migration[5.0]
  def change
    create_table :staff_members do |t|
      t.text :name
      t.text :email
      t.text :phone
      t.text :job_title
      t.text :location
      t.text :department
      t.text :sub_department
      t.text :row_html

      t.timestamps
    end
  end
end
