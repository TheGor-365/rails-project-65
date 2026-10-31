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

  test 'language defaults to Russian for existing fixtures and new records' do
    assert_equal 'ru', bulletins(:first).language
    assert_equal 'ru', build_bulletin.language
    assert_equal 'ru', Bulletin.column_defaults.fetch('language')
    assert_not Bulletin.columns_hash.fetch('language').null
  end

  test 'supports only ru en hy language codes' do
    %w[ru en hy].each do |language|
      bulletin = build_bulletin
      bulletin.language = language
      assert bulletin.valid?, "#{language}: #{bulletin.errors.full_messages.inspect}"
    end

    [ nil, '', 'fr', 'EN', '<script>' ].each do |language|
      bulletin = build_bulletin
      bulletin.language = language
      assert_not bulletin.valid?, "#{language.inspect} must not be accepted"
      assert_includes bulletin.errors.attribute_names, :language
    end
  end

  test 'editing title does not change a previously saved listing language' do
    bulletin = bulletins(:first)
    bulletin.update!(language: 'hy')
    bulletin.update!(title: 'Updated listing title')

    assert_equal 'hy', bulletin.reload.language
  end

  test 'image and language validation messages follow current locale' do
    expected = {
      ru: [ 'Язык объявления', 'недопустимое значение' ],
      en: [ 'Listing language', 'is not a supported value' ],
      hy: [ 'Հայտարարության լեզու', 'թույլատրելի արժեք չէ' ]
    }

    expected.each do |locale, (attribute, message)|
      I18n.with_locale(locale) do
        bulletin = build_bulletin
        bulletin.language = 'zz'

        assert_not bulletin.valid?
        assert_includes bulletin.errors.full_messages.join, attribute
        assert_includes bulletin.errors.full_messages.join, message
      end
    end
  end

end
