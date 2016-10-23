class QueJob < ActiveRecord::Base
  def self.for_job(job_class)
    where(job_class: job_class)
  end

  def self.for_users(users)
    q = QueJob.all
    count = users.count
    if count > 1
      ids = users.is_a?(User::ActiveRecord_Relation) ? users.pluck(:id) : users.map(&:id)
      q = q.where("args->>0 IN (?)", ids.map(&:to_s))
    elsif count == 1
      q = q.where("args->>0 = ?", users.first.id.to_s)
    end
    q
  end

  def self.for_user(user, job_class: nil)
    q = QueJob.all
    if user.is_a?(User)
      q = q.where("args->>0 = ?", user.id.to_s)
    elsif user.is_a?(Fixnum) || user.is_a?(String)
      q = q.where("args->>0 = ?", user.to_s)
    end
    q
  end
end
