class ApplicationMailer < ActionMailer::Base
  default from: "Tcal <tcal@email-notifications.tcal.me>"
  layout 'mailer'
end
