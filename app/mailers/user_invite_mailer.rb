class UserInviteMailer < ApplicationMailer
  # send a signup email to the user, pass in the user object that   contains the user's email address
  def notify(user)
    @user = user
    @subject = user.you_were_invited_message
    @is_mail = true
    mail(
      to: @user.email,
      subject: @subject
    )
    user.update_attributes(invite_email_at: Time.now) if user.id?
  end
end
