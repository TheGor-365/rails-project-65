# frozen_string_literal: true

class User < ApplicationRecord
  has_many :bulletins, dependent: :nullify
  has_many :favorites, dependent: :destroy
  has_many :conversations_as_buyer, class_name: 'Conversation', foreign_key: :buyer_id,
                                    inverse_of: :buyer, dependent: :destroy
  has_many :conversations_as_seller, class_name: 'Conversation', foreign_key: :seller_id,
                                     inverse_of: :seller, dependent: :destroy
  has_many :sent_messages, class_name: 'Message', foreign_key: :sender_id,
                           inverse_of: :sender, dependent: :destroy
  has_many :oauth_identities, dependent: :destroy

  def self.ransackable_attributes(_auth = nil)
    %w[email name id created_at updated_at]
  end

  def self.ransackable_associations(_auth = nil)
    []
  end
end
