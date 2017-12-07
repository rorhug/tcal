class GlobalSetting < ApplicationRecord
  IDENTIFIERS = {
    "auto_sync"       => "Auto Sync",
    "invite_required" => "Invite Required",
    "login_enabled"   => "Login Enabled"
  }.freeze
  IDENTIFIER_KEYS = IDENTIFIERS.keys.freeze

  belongs_to :user
  validates :identifier, inclusion: IDENTIFIER_KEYS
  alias_attribute :value, :value_boolean

  def self.set(identifier, value, user)
    create(identifier: identifier, value: value, user: user)
  end

  def self.get(identifier)
    where(identifier: identifier).last || new(identifier: identifier)
  end

  def self.get_all_latest
    last_of_each = GlobalSetting.select("DISTINCT ON(identifier) *").order("identifier, id DESC").to_a
    last_of_each + (IDENTIFIER_KEYS - last_of_each.map(&:identifier)).map { |identifier| new(identifier: identifier) }
  end
end
