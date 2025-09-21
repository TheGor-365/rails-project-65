class Bulletin < ApplicationRecord
  belongs_to :category
  belongs_to :user

  has_one_attached :image

  validates :title, presence: true, length: { maximum: 50 }
  validates :description, presence: true, length: { maximum: 1000 }
  validate  :validate_image_presence_and_size, on: :create

  scope :recent,    -> { order(created_at: :desc) }
  scope :published, -> { where(state: "published") }
  scope :of_user,   ->(user) { where(user:) }

  include AASM
  aasm column: :state, whiny_transitions: false do
    state :draft, initial: true
    state :under_moderation
    state :published
    state :rejected
    state :archived

    event :to_moderate do
      transitions from: :draft, to: :under_moderation
    end

    event :publish do
      transitions from: :under_moderation, to: :published
    end

    event :reject do
      transitions from: :under_moderation, to: :rejected
    end

    event :archive do
      transitions from: [:under_moderation, :published, :rejected], to: :archived
    end
  end

  def self.ransackable_attributes(_auth = nil)
    %w[title description state category_id user_id created_at updated_at id]
  end

  def self.ransackable_associations(_auth = nil)
    %w[category user]
  end

  private

  def validate_image_presence_and_size
    errors.add(:image, "должно быть добавлено") unless image.attached?
    return unless image.attached?

    errors.add(:image, "не более 5 МБ") if image.blob.byte_size > 5.megabytes
  end
end
