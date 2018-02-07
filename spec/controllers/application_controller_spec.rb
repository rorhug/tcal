require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  let(:user) { create(:rory) }

  describe "accessed_from_tcd_network?" do
    it "returns true when accessed from tcd" do
      allow_any_instance_of(ActionDispatch::Request).to receive(:remote_ip).and_return("134.226.12.152")
      expect(@controller.send(:accessed_from_tcd_network?)).to be_truthy
    end

    it "returns false when accessed outside tcd" do
      allow_any_instance_of(ActionDispatch::Request).to receive(:remote_ip).and_return("201.151.88.15")
      expect(@controller.send(:accessed_from_tcd_network?)).to be_falsey
    end
  end

  describe "login_available?" do
    it "returns true when setting is on and outside tcd" do
      allow_any_instance_of(ActionDispatch::Request).to receive(:remote_ip).and_return("201.151.88.15")
      GlobalSetting.set("login_enabled", true, user)
      expect(@controller.send(:login_available?)).to be_truthy
    end

    it "returns false when setting is off and outside tcd" do
      allow_any_instance_of(ActionDispatch::Request).to receive(:remote_ip).and_return("201.151.88.15")
      GlobalSetting.set("login_enabled", false, user)
      expect(@controller.send(:login_available?)).to be_falsey
    end
  end
end
