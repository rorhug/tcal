class SyncAttempt < ApplicationRecord
  scope :for_feed, -> { order(finished_at: :desc).limit(5) }

  def successful?
    !error_message?
  end

  def duration
    finished_at - started_at
  end
end
