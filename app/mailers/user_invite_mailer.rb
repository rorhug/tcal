class UserInviteMailer < ApplicationMailer
  # send a signup email to the user, pass in the user object that   contains the user's email address
  def notify(user)
    @user = user
    @inviter = user.invited_by
    @subject = "Invite to Tcal from #{@inviter.email}"
    mail(
      to: @user.email,
      from: "Tcal <tcdcreator@gmail.com>",
      subject: @subject
    )
  end
end
