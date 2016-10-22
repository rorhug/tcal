require "rails_helper"

RSpec.describe UserInviteMailer, type: :mailer do
  describe "notify" do
    let(:mail) { UserInviteMailer.notify }

    it "renders the headers" do
      expect(mail.subject).to eq("Notify")
      expect(mail.to).to eq(["to@example.org"])
      expect(mail.from).to eq(["from@example.com"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Hi")
    end
  end

end
