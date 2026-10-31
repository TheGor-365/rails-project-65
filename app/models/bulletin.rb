# frozen_string_literal: true

class Bulletin < ApplicationRecord
  belongs_to :user
  belongs_to :category
  has_one_attached :image
  has_many_attached :photos
  has_many :favorites, dependent: :destroy
  has_many :conversations, dependent: :destroy

  validates :title, :description, :user, :category, presence: true

  validate :validate_image_upload
  validate :validate_photo_uploads

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

  private

  def validate_image_upload
    return unless image.attached?

    blob = image.blob
    allowed_types = %w[image/jpeg image/png image/webp]

    unless allowed_types.include?(blob.content_type)
      errors.add(:image, 'должно быть JPEG, PNG или WebP')
    end

    if blob.byte_size.nil? || blob.byte_size > 5.megabytes
      errors.add(:image, 'не должно превышать 5 МБ')
    end

    change = attachment_changes['image']
    return unless change&.respond_to?(:attachable)
    return if errors[:image].any?

    actual_type = image_content_type_from_bytes(change.attachable, blob)
    return if actual_type == blob.content_type

    errors.add(:image, 'содержимое не соответствует формату файла')
  end

  def validate_photo_uploads
    return unless photos.attached?

    allowed_types = %w[image/jpeg image/png image/webp]
    errors.add(:photos, 'может содержать не более 4 дополнительных изображений') if photos.attachments.size > 4

    photos.each do |photo|
      blob = photo.blob
      unless allowed_types.include?(blob.content_type) && blob.byte_size.present? && blob.byte_size <= 5.megabytes
        errors.add(:photos, 'должны быть JPEG, PNG или WebP до 5 МБ')
      end
    end

    change = attachment_changes['photos']
    return unless change

    change.attachables.each do |attachable|
      next if attachable.is_a?(ActiveStorage::Blob) || attachable.is_a?(ActiveStorage::Attachment)

      declared_type = attachable.content_type if attachable.respond_to?(:content_type)
      declared_type ||= attachable[:content_type] || attachable['content_type'] if attachable.is_a?(Hash)
      actual_type = image_content_type_from_bytes(attachable, nil)
      unless actual_type && actual_type == declared_type && allowed_types.include?(actual_type)
        errors.add(:photos, 'должны соответствовать заявленному формату файла')
      end
    end
  end

  def image_content_type_from_bytes(attachable, blob)
    io = attachable.is_a?(Hash) ? attachable[:io] || attachable['io'] : attachable
    io = io.tempfile if io.respond_to?(:tempfile)

    if io.respond_to?(:read) && io.respond_to?(:rewind)
      Marcel::Magic.by_magic(io)&.type
    elsif io.is_a?(Pathname)
      io.open { |file| Marcel::Magic.by_magic(file)&.type }
    else
      blob.open { |file| Marcel::Magic.by_magic(file)&.type }
    end
  rescue ActiveStorage::FileNotFoundError, Errno::ENOENT
    nil
  end
end
