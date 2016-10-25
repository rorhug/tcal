class UserInviteMailer < ApplicationMailer
  # send a signup email to the user, pass in the user object that   contains the user's email address
  def notify(user)
    @user = user
    @inviter = user.invited_by
    @inviter = nil if @inviter && @inviter.is_admin
    @subject = "Invite to Tcal#{ " from #{@inviter.my_tcd_username_estimate}" if @inviter }"
    mail(
      to: @user.email,
      subject: @subject
    )
  end
end
