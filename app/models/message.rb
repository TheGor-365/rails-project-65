# frozen_string_literal: true

class Message < ApplicationRecord
  belongs_to :conversation, touch: true
  belongs_to :sender, class_name: 'User'

  before_validation :normalize_body

  # Recipient-scoped query: a message is unread only for the other participant.
  # Comparing message ids avoids timestamp precision and race problems.
  scope :unread_for, lambda { |user|
    joins(:conversation)
      .where.not(sender_id: user.id)
      .where(<<~SQL.squish, id: user.id)
        ((conversations.buyer_id = :id AND
          messages.id > COALESCE(conversations.buyer_last_read_message_id, 0))
        OR
        (conversations.seller_id = :id AND
          messages.id > COALESCE(conversations.seller_last_read_message_id, 0)))
      SQL
  }

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
