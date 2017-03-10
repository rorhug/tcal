require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { create(:user) }
  let(:staff_member) { create(:staff_member) }

  describe "staff member blocking" do
    it "stays as nil if new" do
      expect(user.blocked_as_staff_member).to be_nil
    end

    it "is true if a staff member matches" do
      user.update_attributes(email: staff_member.email)
      expect(user.blocked_as_staff_member).to be(true)
    end

    it "stays as false regardless of match" do
      user.update_attributes(blocked_as_staff_member: false)
      user.update_attributes(email: staff_member.email)
      expect(user.blocked_as_staff_member).to be(false)
    end

    it "stays as true regardless of lack of match" do
      user.update_attributes(blocked_as_staff_member: true)
      user.update_attributes(email: "abc@tcd.ie")
      expect(user.blocked_as_staff_member).to be(true)
    end
  end
end
