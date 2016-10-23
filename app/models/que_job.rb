class QueJob < ActiveRecord::Base
  def self.for_users(users, job_class: nil)
    q = QueJob.all

    elsif users.count > 1
      q = q.where("args->>0 IN (?)", users.pluck(:id))
    elsif users.count == 1
      q = q.where("args->>0 = ?", users.first.id)
    end

    if job_class
      q = .where(job_class: "SyncTimetable")
  end

  def self.for_user(user, job_class: nil)
    if users.is_a?(User)
      q = q.where("args->>0 = ?", users.id)
    elsif users.is_a?(Fixnum)
      q = q.where("args->>0 = ?", users)
    User::ActiveRecord_Relation
  end
end
