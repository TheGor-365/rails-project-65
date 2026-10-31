# frozen_string_literal: true

module BulletinPhotoUploads
  private

  def assign_uploaded_photos(bulletin)
    uploads = params.dig(:bulletin, :photos)
    return if uploads.blank?

    unless uploads.is_a?(Array) && uploads.all? { |file| file.blank? || file.respond_to?(:tempfile) }
      raise ActionController::BadRequest, I18n.t('errors.uploads.invalid_additional_files')
    end

    files = uploads.reject(&:blank?)
    return if files.empty?

    # Preserve every existing photo. Assignment happens before save,
    # so invalid new photos cannot partially update the bulletin.
    bulletin.photos = bulletin.photos.blobs.to_a + files
  end
end
