# frozen_string_literal: true

require 'test_helper'
require 'base64'
require 'stringio'

module Web
  class BulletinGalleryTest < ActionDispatch::IntegrationTest
    PNG = Base64.strict_decode64(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/54cAAAAASUVORK5CYII='
    )

    test 'owner can add photos without replacing an existing cover' do
      bulletin = bulletins(:first)
      bulletin.image.attach(io: StringIO.new(PNG), filename: 'cover.png', content_type: 'image/png')
      sign_in(users(:one))

      first = upload(PNG, 'gallery-1.png')
      patch bulletin_path(bulletin), params: { bulletin: { photos: [ first ] } }
      assert_redirected_to profile_path
      assert_equal 1, bulletin.reload.photos.count
      assert bulletin.image.attached?

      second = upload(PNG, 'gallery-2.png')
      patch bulletin_path(bulletin), params: { bulletin: { photos: [ second ] } }
      assert_redirected_to profile_path
      assert_equal 2, bulletin.reload.photos.count
      assert bulletin.image.attached?

      get bulletin_path(bulletin)
      assert_response :success
      assert_select '.cl-gallery-thumb', count: 3
    ensure
      first&.tempfile&.close
      second&.tempfile&.close
    end

    test 'forged extra photo is rejected without changing the bulletin' do
      bulletin = bulletins(:first)
      sign_in(users(:one))
      invalid = upload('%PDF-1.4 not a PNG', 'forged.png')

      patch bulletin_path(bulletin), params: { bulletin: { photos: [ invalid ] } }
      assert_response :unprocessable_entity
      assert_equal 0, bulletin.reload.photos.count
    ensure
      invalid&.tempfile&.close
    end

    test 'more than four photos are rejected' do
      bulletin = bulletins(:first)
      sign_in(users(:one))
      files = 5.times.map { |i| upload(PNG, "photo-#{i}.png") }

      patch bulletin_path(bulletin), params: { bulletin: { photos: files } }
      assert_response :unprocessable_entity
      assert_equal 0, bulletin.reload.photos.count
    ensure
      files&.each { |file| file.tempfile.close }
    end

    private

    def upload(bytes, name)
      Rack::Test::UploadedFile.new(StringIO.new(bytes), 'image/png', true, original_filename: name)
    end
  end
end
