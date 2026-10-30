# frozen_string_literal: true

class Message < ApplicationRecord
  belongs_to :conversation, touch: true
  belongs_to :sender, class_name: 'User'

  before_validation :normalize_body

  validates :body, presence: true, length: { maximum: 2000 }
  validate :participant_sender

  private

  def normalize_body
    self.body = body.to_s.strip
  end

  def participant_sender
    return unless conversation && sender

    errors.add(:sender, 'не участвует в переписке') unless conversation.participant?(sender)
  end
end
