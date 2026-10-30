# frozen_string_literal: true

require 'application_system_test_case'
require 'base64'
require 'stringio'

class BulletinGallerySystemTest < ApplicationSystemTestCase
  PNG = Base64.strict_decode64(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/54cAAAAASUVORK5CYII='
  )

  test 'visitor can switch from cover to another photo without processed variants' do
    bulletin = bulletins(:first)
    bulletin.image.attach(io: StringIO.new(PNG), filename: 'cover.png', content_type: 'image/png')
    bulletin.photos.attach(io: StringIO.new(PNG), filename: 'other.png', content_type: 'image/png')

    visit bulletin_path(bulletin)

    assert_selector '.cl-gallery-thumb', count: 2
    first_src = find('.cl-detail-gallery__image')[:src]

    find('button[aria-label="Фотография 2"]').click

    assert_selector 'button[aria-label="Фотография 2"][aria-pressed="true"]'
    assert_not_equal first_src, find('.cl-detail-gallery__image')[:src]
  end
end
