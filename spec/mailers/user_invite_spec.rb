require "rails_helper"

RSpec.describe UserInviteMailer, type: :mailer do
  describe "notify" do
    let(:user) { create(:user) }
    let(:mail) { UserInviteMailer.notify(user) }

    it "renders the headers" do
      expect(mail.subject).to eq("You've been invited to Tcal")
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq(["tcal@tcal.me"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Use Tcal Now")
    end
  end

end
