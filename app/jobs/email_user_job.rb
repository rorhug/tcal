class EmailUserJob < Que::Job
  MAILERS = [
    "UserInviteMailer",
    "UserMyTcdFailMailer"
  ].freeze

  # Default settings for this job. These are optional - without them, jobs
  # will default to priority 100 and run immediately.
  @priority = 10 # send mail before syncs
  # @run_at = proc { 1.minute.from_now }

  def run(user_id, mailer_class_string, options={})
    # Do stuff.
    ActiveRecord::Base.transaction do
      begin
        @user = User.find(user_id)
        raise NameError, "Invalid mailer class for EmailUserJob" unless MAILERS.include?(mailer_class_string)
        mailer_class = mailer_class_string.constantize

        mailer_class.notify(@user, options).deliver

      # rescue ActiveRecord::RecordNotFound, NameError => e # if the user isn't found or the mailer class is invalid
      rescue Exception => mailer_error
        Raven.capture_exception(mailer_error, user: @user && @user.for_raven)
      ensure
        # It's best to destroy the job in the same transaction as any other
        # changes you make. Que will destroy the job for you after the run
        # method if you don't do it yourself, but if your job writes to the
        # DB but doesn't destroy the job in the same transaction, it's
        # possible that the job could be repeated in the event of a crash.
        destroy
      end
    end
  end

end
