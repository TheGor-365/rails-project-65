# frozen_string_literal: true

require 'test_helper'
require 'base64'
require 'stringio'

module Web
  class BulletinsUploadTest < ActionDispatch::IntegrationTest
    PNG = Base64.strict_decode64(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/54cAAAAASUVORK5CYII='
    )

    test 'accepts valid PNG through HTTP create' do
      sign_in(users(:one))
      upload = build_upload(PNG, 'valid.png', 'image/png')

      assert_difference 'Bulletin.count', 1 do
        post bulletins_path, params: {
          bulletin: attributes_for('HTTP valid PNG', upload)
        }
      end

      assert_redirected_to profile_path
      assert Bulletin.find_by!(title: 'HTTP valid PNG').image.attached?
    ensure
      upload&.tempfile&.close
    end

    test 'rejects forged PNG through HTTP create' do
      sign_in(users(:one))
      upload = build_upload('%PDF-1.4 fake image', 'fake.png', 'image/png')

      assert_no_difference 'Bulletin.count' do
        post bulletins_path, params: {
          bulletin: attributes_for('HTTP forged PNG', upload)
        }
      end

      assert_response :unprocessable_entity
    ensure
      upload&.tempfile&.close
    end

    private

    def attributes_for(title, upload)
      {
        title: title,
        description: 'Upload validation integration test',
        category_id: categories(:one).id,
        image: upload
      }
    end

    def build_upload(bytes, filename, content_type)
      Rack::Test::UploadedFile.new(
        StringIO.new(bytes),
        content_type,
        true,
        original_filename: filename
      )
    end
  end
end
