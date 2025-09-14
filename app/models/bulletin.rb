class Bulletin < ApplicationRecord
  belongs_to :category
  belongs_to :user

  has_one_attached :image

  validates :title, presence: true, length: { maximum: 50 }
  validates :description, presence: true, length: { maximum: 1000 }
  validate  :validate_image_presence_and_size

  scope :recent, -> { order(created_at: :desc) }

  private

  def validate_image_presence_and_size
    errors.add(:image, 'должно быть добавлено') unless image.attached?
    return unless image.attached?

    if image.blob.byte_size > 5.megabytes
      errors.add(:image, 'не более 5 МБ')
    end
  end
end
