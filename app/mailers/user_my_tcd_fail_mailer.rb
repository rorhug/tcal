class UserMyTcdFailMailer < ApplicationMailer
  # send a signup email to the user, pass in the user object that   contains the user's email address
  def notify(user, options={})
    @user = user
    @subject = "Quickly Fix your Calendar Sync"
    @requires_password_change = options[:requires_password_change]
    mail(
      to: @user.email,
      subject: @subject
    )
  end
end
