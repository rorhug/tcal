class QueJob < ActiveRecord::Base
  def self.for_job(job_class)
    where(job_class: job_class)
  end

  def self.for_users(users)
    q = QueJob.all
    if users.count > 1
      ids = users.is_a?(User::ActiveRecord_Relation) ? users.pluck(:id) : users.map(&:id)
      q = q.where("args->>0 IN (?)", )
    elsif users.count == 1
      q = q.where("args->>0 = ?", users.first.id)
    end
    q
  end

  def self.for_user(user, job_class: nil)
    q = QueJob.all
    if users.is_a?(User)
      q = q.where("args->>0 = ?", users.id)
    elsif users.is_a?(Fixnum)
      q = q.where("args->>0 = ?", users)
    end
    q
  end
end
