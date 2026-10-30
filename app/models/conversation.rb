# frozen_string_literal: true

class Conversation < ApplicationRecord
  belongs_to :bulletin
  belongs_to :buyer, class_name: 'User'
  belongs_to :seller, class_name: 'User'

  has_many :messages, dependent: :destroy
  has_one :last_message, -> { order(created_at: :desc, id: :desc) }, class_name: 'Message'

  validates :buyer_id, uniqueness: { scope: :bulletin_id }
  validate :different_participants
  validate :correct_author
  validate :published_bulletin, on: :create

  scope :visible_to, ->(user) { where('buyer_id = :id OR seller_id = :id', id: user.id) }

  def participant?(user)
    user.present? && (buyer_id == user.id || seller_id == user.id)
  end

  def other_participant(user)
    buyer_id == user.id ? seller : buyer
  end

  private

  def different_participants
    errors.add(:buyer, 'не может быть автором') if buyer_id.present? && buyer_id == seller_id
  end

  def correct_author
    errors.add(:seller, 'должен владеть объявлением') if bulletin && seller_id && bulletin.user_id != seller_id
  end

  def published_bulletin
    errors.add(:bulletin, 'должно быть опубликовано') if bulletin && !bulletin.published?
  end
end
