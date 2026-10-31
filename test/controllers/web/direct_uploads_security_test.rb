# frozen_string_literal: true

require 'test_helper'
require 'digest'

module Web
  class DirectUploadsSecurityTest < ActionDispatch::IntegrationTest
    test 'guest cannot create unused direct upload blob' do
      assert_direct_upload_blocked
    end

    test 'signed in user cannot create unused direct upload blob' do
      sign_in(users(:one))
      assert_direct_upload_blocked
    end

    private

    def assert_direct_upload_blocked
      assert_no_difference 'ActiveStorage::Blob.count' do
        post rails_direct_uploads_path, params: {
          blob: {
            filename: 'probe.png',
            byte_size: 1,
            checksum: Digest::MD5.base64digest('x'),
            content_type: 'image/png'
          }
        }, as: :json
      end

      assert_response :not_found
    end
  end
end
