# frozen_string_literal: true

require 'test_helper'
require 'stringio'

class BulletinTest < ActiveSupport::TestCase
  def build_bulletin
    Bulletin.new(
      title: 'Test bulletin',
      description: 'Test description',
      category: categories(:one),
      user: users(:one)
    )
  end

  test 'rejects unsupported image content type' do
    bulletin = build_bulletin

    bulletin.image.attach(
      io: StringIO.new('%PDF-1.4 test'),
      filename: 'document.pdf',
      content_type: 'application/pdf',
      identify: false
    )

    assert_not bulletin.valid?
    assert_includes bulletin.errors.attribute_names, :image
  end

  test 'rejects image larger than five megabytes' do
    bulletin = build_bulletin

    bulletin.image.attach(
      io: StringIO.new('x' * (5 * 1024 * 1024 + 1)),
      filename: 'oversized.png',
      content_type: 'image/png',
      identify: false
    )

    assert_not bulletin.valid?
    assert_includes bulletin.errors.attribute_names, :image
  end

  test 'allows a bulletin without image' do
    bulletin = build_bulletin

    assert bulletin.valid?, bulletin.errors.full_messages.inspect
  end

  test 'allows a small valid PNG' do
    require 'base64'

    png = Base64.strict_decode64(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/54cAAAAASUVORK5CYII='
    )

    bulletin = build_bulletin
    bulletin.image.attach(
      io: StringIO.new(png),
      filename: 'pixel.png',
      content_type: 'image/png',
      identify: false
    )

    assert bulletin.valid?, bulletin.errors.full_messages.inspect
  end

  test 'rejects forged PNG content type' do
    bulletin = build_bulletin

    bulletin.image.attach(
      io: StringIO.new('%PDF-1.4 fake image'),
      filename: 'fake.png',
      content_type: 'image/png',
      identify: false
    )

    assert_not bulletin.valid?
    assert_includes bulletin.errors.attribute_names, :image
  end

  test 'accepts signed PNG blob' do
    require 'base64'
    png = Base64.strict_decode64(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/54cAAAAASUVORK5CYII='
    )

    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(png),
      filename: 'pixel.png',
      content_type: 'image/png',
      identify: false
    )

    bulletin = build_bulletin
    bulletin.image.attach(blob.signed_id)

    assert bulletin.valid?, bulletin.errors.full_messages.inspect
  ensure
    blob&.purge
  end

  test 'rejects forged signed PNG blob' do
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new('%PDF-1.4 fake image'),
      filename: 'fake.png',
      content_type: 'image/png',
      identify: false
    )

    bulletin = build_bulletin
    bulletin.image.attach(blob.signed_id)

    assert_not bulletin.valid?
    assert_includes bulletin.errors.attribute_names, :image
  ensure
    blob&.purge
  end

  test 'allows updating bulletin with existing image' do
    require 'base64'
    png = Base64.strict_decode64(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/54cAAAAASUVORK5CYII='
    )

    bulletin = build_bulletin
    bulletin.image.attach(
      io: StringIO.new(png),
      filename: 'existing.png',
      content_type: 'image/png',
      identify: false
    )

    bulletin.save!
    bulletin.update!(title: 'Edited bulletin')

    assert_equal 'Edited bulletin', bulletin.reload.title
    assert bulletin.image.attached?
  ensure
    bulletin&.image&.purge if bulletin&.persisted?
  end
end
