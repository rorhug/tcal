class ApplicationMailer < ActionMailer::Base
  default from: "Tcal <tcal@tcal.me>", "X-MSYS-API" => {options: {open_tracking: true, click_tracking: true}}.to_json
  layout 'mailer'
end
