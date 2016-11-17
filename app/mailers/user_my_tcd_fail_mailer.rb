class UserMyTcdFailMailer < ApplicationMailer
  # send a signup email to the user, pass in the user object that   contains the user's email address
  def notify(user, options={})
    @user = user
    @subject = "Quickly Fix your Calendar Sync"
    @requires_password_change = options[:requires_password_change]

    @call_to_action = {
      name: "Fix Sync",
      description: "Click here to re-connect MyTCD with Tcal.",
      url: user_setup_step_url(step: "my_tcd", utm_source: "email", utm_campaign: "mytcdfail")
    }

    mail(
      to: @user.email,
      subject: @subject
    )
  end
end
