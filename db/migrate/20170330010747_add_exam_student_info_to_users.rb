class AddExamStudentInfoToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :exam_page_student_number, :text
    add_column :users, :exam_page_student_name, :text
    add_column :users, :exam_page_student_course_year, :text
    add_column :users, :exam_page_course, :text
  end
end
