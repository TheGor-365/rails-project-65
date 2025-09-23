# frozen_string_literal: true

class Bulletin < ApplicationRecord
  belongs_to :user
  belongs_to :category
  has_one_attached :image

  validates :title, :description, :user, :category, presence: true

  scope :published, -> { where(state: 'published').order(created_at: :desc) }
  scope :recent,    -> { order(created_at: :desc) }

  include AASM

  aasm column: :state, whiny_persistence: false do
    state :draft, initial: true
    state :under_moderation
    state :published
    state :rejected
    state :archived

    event :to_moderate do
      transitions from: %i[draft rejected], to: :under_moderation
    end

    event :publish do
      transitions from: :under_moderation, to: :published
    end

    event :reject do
      transitions from: :under_moderation, to: :rejected
    end

    event :archive do
      transitions from: %i[draft under_moderation published rejected], to: :archived
    end
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[id title description category_id user_id state created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[category user]
  end
end
