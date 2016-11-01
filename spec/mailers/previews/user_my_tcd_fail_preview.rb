# Preview all emails at http://localhost:3000/rails/mailers/my_tcd_fail
class UserMyTcdFailPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/my_tcd_fail/notify
  def notify
    UserMyTcdFailMailer.notify(
      User.new(email: "ar8@tcd1.ie"), requires_password_change: false
    )
  end

end
