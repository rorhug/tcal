# Preview all emails at http://localhost:3000/rails/mailers/user_invite
class UserInvitePreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/user_invite/notify
  def notify
    UserInviteMailer.notify(
      User.new(email: "ar8@tcd.ie", invited_by: User.new(email: "b@tcd.ie"))
    )
  end

end
